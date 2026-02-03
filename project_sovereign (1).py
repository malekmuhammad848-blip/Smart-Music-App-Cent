#!/usr/bin/env python3
"""
Project Sovereign - Surgical Repair Edition
Minimally invasive code repair for Flutter repositories.

Focus Areas:
- Remove 'const' from Interval and Curve widgets
- Add <dynamic> to Future.wait calls
- Fix local.properties with correct SDK paths
- Ensure minSdkVersion is 21

Author: Systems Engineering Team
Python: 3.10+
Version: 2.0 (Surgical)
"""

import os
import re
import sys
from pathlib import Path
from typing import Tuple, Optional
from dataclasses import dataclass


@dataclass
class RepairStats:
    """Track surgical repair statistics."""
    files_scanned: int = 0
    files_modified: int = 0
    const_fixes: int = 0
    future_fixes: int = 0
    gradle_fixes: int = 0
    
    def report(self) -> str:
        """Generate repair report."""
        return f"""
╔════════════════════════════════════════════════╗
║      PROJECT SOVEREIGN - SURGICAL REPAIR       ║
╠════════════════════════════════════════════════╣
║ Files Scanned:        {self.files_scanned:>6}                   ║
║ Files Modified:       {self.files_modified:>6}                   ║
║ Const Removals:       {self.const_fixes:>6}                   ║
║ Future.wait Fixes:    {self.future_fixes:>6}                   ║
║ Gradle Fixes:         {self.gradle_fixes:>6}                   ║
╚════════════════════════════════════════════════╝
"""


class SurgicalSovereign:
    """Surgical repair tool for Flutter repositories."""
    
    # Target widgets that need const removal
    CONST_TARGETS = {
        'Interval',
        'Curve',
        'Curves',
    }
    
    def __init__(self, repo_path: str):
        """Initialize with repository path."""
        self.repo_path = Path(repo_path).resolve()
        self.stats = RepairStats()
        
        if not self.repo_path.exists():
            raise ValueError(f"Repository path does not exist: {repo_path}")
    
    def fix_dart_file(self, file_path: Path) -> bool:
        """Apply surgical fixes to a Dart file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Fix 1: Remove const from Interval/Curve widgets
            content, const_count = self._fix_const_widgets(content)
            self.stats.const_fixes += const_count
            
            # Fix 2: Add <dynamic> to Future.wait calls
            content, future_count = self._fix_future_wait(content)
            self.stats.future_fixes += future_count
            
            # Only write if changes were made
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                return True
            
            return False
            
        except Exception as e:
            print(f"[WARNING] Could not process {file_path}: {e}")
            return False
    
    def _fix_const_widgets(self, content: str) -> Tuple[str, int]:
        """
        Remove 'const' keyword from Interval and Curve widgets.
        
        Example transformations:
        const Interval(0.0, 1.0) -> Interval(0.0, 1.0)
        const Curves.easeIn -> Curves.easeIn
        """
        count = 0
        
        for target in self.CONST_TARGETS:
            # Pattern 1: const TargetWidget(...)
            # Example: const Interval(0.0, 1.0, curve: Curves.easeIn)
            pattern1 = rf'\bconst\s+{target}\s*\('
            matches = list(re.finditer(pattern1, content))
            
            for match in reversed(matches):
                # Remove the 'const ' part, keeping the widget
                start = match.start()
                end = match.start() + len('const ')
                content = content[:start] + content[end:]
                count += 1
            
            # Pattern 2: const Curves.xyz
            # Example: const Curves.easeIn
            if target == 'Curves':
                pattern2 = r'\bconst\s+Curves\.\w+'
                matches = list(re.finditer(pattern2, content))
                
                for match in reversed(matches):
                    # Remove the 'const ' part
                    start = match.start()
                    end = match.start() + len('const ')
                    content = content[:start] + content[end:]
                    count += 1
            
            # Pattern 3: const Curve.xyz (enum-like access)
            if target == 'Curve':
                pattern3 = r'\bconst\s+Curve\.\w+'
                matches = list(re.finditer(pattern3, content))
                
                for match in reversed(matches):
                    start = match.start()
                    end = match.start() + len('const ')
                    content = content[:start] + content[end:]
                    count += 1
        
        return content, count
    
    def _fix_future_wait(self, content: str) -> Tuple[str, int]:
        """
        Add <dynamic> to Future.wait calls that don't have type parameters.
        
        Example transformation:
        Future.wait([...]) -> Future.wait<dynamic>([...])
        
        Preserves existing type parameters:
        Future.wait<String>([...]) -> Future.wait<String>([...])
        """
        count = 0
        
        # Pattern: Future.wait followed by ( without <type> in between
        # Negative lookahead ensures we don't match Future.wait<T>(
        pattern = r'\bFuture\.wait\s*(?!<)(\[|\()'
        
        matches = list(re.finditer(pattern, content))
        
        for match in reversed(matches):
            # Insert <dynamic> before the opening bracket/paren
            insert_pos = match.end() - 1  # Before the [ or (
            content = content[:insert_pos] + '<dynamic>' + content[insert_pos:]
            count += 1
        
        return content, count
    
    def fix_local_properties(self) -> bool:
        """
        Fix android/local.properties with correct SDK paths.
        Only modifies if file exists or can be created.
        """
        android_dir = self.repo_path / 'android'
        
        # Only proceed if android directory exists
        if not android_dir.exists():
            print("[INFO] android/ directory not found, skipping local.properties")
            return False
        
        local_props_path = android_dir / 'local.properties'
        
        try:
            # Create or update local.properties
            content = f"""# Auto-generated by Project Sovereign (Surgical)
