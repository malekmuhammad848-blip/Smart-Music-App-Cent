# infrastructure/aws/main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket = "cent-terraform-state"
    key    = "production/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "cent-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "production"
    Application = "CENT"
  }
}

# EKS Cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = "cent-cluster"
  cluster_version = "1.27"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  eks_managed_node_groups = {
    main = {
      min_size     = 1
      max_size     = 10
      desired_size = 3

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"

      update_config = {
        max_unavailable_percentage = 50
      }
    }

    ml-nodes = {
      min_size     = 1
      max_size     = 5
      desired_size = 2

      instance_types = ["g4dn.xlarge"]
      capacity_type  = "SPOT"

      labels = {
        node-type = "ml"
      }

      taints = [{
        key    = "node-type"
        value  = "ml"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  tags = {
    Environment = "production"
    Application = "CENT"
  }
}

# RDS PostgreSQL
module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "cent-db"

  engine               = "postgres"
  engine_version       = "15"
  family               = "postgres15"
  major_engine_version = "15"
  instance_class       = "db.t4g.large"

  allocated_storage     = 100
  max_allocated_storage = 500

  db_name  = "cent_production"
  username = var.db_username
  password = var.db_password
  port     = 5432

  multi_az               = true
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.vpc.default_security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  backup_retention_period = 7
  skip_final_snapshot     = false
  deletion_protection     = true

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  create_monitoring_role      = true
  monitoring_interval         = 60
  monitoring_role_name        = "cent-rds-monitoring-role"
  create_monitoring_role      = true

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = {
    Environment = "production"
    Application = "CENT"
  }
}

# Elasticache Redis
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "cent-redis"
  engine              = "redis"
  node_type           = "cache.t4g.small"
  num_cache_nodes     = 1
  parameter_group_name = "default.redis7"
  engine_version      = "7.0"
  port                = 6379

  subnet_group_name  = module.vpc.elasticache_subnet_group_name
  security_group_ids = [aws_security_group.redis.id]

  snapshot_retention_limit = 7
  snapshot_window         = "05:00-09:00"

  tags = {
    Name        = "cent-redis"
    Environment = "production"
  }
}

# S3 Bucket for music storage
resource "aws_s3_bucket" "music_storage" {
  bucket = "cent-music-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "cent-music-storage"
    Environment = "production"
  }
}

resource "aws_s3_bucket_versioning" "music_storage" {
  bucket = aws_s3_bucket.music_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "music_storage" {
  bucket = aws_s3_bucket.music_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "music_storage" {
  bucket = aws_s3_bucket.music_storage.id

  rule {
    id     = "transition_to_glacier"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "music_cdn" {
  origin {
    domain_name = aws_s3_bucket.music_storage.bucket_regional_domain_name
    origin_id   = "S3-cent-music"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.music_cdn.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CENT Music CDN"
  default_root_object = "index.html"

  aliases = ["music.cent.com"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-cent-music"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    # Cache based on audio quality
    cache_policy_id = aws_cloudfront_cache_policy.audio_cache.id
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE", "FR", "JP", "AU"]
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cdn_cert.arn
    ssl_support_method  = "sni-only"
  }

  tags = {
    Environment = "production"
    Application = "CENT"
  }
}

# CloudFront Cache Policy for audio
resource "aws_cloudfront_cache_policy" "audio_cache" {
  name        = "cent-audio-cache-policy"
  comment     = "Cache policy for audio files with quality-based caching"
  default_ttl = 3600
  max_ttl     = 86400
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Accept", "Accept-Encoding", "Range"]
      }
    }

    query_strings_config {
      query_string_behavior = "whitelist"
      query_strings {
        items = ["quality", "bitrate"]
      }
    }
  }
}

# Security Groups
resource "aws_security_group" "redis" {
  name        = "cent-redis-sg"
  description = "Security group for Redis"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Redis from EKS"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cent-redis-sg"
  }
}
