#!/bin/bash

# تنظيف شامل للمشروع
flutter clean

# حذف أي إشارة لمكتبة cent_app من ملف pubspec.yaml تماماً
sed -i '/cent_app:/d' pubspec.yaml

# جلب المكتبات بعد التنظيف
flutter pub get

# إصلاح الأخطاء الداخلية في الـ 50 ألف سطر آلياً
dart fix --apply

echo "Cent Engine: Fix completed and cent_app removed!"
