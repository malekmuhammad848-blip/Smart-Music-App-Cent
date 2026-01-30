// mobile/lib/src/core/design_system/design_system.dart
import 'package:flutter/material.dart';

class CENTColors {
  // Primary colors
  static const Color primary = Color(0xFF1DB954);
  static const Color primaryDark = Color(0xFF1AA34A);
  static const Color primaryLight = Color(0xFF4CD964);
  
  // Gradient variations
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient premiumGradient = LinearGradient(
    colors: [Color(0xFF9D4EDD), Color(0xFF560BAD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Dark theme
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF181818);
  static const Color surfaceVariant = Color(0xFF282828);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFB3B3B3);
  
  // Light theme
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF6F6F6);
  static const Color lightSurfaceVariant = Color(0xFFE8E8E8);
  static const Color lightOnSurface = Color(0xFF000000);
  static const Color lightOnSurfaceVariant = Color(0xFF666666);
  
  // Accent colors for moods/genres
  static const Map<String, Color> moodColors = {
    'happy': Color(0xFFFFD166),
    'sad': Color(0xFF118AB2),
    'energetic': Color(0xFFEF476F),
    'calm': Color(0xFF06D6A0),
    'focused': Color(0xFF7209B7),
    'romantic': Color(0xFFFF006E),
  };
  
  static const Map<String, Color> genreColors = {
    'pop': Color(0xFFFF595E),
    'rock': Color(0xFF1982C4),
    'hiphop': Color(0xFF6A4C93),
    'electronic': Color(0xFF8AC926),
    'jazz': Color(0xFFFFCA3A),
    'classical': Color(0xFF1982C4),
    'country': Color(0xFF8AC926),
  };
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
}

class CENTTypography {
  // Font families
  static const String primaryFont = 'CircularStd';
  static const String secondaryFont = 'SFProDisplay';
  
  // Text styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 57,
    fontWeight: FontWeight.w400,
    height: 1.12,
    letterSpacing: -0.25,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 45,
    fontWeight: FontWeight.w400,
    height: 1.16,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 1.22,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.25,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 1.29,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 1.33,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.27,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.15,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.25,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.4,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.5,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.45,
    letterSpacing: 0.5,
  );
}

class CENTShapes {
  static const BorderRadius extraSmall = BorderRadius.all(Radius.circular(4));
  static const BorderRadius small = BorderRadius.all(Radius.circular(8));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(12));
  static const BorderRadius large = BorderRadius.all(Radius.circular(16));
  static const BorderRadius extraLarge = BorderRadius.all(Radius.circular(24));
  static const BorderRadius circle = BorderRadius.all(Radius.circular(999));
}

class CENTSpacing {
  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
  static const double extraLarge = 32;
  static const double superLarge = 48;
}

class CENTTheme extends ThemeExtension<CENTTheme> {
  final CENTColors colors;
  final CENTTypography typography;
  final CENTShapes shapes;
  final CENTSpacing spacing;
  
  const CENTTheme({
    required this.colors,
    required this.typography,
    required this.shapes,
    required this.spacing,
  });
  
  factory CENTTheme.dark() {
    return CENTTheme(
      colors: CENTColors(),
      typography: CENTTypography(),
      shapes: CENTShapes(),
      spacing: CENTSpacing(),
    );
  }
  
  factory CENTTheme.light() {
    return CENTTheme(
      colors: CENTColors(),
      typography: CENTTypography(),
      shapes: CENTShapes(),
      spacing: CENTSpacing(),
    );
  }
  
  @override
  ThemeExtension<CENTTheme> copyWith({
    CENTColors? colors,
    CENTTypography? typography,
    CENTShapes? shapes,
    CENTSpacing? spacing,
  }) {
    return CENTTheme(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      shapes: shapes ?? this.shapes,
      spacing: spacing ?? this.spacing,
    );
  }
  
  @override
  ThemeExtension<CENTTheme> lerp(
    ThemeExtension<CENTTheme>? other, 
    double t,
  ) {
    if (other is! CENTTheme) {
      return this;
    }
    
    return CENTTheme(
      colors: colors,
      typography: typography,
      shapes: shapes,
      spacing: spacing,
    );
  }
}

// Custom widgets using the design system
class CENTCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool elevated;
  final VoidCallback? onTap;
  
  const CENTCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderRadius,
    this.elevated = true,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CENTTheme>()!;
    
    return Material(
      color: backgroundColor ?? theme.colors.surface,
      borderRadius: borderRadius ?? theme.shapes.medium,
      elevation: elevated ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? theme.shapes.medium,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class CENTButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final CENTButtonType type;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  
  const CENTButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = CENTButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CENTTheme>()!;
    
    final buttonStyle = _getButtonStyle(theme);
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 48,
        minWidth: fullWidth ? double.infinity : 0,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _getTextColor(theme),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: _getTextStyle(theme),
                  ),
                ],
              ),
      ),
    );
  }
  
  ButtonStyle _getButtonStyle(CENTTheme theme) {
    switch (type) {
      case CENTButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: theme.colors.primary,
          foregroundColor: theme.colors.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: theme.shapes.medium,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        );
      case CENTButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: theme.colors.surfaceVariant,
          foregroundColor: theme.colors.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: theme.shapes.medium,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        );
      case CENTButtonType.outline:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colors.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: theme.shapes.medium,
            side: BorderSide(color: theme.colors.primary),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        );
    }
  }
  
  TextStyle _getTextStyle(CENTTheme theme) {
    return theme.typography.labelLarge.copyWith(
      color: _getTextColor(theme),
      fontWeight: FontWeight.w600,
    );
  }
  
  Color _getTextColor(CENTTheme theme) {
    switch (type) {
      case CENTButtonType.primary:
        return theme.colors.onSurface;
      case CENTButtonType.secondary:
        return theme.colors.onSurfaceVariant;
      case CENTButtonType.outline:
        return theme.colors.primary;
    }
  }
}

enum CENTButtonType { primary, secondary, outline }
