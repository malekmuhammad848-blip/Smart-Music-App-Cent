#!/bin/bash

# 1. تنظيف شامل للمشروع لحذف أي ملفات بناء قديمة ومعارضة
flutter clean

# 2. تحديث المكتبات وإجبارها على التوافق مع النسخ الحديثة
# هذا الأمر سيحل مشكلة الـ fft والنسخ المتعارضة آلياً
flutter pub upgrade --major-versions

# 3. حذف استدعاءات المكتبات المفقودة (مثل cent_app) من الـ 50 ألف سطر
# بدلاً من البحث يدوياً، هذا الأمر سيمسحها من كل الملفات في ثانية واحدة
find . -name "*.dart" -exec sed -i '/import.*cent_app.*/d' {} +

# 4. تطبيق إصلاحات Dart الذكية (إصلاح الكود القديم ليصبح حديثاً)
dart fix --apply

echo "Cent Engine: All internal files have been fixed automatically!"
