# ml-service/app/services/recommendation.py
import numpy as np
import pandas as pd
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from collections import defaultdict
import pickle
import redis
from sqlalchemy import create_engine, text
from sklearn.preprocessing import StandardScaler
from sklearn.metrics.pairwise import cosine_similarity
import lightfm
from lightfm import LightFM
from lightfm.data import Dataset
import implicit
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
import joblib
import logging

logger = logging.getLogger(__name__)

class CENTRecommendationEngine:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.redis_client = redis.Redis.from_url(config['redis_url'])
        self.db_engine = create_engine(config['database_url'])
        
        # Models
        self.collab_model = None
        self.content_model = None
        self.hybrid_model = None
        self.session_model = None
        
        # Caches
        self.user_embeddings = {}
        self.item_embeddings = {}
        self.similarity_matrix = None
        
        self.load_models()
        
    def load_models(self):
        """Load pre-trained models from storage"""
        try:
            # Collaborative filtering model
            with open('models/collab_model.pkl', 'rb') as f:
                self.collab_model = pickle.load(f)
                
            # Content-based model
            self.content_model = joblib.load('models/content_model.joblib')
            
            # Hybrid model weights
            self.hybrid_weights = {
                'collab': 0.4,
                'content': 0.3,
                'popularity': 0.2,
                'recency': 0.1
            }
            
            # Load embeddings if they exist
            self.load_embeddings()
            
            logger.info("Models loaded successfully")
            
        except FileNotFoundError:
            logger.info("No pre-trained models found, training new ones")
            self.train_models()
    
    def train_models(self):
        """Train recommendation models"""
        # Load data
        interactions = self.load_interaction_data()
        user_features = self.load_user_features()
        item_features = self.load_item_features()
        
        # Train collaborative filtering
        self.train_collaborative_filtering(interactions)
        
        # Train content-based filtering
        self.train_content_based(item_features, interactions)
        
        # Train hybrid model
        self.train_hybrid_model(interactions, user_features, item_features)
        
        # Train session-based model
        self.train_session_model()
        
        # Save models
        self.save_models()
    
    def get_recommendations(
        self,
        user_id: str,
        limit: int = 50,
        context: Optional[Dict] = None
    ) -> List[Dict[str, Any]]:
        """
        Get personalized recommendations for a user
        """
        recommendations = []
        
        # 1. Get collaborative filtering recommendations
        collab_recs = self.get_collaborative_recommendations(user_id, limit * 2)
        
        # 2. Get content-based recommendations
        content_recs = self.get_content_recommendations(user_id, limit * 2)
        
        # 3. Get session-based recommendations if context provided
        if context and 'recent_tracks' in context:
            session_recs = self.get_session_recommendations(
                context['recent_tracks'],
                limit
            )
        else:
            session_recs = []
        
        # 4. Get trending/popular recommendations
        trending_recs = self.get_trending_recommendations(limit)
        
        # 5. Blend recommendations using hybrid weights
        blended = self.blend_recommendations(
            collab_recs,
            content_recs,
            session_recs,
            trending_recs
        )
        
        # 6. Apply diversity and freshness filters
        final_recs = self.apply_filters(
            blended,
            user_id,
            context or {}
        )
        
        # 7. Generate explanation for each recommendation
        final_recs = self.add_explanations(final_recs, user_id)
        
        return final_recs[:limit]
    
    def get_discover_weekly(self, user_id: str) -> List[Dict[str, Any]]:
        """
        Generate Discover Weekly playlist for user
        """
        # Get base recommendations
        base_recs = self.get_recommendations(user_id, limit=100)
        
        # Filter for freshness (released in last 4 weeks)
        fresh_recs = self.filter_fresh_tracks(base_recs, weeks=4)
        
        # Ensure diversity in artists and genres
        diverse_recs = self.ensure_diversity(fresh_recs, max_per_artist=2)
        
        # Create playlist structure
        playlist = {
            'name': f'Discover Weekly - {datetime.now().strftime("%b %d")}',
            'description': 'Your weekly personalized mixtape of fresh music',
            'tracks': diverse_recs[:30],
            'generated_at': datetime.now().isoformat(),
            'user_id': user_id
        }
        
        # Cache playlist
        cache_key = f'discover_weekly:{user_id}:{datetime.now().strftime("%Y-%W")}'
        self.redis_client.setex(
            cache_key,
            604800,  # 1 week
            pickle.dumps(playlist)
        )
        
        return playlist
    
    def get_daily_mixes(self, user_id: str) -> Dict[str, List[Dict[str, Any]]]:
        """
        Generate 6 daily mixes based on different aspects of user taste
        """
        mixes = {}
        
        # Mix 1: Based on top artists
        mix1 = self.get_artist_based_mix(user_id, 'top_artists')
        mixes['mix_1'] = mix1
        
        # Mix 2: Based on recent listens
        mix2 = self.get_recent_based_mix(user_id)
        mixes['mix_2'] = mix2
        
        # Mix 3: Based on favorite genres
        mix3 = self.get_genre_based_mix(user_id)
        mixes['mix_3'] = mix3
        
        # Mix 4: Based on mood/audio features
        mix4 = self.get_mood_based_mix(user_id, 'energetic')
        mixes['mix_4'] = mix4
        
        # Mix 5: Based on decade preferences
        mix5 = self.get_decade_based_mix(user_id)
        mixes['mix_5'] = mix5
        
        # Mix 6: Discovery mix (less familiar recommendations)
        mix6 = self.get_discovery_mix(user_id)
        mixes['mix_6'] = mix6
        
        return mixes
    
    def get_radio_station(
        self,
        seed_items: List[str],
        item_type: str = 'track',
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Generate infinite radio station based on seed items
        """
        station = []
        
        # Expand seeds using similarity
        expanded_items = self.expand_seeds(seed_items, item_type)
        
        # Create radio sequence with smooth transitions
        sequence = self.create_radio_sequence(expanded_items)
        
        # Add variety while maintaining coherence
        station = self.add_variety_to_sequence(sequence, limit)
        
        return station
    
    def train_collaborative_filtering(self, interactions: pd.DataFrame):
        """
        Train collaborative filtering model using LightFM
        """
        # Prepare dataset
        dataset = Dataset()
        dataset.fit(
            interactions['user_id'].unique(),
            interactions['track_id'].unique()
        )
        
        # Build interactions matrix
        (interactions_matrix, _) = dataset.build_interactions(
            list(zip(
                interactions['user_id'],
                interactions['track_id'],
                interactions['weight']
            ))
        )
        
        # Train model
        model = LightFM(
            loss='warp',
            learning_rate=0.05,
            no_components=64,
            user_alpha=0.0001,
            item_alpha=0.0001
        )
        
        model.fit(
            interactions_matrix,
            epochs=30,
            num_threads=4,
            verbose=True
        )
        
        self.collab_model = model
        self.interactions_matrix = interactions_matrix
        
        # Generate embeddings
        self.user_embeddings = model.get_user_representations()
        self.item_embeddings = model.get_item_representations()
    
    def train_content_based(self, item_features: pd.DataFrame, interactions: pd.DataFrame):
        """
        Train content-based recommendation model
        """
        # Extract audio features
        audio_features = item_features[[
            'danceability', 'energy', 'valence',
            'acousticness', 'instrumentalness',
            'liveness', 'speechiness', 'tempo',
            'key', 'mode', 'duration_ms'
        ]]
        
        # Normalize features
        scaler = StandardScaler()
        normalized_features = scaler.fit_transform(audio_features)
        
        # Compute similarity matrix
        self.similarity_matrix = cosine_similarity(normalized_features)
        
        # Store feature mappings
        self.item_ids = item_features['track_id'].values
        self.item_id_to_index = {
            id_: idx for idx, id_ in enumerate(self.item_ids)
        }
        
        self.content_model = {
            'similarity_matrix': self.similarity_matrix,
            'item_mapping': self.item_id_to_index,
            'scaler': scaler
        }
    
    def train_hybrid_model(
        self,
        interactions: pd.DataFrame,
        user_features: pd.DataFrame,
        item_features: pd.DataFrame
    ):
        """
        Train hybrid recommendation model using deep learning
        """
        # Prepare data for neural network
        X_user, X_item, y = self.prepare_hybrid_data(
            interactions,
            user_features,
            item_features
        )
        
        # Build neural network
        model = self.build_hybrid_nn(
            user_feature_dim=X_user.shape[1],
            item_feature_dim=X_item.shape[1]
        )
        
        # Train model
        model.fit(
            [X_user, X_item],
            y,
            epochs=50,
            batch_size=256,
            validation_split=0.2,
            verbose=1
        )
        
        self.hybrid_model = model
    
    def build_hybrid_nn(self, user_feature_dim: int, item_feature_dim: int):
        """Build hybrid neural network model"""
        
        # User input branch
        user_input = keras.Input(shape=(user_feature_dim,))
        user_dense = layers.Dense(128, activation='relu')(user_input)
        user_dense = layers.Dropout(0.2)(user_dense)
        user_dense = layers.Dense(64, activation='relu')(user_dense)
        
        # Item input branch
        item_input = keras.Input(shape=(item_feature_dim,))
        item_dense = layers.Dense(128, activation='relu')(item_input)
        item_dense = layers.Dropout(0.2)(item_dense)
        item_dense = layers.Dense(64, activation='relu')(item_dense)
        
        # Merge branches
        merged = layers.concatenate([user_dense, item_dense])
        merged = layers.Dense(128, activation='relu')(merged)
        merged = layers.Dropout(0.3)(merged)
        merged = layers.Dense(64, activation='relu')(merged)
        
        # Output
        output = layers.Dense(1, activation='sigmoid')(merged)
        
        model = keras.Model(inputs=[user_input, item_input], outputs=output)
        
        model.compile(
            optimizer=keras.optimizers.Adam(learning_rate=0.001),
            loss='binary_crossentropy',
            metrics=['accuracy', keras.metrics.AUC()]
        )
        
        return model
    
    def blend_recommendations(self, *recommendation_lists):
        """Blend multiple recommendation lists using weighted scoring"""
        all_items = {}
        
        # Collect all items with their scores from each list
        for idx, rec_list in enumerate(recommendation_lists):
            weight = self.hybrid_weights.get(
                list(self.hybrid_weights.keys())[idx],
                0.1
            )
            
            for rank, item in enumerate(rec_list):
                item_id = item['track_id']
                score = item.get('score', 0) * weight * (1 / (rank + 1))
                
                if item_id not in all_items:
                    all_items[item_id] = {
                        'track': item,
                        'total_score': 0,
                        'contributors': []
                    }
                
                all_items[item_id]['total_score'] += score
                all_items[item_id]['contributors'].append(
                    list(self.hybrid_weights.keys())[idx]
                )
        
        # Sort by total score
        sorted_items = sorted(
            all_items.items(),
            key=lambda x: x[1]['total_score'],
            reverse=True
        )
        
        # Prepare final list
        final_recs = []
        for item_id, data in sorted_items:
            final_item = data['track'].copy()
            final_item['blended_score'] = data['total_score']
            final_item['recommendation_sources'] = data['contributors']
            final_recs.append(final_item)
        
        return final_recs
    
    def add_explanations(self, recommendations: List[Dict], user_id: str) -> List[Dict]:
        """Add human-readable explanations for recommendations"""
        
        user_history = self.get_user_history(user_id)
        
        for rec in recommendations:
            explanation = []
            
            if 'collaborative' in rec.get('recommendation_sources', []):
                explanation.append(
                    "Recommended because users with similar taste also like this"
                )
            
            if 'content' in rec.get('recommendation_sources', []):
                similar_track = self.find_similar_track_in_history(
                    rec['track_id'],
                    user_history
                )
                if similar_track:
                    explanation.append(
                        f"Similar to {similar_track['title']} you listened to"
                    )
            
            if 'artist' in rec.get('recommendation_sources', []):
                explanation.append(
                    f"From an artist you follow: {rec['artist_name']}"
                )
            
            if not explanation:
                explanation.append("Popular track you might like")
            
            rec['explanation'] = " • ".join(explanation)
        
        return recommendations
    
    def ensure_diversity(self, recommendations: List[Dict], max_per_artist: int = 2):
        """Ensure diversity in recommendations"""
        artist_counts = defaultdict(int)
        diverse_recs = []
        
        for rec in recommendations:
            artist_id = rec.get('artist_id')
            
            if artist_counts[artist_id] < max_per_artist:
                diverse_recs.append(rec)
                artist_counts[artist_id] += 1
            
            if len(diverse_recs) >= 30:
                break
        
        return diverse_recs
    
    def filter_fresh_tracks(self, recommendations: List[Dict], weeks: int = 4):
        """Filter for recently released tracks"""
        cutoff_date = datetime.now() - timedelta(weeks=weeks)
        
        fresh_recs = [
            rec for rec in recommendations
            if rec.get('release_date') and 
            datetime.fromisoformat(rec['release_date']) > cutoff_date
        ]
        
        return fresh_recs or recommendations[:10]  # Fallback if no fresh tracks
