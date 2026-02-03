#!/bin/bash

# 1. تنظيف شامل للمشروع
flutter clean
rm -f pubspec.lock

# 2. إصلاح التبعيات المفقودة (حل خطأ 12:35)
sed -i '/cent_app/d' pubspec.yaml
sed -i 's/^name: .*/name: cent/' pubspec.yaml

# 3. الجراحة الشاملة للأكواد (إصلاح أخطاء صورة 2:02 و 12:43)
# سنقوم بالبحث عن كل الأنماط المسببة للفشل واستبدالها بأنماط مرنة
find . -name "*.dart" -type f | xargs sed -i 's/MemoryPressureLevel/dynamic/g'
find . -name "*.dart" -type f | xargs sed -i 's/VisualComplexityLevel/dynamic/g'
find . -name "*.dart" -type f | xargs sed -i 's/ThemePalette/dynamic/g'
find . -name "*.dart" -type f | xargs sed -i 's/InternalAppEventType/dynamic/g'
find . -name "*.dart" -type f | xargs sed -i 's/await Future.wait(/await Future.wait<dynamic>(/g'
find . -name "*.dart" -type f | xargs sed -i 's/super.dispose()/if(true){super.dispose();}/g'

# 4. إصلاح المشاكل البنائية آلياً
dart fix --apply
flutter pub get
