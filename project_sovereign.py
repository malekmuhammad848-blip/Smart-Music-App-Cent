import os
import re
import sys

class RepoFixer:
    def __init__(self):
        self.root_path = os.getcwd()
        self.errors_fixed = 0

    def replace_in_file(self, file_path, pattern, replacement):
        if not os.path.exists(file_path):
            return
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        new_content = re.sub(pattern, replacement, content)
        
        if new_content != content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            self.errors_fixed += 1
            print(f"[FIXED] {file_path}")

    def fix_gradle_versions(self):
        # Fix Gradle tools version
        gradle_path = os.path.join(self.root_path, "android", "build.gradle")
        self.replace_in_file(
            gradle_path,
            r"com\.android\.tools\.build:gradle:[\d\.]+",
            "com.android.tools.build:gradle:8.1.1"
        )
        
        # Fix Kotlin version
        self.replace_in_file(
            gradle_path,
            r"ext\.kotlin_version = .*",
            "ext.kotlin_version = '1.9.10'"
        )

    def fix_manifest_icon(self):
        # Fix Manifest icon to use system default if custom icon is missing
        manifest_path = os.path.join(self.root_path, "android", "app", "src", "main", "AndroidManifest.xml")
        self.replace_in_file(
            manifest_path,
            r'android:icon="@mipmap/ic_launcher"',
            'android:icon="@android:drawable/sym_def_app_icon"'
        )

    def fix_workflow_deprecated_actions(self):
        # Fix deprecated upload-artifact v3 to v4
        workflow_dir = os.path.join(self.root_path, ".github", "workflows")
        if os.path.exists(workflow_dir):
            for filename in os.listdir(workflow_dir):
                if filename.endswith(".yml") or filename.endswith(".yaml"):
                    path = os.path.join(workflow_dir, filename)
                    self.replace_in_file(path, r"actions/upload-artifact@v3", "actions/upload-artifact@v4")
                    self.replace_in_file(path, r"actions/checkout@v3", "actions/checkout@v4")

    def run_all_fixes(self):
        print("Starting repository auto-repair...")
        self.fix_gradle_versions()
        self.fix_manifest_icon()
        self.fix_workflow_deprecated_actions()
        print(f"Repair finished. Total issues fixed: {self.errors_fixed}")

if __name__ == "__main__":
    fixer = RepoFixer()
    fixer.run_all_fixes()
    