# Do not modify manually

sdk.dir=/usr/local/lib/android/sdk
flutter.sdk=/opt/hostedtoolcache/flutter/stable-3.19.0-x64
"""
            
            with open(local_props_path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            print(f"[FIXED] {local_props_path}")
            self.stats.gradle_fixes += 1
            return True
            
        except Exception as e:
            print(f"[WARNING] Could not fix local.properties: {e}")
            return False
    
    def fix_gradle_min_sdk(self, gradle_path: Path) -> bool:
        """
        Ensure minSdkVersion is set to 21 in build.gradle.
        Does NOT hardcode compileSdk - leaves it as-is.
        """
        try:
            with open(gradle_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Only fix minSdk/minSdkVersion if it's less than 21 or not set
            # Pattern 1: minSdkVersion XX where XX < 21
            pattern1 = r'minSdkVersion\s+(\d+)'
            match = re.search(pattern1, content)
            
            if match:
                current_min_sdk = int(match.group(1))
                if current_min_sdk < 21:
                    content = re.sub(pattern1, 'minSdkVersion 21', content)
                    print(f"[FIXED] Updated minSdkVersion from {current_min_sdk} to 21")
                    self.stats.gradle_fixes += 1
            
            # Pattern 2: minSdk XX where XX < 21
            pattern2 = r'minSdk\s+(\d+)'
            match = re.search(pattern2, content)
            
            if match:
                current_min_sdk = int(match.group(1))
                if current_min_sdk < 21:
                    content = re.sub(pattern2, 'minSdk 21', content)
                    print(f"[FIXED] Updated minSdk from {current_min_sdk} to 21")
                    self.stats.gradle_fixes += 1
            
            # Pattern 3: minSdkVersion flutter.minSdkVersion
            if 'minSdkVersion flutter.minSdkVersion' in content:
                content = content.replace('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 21')
                print("[FIXED] Replaced flutter.minSdkVersion with 21")
                self.stats.gradle_fixes += 1
            
            # Pattern 4: minSdk flutter.minSdkVersion
            if 'minSdk flutter.minSdkVersion' in content:
                content = content.replace('minSdk flutter.minSdkVersion', 'minSdk 21')
                print("[FIXED] Replaced flutter.minSdk with 21")
                self.stats.gradle_fixes += 1
            
            # Only write if changes were made
            if content != original_content:
                with open(gradle_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                return True
            
            return False
            
        except Exception as e:
            print(f"[WARNING] Could not fix {gradle_path}: {e}")
            return False
    
    def surgical_repair(self) -> None:
        """Execute surgical repair on the repository."""
        print(f"\n[START] Project Sovereign - Surgical Repair Mode")
        print(f"[TARGET] {self.repo_path}")
        print("=" * 60)
        
        # Phase 1: Fix Dart files
        print("\n[PHASE 1] Scanning Dart files...")
        dart_files = list(self.repo_path.glob('**/*.dart'))
        
        # Filter out generated files and test files to be extra safe
        dart_files = [
            f for f in dart_files 
            if not any(x in str(f) for x in [
                '.g.dart', 
                '.freezed.dart',
                'generated_plugin_registrant.dart'
            ])
        ]
        
        print(f"[SCAN] Found {len(dart_files)} Dart files")
        
        for dart_file in dart_files:
            self.stats.files_scanned += 1
            if self.fix_dart_file(dart_file):
                self.stats.files_modified += 1
            
            if self.stats.files_scanned % 50 == 0:
                print(f"[PROGRESS] Processed {self.stats.files_scanned} files...")
        
        # Phase 2: Fix local.properties
        print("\n[PHASE 2] Fixing local.properties...")
        self.fix_local_properties()
        
        # Phase 3: Fix Gradle minSdk
        print("\n[PHASE 3] Fixing Gradle minSdkVersion...")
        gradle_files = list(self.repo_path.glob('**/build.gradle'))
        
        for gradle_file in gradle_files:
            if 'android' in str(gradle_file):
                self.fix_gradle_min_sdk(gradle_file)
        
        # Final report
        print("\n" + self.stats.report())
        print("[COMPLETE] Surgical repair finished")
        print(f"[NOTE] Modified {self.stats.files_modified} of {self.stats.files_scanned} files")


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: python3 project_sovereign.py <repository_path>")
        print("\nSurgical Repair Mode - Minimally Invasive Fixes")
        print("\nFixes Applied:")
        print("  - Remove 'const' from Interval/Curve widgets")
        print("  - Add <dynamic> to Future.wait calls")
        print("  - Fix local.properties SDK paths")
        print("  - Ensure minSdkVersion >= 21")
        print("\nWhat is NOT modified:")
        print("  - Import statements (preserved)")
        print("  - compileSdk values (preserved)")
        print("  - Generated files (skipped)")
        print("  - Project structure (unchanged)")
        sys.exit(1)
    
    repo_path = sys.argv[1]
    
    try:
        sovereign = SurgicalSovereign(repo_path)
        sovereign.surgical_repair()
        
        # Exit with success
        sys.exit(0)
        
    except Exception as e:
        print(f"\n[ERROR] {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
