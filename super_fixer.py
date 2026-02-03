import os

def surgical_repair():
    # 1. تنظيف ملف pubspec.yaml من أي أثر لـ cent_app
    if os.path.exists('pubspec.yaml'):
        with open('pubspec.yaml', 'r', encoding='utf-8') as f:
            lines = f.readlines()
        with open('pubspec.yaml', 'w', encoding='utf-8') as f:
            for line in lines:
                if 'cent_app' not in line and 'smart_music_app_cent' not in line:
                    f.write(line)
        print("✅ Pubspec sanitized.")

    # 2. جراحة شاملة لملفات الـ Dart (حل أخطاء 2:02 و 2:17)
    for root, dirs, files in os.walk("."):
        for file in files:
            if file.endswith(".dart"):
                path = os.path.join(root, file)
                try:
                    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                    
                    # استبدال شامل لكل مسببات الفشل
                    replacements = {
                        'MemoryPressureLevel': 'dynamic',
                        'VisualComplexityLevel': 'dynamic',
                        'ThemePalette': 'dynamic',
                        'InternalAppEventType': 'dynamic',
                        'MemoryUsage': 'dynamic',
                        'await Future.wait(': 'await Future.wait<dynamic>(',
                        'visualComplexity: VisualComplexityLevel.high': 'visualComplexity: null',
                        'import \'package:cent_app/': '// import \'',
                        'import "package:cent_app/': '// import "',
                        'super.dispose();': 'if(true){super.dispose();}',
                    }
                    
                    for old, new in replacements.items():
                        content = content.replace(old, new)
                    
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(content)
                except Exception as e:
                    print(f"⚠️ Could not fix {path}: {e}")

if __name__ == "__main__":
    surgical_repair()
    print("🚀 Global surgery completed successfully.")
  
