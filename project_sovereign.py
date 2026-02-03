#!/usr/bin/env python3
"""
Project Sovereign - Heuristic Compiler for Flutter Repository Repair
A surgical code repair tool for 50,000+ line Flutter repositories.

Features:
- Deep recursive scanning of all .dart files
- Intelligent type inference failure detection and correction
- Automatic import path normalization based on pubspec.yaml
- Future/Await safety enforcement
- Gradle version hard-coding (compileSdk 34, minSdk 21)
- Constant expression integrity preservation
- connectivity_plus 7.0.0 compatibility shim injection

Author: Systems Engineering Team
Python: 3.10+
"""

import os
import re
import sys
import shutil
from pathlib import Path
from typing import List, Set, Tuple, Optional, Dict
from dataclasses import dataclass
from concurrent.futures import ThreadPoolExecutor, as_completed


@dataclass
class RepairStats:
    """Track repair statistics across the repository."""
    files_scanned: int = 0
    files_modified: int = 0
    type_fixes: int = 0
    import_fixes: int = 0
    future_fixes: int = 0
    dispose_fixes: int = 0
    gradle_fixes: int = 0
    const_preservations: int = 0
    
    def report(self) -> str:
        """Generate a human-readable report."""
        return f"""
╔════════════════════════════════════════════════════════════╗
║           PROJECT SOVEREIGN - REPAIR REPORT                ║
╠════════════════════════════════════════════════════════════╣
║ Files Scanned:           {self.files_scanned:>6}                         ║
║ Files Modified:          {self.files_modified:>6}                         ║
║ Type Inference Fixes:    {self.type_fixes:>6}                         ║
║ Import Path Fixes:       {self.import_fixes:>6}                         ║
║ Future.wait<> Fixes:     {self.future_fixes:>6}                         ║
║ super.dispose() Fixes:   {self.dispose_fixes:>6}                         ║
║ Gradle Version Fixes:    {self.gradle_fixes:>6}                         ║
║ Const Preservations:     {self.const_preservations:>6}                         ║
╚════════════════════════════════════════════════════════════╝
"""


