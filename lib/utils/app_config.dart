class AppConfig {
  static const String appName = 'Cent';
  static const String appVersion = '1.0.0';
  static const String developer = 'MALEK';

  static const String goldColor = '#FFD700';
  static const String blackColor = '#000000';
  static const String darkBackgroundColor = '#121212';

  static const int animationDuration = 300;
  static const int fastAnimationDuration = 200;
  static const int slowAnimationDuration = 500;

  static const List<String> demoTracks = [
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
  ];
}

class Translations {
  static const Map<String, Map<String, String>> strings = {
    'en': {
      'home': 'Home',
      'search': 'Search',
      'library': 'Your Library',
      'settings': 'Settings',
      'about': 'About',
      'language': 'Language',
      'theme': 'Theme',
      'notifications': 'Notifications',
      'logout': 'Logout',
      'version': 'Version',
      'privacyPolicy': 'Privacy Policy',
      'developedBy': 'Developed by',
      'allRightsReserved': 'All Rights Reserved',
      'application': 'Application',
      'enabled': 'Enabled',
      'disabled': 'Disabled',
      'musicStudio': 'music studio',
    },
    'ar': {
      'home': 'الرئيسية',
      'search': 'البحث',
      'library': 'مكتبتي',
      'settings': 'الإعدادات',
      'about': 'حول',
      'language': 'اللغة',
      'theme': 'المظهر',
      'notifications': 'الإخطارات',
      'logout': 'تسجيل الخروج',
      'version': 'الإصدار',
      'privacyPolicy': 'سياسة الخصوصية',
      'developedBy': 'تم التطوير بواسطة',
      'allRightsReserved': 'جميع الحقوق محفوظة',
      'application': 'التطبيق',
      'enabled': 'مفعّل',
      'disabled': 'معطّل',
      'musicStudio': 'استوديو الموسيقى',
    },
  };

  static String get(String key, bool isArabic) {
    final lang = isArabic ? 'ar' : 'en';
    return strings[lang]?[key] ?? key;
  }
}
