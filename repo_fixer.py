import os
import re

def fix_file(file_path, fixes):
    if not os.path.exists(file_path):
        print(f"Skipping {file_path}: File not found")
        return
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for pattern, replacement in fixes:
        new_content = re.sub(pattern, replacement, new_content)
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed errors in: {file_path}")
    else:
        print(f"No errors found in: {file_path}")

def main():
    # 1. إصلاح إصدارات Gradle و Kotlin لتتوافق مع Java 17
    fix_file('android/build.gradle', [
        (r"com\.android\.tools\.build:gradle:[\d\.]+", "com.android.tools.build:gradle:8.1.1"),
        (r"ext\.kotlin_version = .*", "ext.kotlin_version = '1.9.10'")
    ])

    # 2. إصلاح مشكلة الأيقونة المفقودة في المينافيست
    fix_file('android/app/src/main/AndroidManifest.xml', [
        (r'android:icon="@mipmap/ic_launcher"', 'android:icon="@android:drawable/sym_def_app_icon"')
    ])

    # 3. تحديث أدوات الرفع القديمة في ملفات سير العمل
    workflow_dir = '.github/workflows'
    if os.path.exists(workflow_dir):
        for f in os.listdir(workflow_dir):
            if f.endswith('.yml'):
                fix_file(os.path.join(workflow_dir, f), [
                    (r"actions/upload-artifact@v3", "actions/upload-artifact@v4"),
                    (r"actions/checkout@v3", "actions/checkout@v4")
                ])

if __name__ == "__main__":
    try:
        main()
        print("Auto-repair completed successfully.")
    except Exception as e:
        print(f"Warning: Auto-repair encountered an issue: {e}")
        