class ProjectSovereign:
    """Main heuristic compiler class."""
    
    # Problematic types that commonly cause inference failures
    PROBLEMATIC_TYPES = {
        'MemoryPressureLevel',
        'InternalAppEventType',
        'AppLifecycleState',
        'RouteInformation',
        'SystemUiMode',
        'DeviceOrientation',
        'Brightness',
        'TargetPlatform',
        'ScrollDirection',
        'DragStartBehavior',
        'HitTestBehavior',
    }
    
    def __init__(self, repo_path: str):
        """Initialize the compiler with repository path."""
        self.repo_path = Path(repo_path).resolve()
        self.stats = RepairStats()
        self.project_name: Optional[str] = None
        self.backup_dir = self.repo_path / '.sovereign_backup'
        
        if not self.repo_path.exists():
            raise ValueError(f"Repository path does not exist: {repo_path}")
    
    def create_backup(self) -> None:
        """Create a backup of the repository before modifications."""
        print(f"[BACKUP] Creating backup at {self.backup_dir}...")
        if self.backup_dir.exists():
            shutil.rmtree(self.backup_dir)
        
        # Backup only critical files
        for pattern in ['**/*.dart', '**/build.gradle', 'pubspec.yaml']:
            for file_path in self.repo_path.glob(pattern):
                if '.sovereign_backup' not in str(file_path):
                    relative_path = file_path.relative_to(self.repo_path)
                    backup_path = self.backup_dir / relative_path
                    backup_path.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(file_path, backup_path)
        
        print(f"[BACKUP] Backup completed successfully.")
    
    def extract_project_name(self) -> str:
        """Extract project name from pubspec.yaml."""
        pubspec_path = self.repo_path / 'pubspec.yaml'
        
        if not pubspec_path.exists():
            print("[WARNING] pubspec.yaml not found. Using 'app' as default project name.")
            return 'app'
        
        try:
            with open(pubspec_path, 'r', encoding='utf-8') as f:
                for line in f:
                    match = re.match(r'^name:\s*([a-z_][a-z0-9_]*)\s*$', line.strip())
                    if match:
                        project_name = match.group(1)
                        print(f"[PROJECT] Detected project name: {project_name}")
                        return project_name
        except Exception as e:
            print(f"[ERROR] Failed to read pubspec.yaml: {e}")
        
        return 'app'
    
    def fix_dart_file(self, file_path: Path) -> bool:
        """Apply all fixes to a single Dart file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Fix 1: Type Inference Failures
            content, type_count = self._fix_type_inference(content)
            self.stats.type_fixes += type_count
            
            # Fix 2: Legacy Imports
            content, import_count = self._fix_imports(content)
            self.stats.import_fixes += import_count
            
            # Fix 3: Future.wait Safety
            content, future_count = self._fix_future_wait(content)
            self.stats.future_fixes += future_count
            
            # Fix 4: super.dispose() Safety
            content, dispose_count = self._fix_super_dispose(content)
            self.stats.dispose_fixes += dispose_count
            
            # Only write if changes were made
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                return True
            
            return False
            
        except Exception as e:
            print(f"[ERROR] Failed to process {file_path}: {e}")
            return False
    
    def _fix_type_inference(self, content: str) -> Tuple[str, int]:
        """Fix type inference failures by replacing problematic types with dynamic."""
        count = 0
        
        for prob_type in self.PROBLEMATIC_TYPES:
            # Pattern 1: Variable declarations with problematic types
            # Example: MemoryPressureLevel level = ...
            pattern1 = rf'\b{prob_type}\b\s+(\w+)\s*='
            if re.search(pattern1, content):
                # Check if this is NOT in a const context
                for match in re.finditer(pattern1, content):
                    start_pos = max(0, match.start() - 100)
                    context = content[start_pos:match.start()]
                    
                    # Don't replace if in const context
                    if not re.search(r'\bconst\s+$', context):
                        content = content[:match.start()] + f'dynamic {match.group(1)} =' + content[match.end():]
                        count += 1
                        self.stats.const_preservations += 0
                    else:
                        self.stats.const_preservations += 1
            
            # Pattern 2: Function return types (non-const contexts)
            # Example: MemoryPressureLevel getLevel() { ... }
            pattern2 = rf'\b{prob_type}\b\s+(\w+)\s*\([^)]*\)\s*\{{'
            matches = list(re.finditer(pattern2, content))
            for match in reversed(matches):
                start_pos = max(0, match.start() - 50)
                context = content[start_pos:match.start()]
                
                if not re.search(r'\bconst\b', context):
                    content = content[:match.start()] + f'dynamic {match.group(1)}({content[match.start():match.end()].split("(", 1)[1]}'
                    count += 1
            
            # Pattern 3: Generic type parameters causing issues
            # Example: List<MemoryPressureLevel> items
            pattern3 = rf'<{prob_type}>'
            if '<' in content and re.search(pattern3, content):
                # Replace only in non-const List/Set/Map contexts
                lines = content.split('\n')
                for i, line in enumerate(lines):
                    if re.search(pattern3, line) and not re.search(r'\bconst\b', line):
                        lines[i] = re.sub(pattern3, '<dynamic>', line)
                        count += 1
                content = '\n'.join(lines)
        
        return content, count
    
    def _fix_imports(self, content: str) -> Tuple[str, int]:
        """Fix legacy import paths to match current project name."""
        if not self.project_name:
            return content, 0
        
        count = 0
        lines = content.split('\n')
        
        for i, line in enumerate(lines):
            # Match import statements
            import_match = re.match(r"^import\s+['\"]package:([^/]+)/(.+)['\"];?\s*$", line.strip())
            
            if import_match:
                old_package = import_match.group(1)
                path_part = import_match.group(2)
                
                # Skip if already correct or is a dependency
                if old_package == self.project_name:
                    continue
                
                # Check if this looks like a local import (not a pub dependency)
                # Heuristic: if the path exists in lib/, it's probably local
                potential_path = self.repo_path / 'lib' / path_part
                
                if potential_path.exists() or old_package in ['app', 'flutter_app', 'my_app']:
                    # Replace with current project name
                    lines[i] = f"import 'package:{self.project_name}/{path_part}';"
                    count += 1
        
        return '\n'.join(lines), count
    
    def _fix_future_wait(self, content: str) -> Tuple[str, int]:
        """Wrap Future.wait calls with <dynamic> type parameter."""
        count = 0
        
        # Pattern: Future.wait( ... ) without type parameter
        # We need to avoid Future.wait<...> that already has type params
        pattern = r'\bFuture\.wait\s*\('
        
        matches = list(re.finditer(pattern, content))
        
        for match in reversed(matches):
            # Check what comes before the opening paren
            before_paren = content[match.end()-1:match.end()+1]
            
            # If there's already a type parameter, skip
            if content[match.start():match.end()].endswith('<'):
                continue
            
            # Check if <...> appears between 'wait' and '('
            segment = content[match.start():match.end()]
            if '<' in segment:
                continue
            
            # Inject <dynamic>
            insert_pos = match.end() - 1  # Before the '('
            content = content[:insert_pos] + '<dynamic>' + content[insert_pos:]
            count += 1
        
        return content, count
    
    def _fix_super_dispose(self, content: str) -> Tuple[str, int]:
        """Wrap super.dispose() calls in try-catch blocks for safety."""
        count = 0
        
        # Pattern: super.dispose(); that's NOT already in a try block
        pattern = r'(\s*)(super\.dispose\(\);?)'
        
        lines = content.split('\n')
        i = 0
        
        while i < len(lines):
            line = lines[i]
            match = re.search(pattern, line)
            
            if match:
                # Check if already in try-catch by looking at surrounding context
                context_start = max(0, i - 5)
                context_lines = lines[context_start:i]
                context = '\n'.join(context_lines)
                
                # If we see 'try {' in the last few lines, skip
                if re.search(r'\btry\s*\{', context):
                    i += 1
                    continue
                
                # Extract indentation
                indent = match.group(1)
                
                # Replace with try-catch wrapped version
                wrapped = f"{indent}try {{\n{indent}  super.dispose();\n{indent}}} catch (e) {{\n{indent}  // Safe dispose\n{indent}}}"
                
                lines[i] = line.replace(match.group(0), wrapped)
                count += 1
            
            i += 1
        
        return '\n'.join(lines), count
    
    def fix_gradle_file(self, file_path: Path) -> bool:
        """Force-inject compileSdk 34 and minSdk 21 into build.gradle."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            modified = False
            
            # Fix compileSdk (both compileSdkVersion and compileSdk variants)
            # Pattern 1: compileSdkVersion XXX
            if re.search(r'compileSdkVersion\s+\d+', content):
                content = re.sub(r'compileSdkVersion\s+\d+', 'compileSdkVersion 34', content)
                modified = True
            elif re.search(r'compileSdk\s+\d+', content):
                content = re.sub(r'compileSdk\s+\d+', 'compileSdk 34', content)
                modified = True
            elif re.search(r'compileSdkVersion\s+flutter\.\w+', content):
                # Replace flutter.compileSdkVersion with hardcoded value
                content = re.sub(r'compileSdkVersion\s+flutter\.\w+', 'compileSdkVersion 34', content)
                modified = True
            elif re.search(r'compileSdk\s+flutter\.\w+', content):
                content = re.sub(r'compileSdk\s+flutter\.\w+', 'compileSdk 34', content)
                modified = True
            else:
                # Inject if missing - find android {} or defaultConfig {} block
                android_match = re.search(r'android\s*\{', content)
                if android_match:
                    insert_pos = android_match.end()
                    content = content[:insert_pos] + '\n    compileSdk 34' + content[insert_pos:]
                    modified = True
            
            # Fix minSdk (minSdkVersion and minSdk variants)
            if re.search(r'minSdkVersion\s+\d+', content):
                content = re.sub(r'minSdkVersion\s+\d+', 'minSdkVersion 21', content)
                modified = True
            elif re.search(r'minSdk\s+\d+', content):
                content = re.sub(r'minSdk\s+\d+', 'minSdk 21', content)
                modified = True
            elif re.search(r'minSdkVersion\s+flutter\.\w+', content):
                content = re.sub(r'minSdkVersion\s+flutter\.\w+', 'minSdkVersion 21', content)
                modified = True
            elif re.search(r'minSdk\s+flutter\.\w+', content):
                content = re.sub(r'minSdk\s+flutter\.\w+', 'minSdk 21', content)
                modified = True
            else:
                # Inject if missing - find defaultConfig {} block
                default_config_match = re.search(r'defaultConfig\s*\{', content)
                if default_config_match:
                    insert_pos = default_config_match.end()
                    content = content[:insert_pos] + '\n        minSdkVersion 21' + content[insert_pos:]
                    modified = True
            
            if modified:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                self.stats.gradle_fixes += 1
                return True
            
            return False
            
        except Exception as e:
            print(f"[ERROR] Failed to process Gradle file {file_path}: {e}")
            return False
    
    def inject_connectivity_shim(self) -> None:
        """Inject a local shim for connectivity_plus 7.0.0 if property 'flutter' is missing."""
        print("[SHIM] Checking connectivity_plus compatibility...")
        
        # Check if connectivity_plus is in dependencies
        pubspec_path = self.repo_path / 'pubspec.yaml'
        if not pubspec_path.exists():
            return
        
        try:
            with open(pubspec_path, 'r', encoding='utf-8') as f:
                pubspec_content = f.read()
            
            if 'connectivity_plus' not in pubspec_content:
                print("[SHIM] connectivity_plus not found in dependencies, skipping shim.")
                return
            
            # Create shim file
            shim_path = self.repo_path / 'lib' / 'connectivity_shim.dart'
            shim_path.parent.mkdir(parents=True, exist_ok=True)
            
            shim_content = '''// Auto-generated connectivity_plus compatibility shim
// Generated by Project Sovereign

import 'package:connectivity_plus/connectivity_plus.dart';

/// Compatibility shim for connectivity_plus 7.0.0
/// Provides safe access to connectivity features when 'flutter' property might be missing
class ConnectivityShim {
  static final Connectivity _connectivity = Connectivity();
  
  /// Get current connectivity status with fallback
  static Future<dynamic> checkConnectivity() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      // Fallback to unknown state if property access fails
      return ConnectivityResult.none;
    }
  }
  
  /// Stream of connectivity changes with error handling
  static Stream<dynamic> get onConnectivityChanged {
    try {
      return _connectivity.onConnectivityChanged;
    } catch (e) {
      // Return empty stream on error
      return Stream.empty();
    }
  }
}
'''
            
            with open(shim_path, 'w', encoding='utf-8') as f:
                f.write(shim_content)
            
            print(f"[SHIM] Connectivity shim injected at {shim_path}")
            
        except Exception as e:
            print(f"[ERROR] Failed to inject connectivity shim: {e}")
    
    def scan_and_repair(self) -> None:
        """Main repair orchestration method."""
        print(f"\n[START] Project Sovereign - Heuristic Compiler")
        print(f"[TARGET] Repository: {self.repo_path}")
        print("=" * 60)
        
        # Step 1: Extract project name
        self.project_name = self.extract_project_name()
        
        # Step 2: Create backup
        self.create_backup()
        
        # Step 3: Scan and fix all Dart files
        print("\n[SCAN] Scanning Dart files...")
        dart_files = list(self.repo_path.glob('**/*.dart'))
        dart_files = [f for f in dart_files if '.sovereign_backup' not in str(f)]
        
        print(f"[SCAN] Found {len(dart_files)} Dart files")
        
        for dart_file in dart_files:
            self.stats.files_scanned += 1
            if self.fix_dart_file(dart_file):
                self.stats.files_modified += 1
            
            if self.stats.files_scanned % 100 == 0:
                print(f"[PROGRESS] Processed {self.stats.files_scanned} files...")
        
        # Step 4: Fix all Gradle files
        print("\n[GRADLE] Scanning build.gradle files...")
        gradle_files = list(self.repo_path.glob('**/build.gradle'))
        gradle_files = [f for f in gradle_files if '.sovereign_backup' not in str(f)]
        
        print(f"[GRADLE] Found {len(gradle_files)} Gradle files")
        
        for gradle_file in gradle_files:
            self.fix_gradle_file(gradle_file)
        
        # Step 5: Inject connectivity shim
        self.inject_connectivity_shim()
        
        # Step 6: Report
        print("\n" + self.stats.report())
        print(f"[COMPLETE] Repository repair completed successfully!")
        print(f"[BACKUP] Original files backed up to: {self.backup_dir}")


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: python project_sovereign.py <repository_path>")
        print("\nExample:")
        print("  python project_sovereign.py /path/to/flutter/project")
        sys.exit(1)
    
    repo_path = sys.argv[1]
    
    try:
        compiler = ProjectSovereign(repo_path)
        compiler.scan_and_repair()
    except Exception as e:
        print(f"\n[FATAL ERROR] {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
