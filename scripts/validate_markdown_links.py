#!/usr/bin/env python3
"""
Validate all links and file references in markdown files.
Checks for:
- Broken internal file paths
- Malformed links
- Missing files referenced in markdown
"""

import os
import re
import sys
from pathlib import Path
from typing import List, Tuple, Dict, Set

class MarkdownLinkValidator:
    def __init__(self, repo_root: str = "."):
        self.repo_root = Path(repo_root)
        self.errors: List[Dict] = []
        self.warnings: List[Dict] = []
        
    def find_markdown_files(self) -> List[Path]:
        """Find all markdown files in the repository."""
        md_files = []
        ignore_dirs = {'.git', 'node_modules', '.github', '__pycache__', '.venv', 'venv'}
        
        for root, dirs, files in os.walk(self.repo_root):
            # Remove ignored directories from traversal
            dirs[:] = [d for d in dirs if d not in ignore_dirs]
            
            for file in files:
                if file.endswith('.md'):
                    md_files.append(Path(root) / file)
        
        return sorted(md_files)
    
    def extract_links(self, content: str) -> List[Tuple[str, int]]:
        """Extract all links from markdown content.
        Returns list of (link, line_number) tuples.
        """
        links = []
        
        # Match [text](url) pattern
        link_pattern = r'\[([^\]]+)\]\(([^)]+)\)'
        
        for line_num, line in enumerate(content.split('\n'), 1):
            matches = re.finditer(link_pattern, line)
            for match in matches:
                url = match.group(2)
                links.append((url, line_num))
        
        return links
    
    def is_external_link(self, url: str) -> bool:
        """Check if a URL is external (http/https)."""
        return url.startswith(('http://', 'https://', 'ftp://'))
    
    def is_anchor_link(self, url: str) -> bool:
        """Check if a URL is an anchor link (#section)."""
        return url.startswith('#')
    
    def resolve_file_path(self, relative_path: str, from_file: Path) -> Path:
        """Resolve a relative file path from a given markdown file."""
        # Remove anchors
        path_without_anchor = relative_path.split('#')[0]
        
        if not path_without_anchor:
            return from_file.parent / from_file.name
        
        # If absolute path, resolve from repo root
        if path_without_anchor.startswith('/'):
            return self.repo_root / path_without_anchor.lstrip('/')
        
        # If relative path, resolve from markdown file's directory
        return (from_file.parent / path_without_anchor).resolve()
    
    def validate_file(self, file_path: Path) -> None:
        """Validate all links in a single markdown file."""
        try:
            content = file_path.read_text(encoding='utf-8')
        except Exception as e:
            self.errors.append({
                'file': str(file_path.relative_to(self.repo_root)),
                'line': 0,
                'error': f'Cannot read file: {e}'
            })
            return
        
        links = self.extract_links(content)
        
        for url, line_num in links:
            # Skip external links and anchors
            if self.is_external_link(url) or self.is_anchor_link(url):
                continue
            
            # Resolve the file path
            try:
                target_path = self.resolve_file_path(url, file_path)
                
                # Check if file exists
                if not target_path.exists():
                    self.errors.append({
                        'file': str(file_path.relative_to(self.repo_root)),
                        'line': line_num,
                        'url': url,
                        'resolved_path': str(target_path.relative_to(self.repo_root)),
                        'error': 'File not found'
                    })
            except Exception as e:
                self.warnings.append({
                    'file': str(file_path.relative_to(self.repo_root)),
                    'line': line_num,
                    'url': url,
                    'warning': f'Cannot resolve path: {e}'
                })
    
    def validate_all(self) -> int:
        """Validate all markdown files and return error count."""
        print("🔍 Scanning for markdown files...")
        md_files = self.find_markdown_files()
        print(f"Found {len(md_files)} markdown files\n")
        
        for file_path in md_files:
            self.validate_file(file_path)
        
        return len(self.errors)
    
    def print_report(self) -> None:
        """Print validation report."""
        print("\n" + "="*80)
        print("MARKDOWN LINK VALIDATION REPORT")
        print("="*80 + "\n")
        
        if self.errors:
            print(f"❌ ERRORS: {len(self.errors)} broken links found\n")
            for error in self.errors:
                print(f"  File: {error['file']}:{error['line']}")
                print(f"  URL:  {error.get('url', 'N/A')}")
                if 'resolved_path' in error:
                    print(f"  Path: {error['resolved_path']}")
                print(f"  Issue: {error['error']}\n")
        else:
            print("✅ No broken links found in markdown files!\n")
        
        if self.warnings:
            print(f"⚠️  WARNINGS: {len(self.warnings)} unresolvable links\n")
            for warning in self.warnings:
                print(f"  File: {warning['file']}:{warning['line']}")
                print(f"  URL:  {warning.get('url', 'N/A')}")
                print(f"  Issue: {warning['warning']}\n")
        
        print("="*80)
        
        # Summary
        total_issues = len(self.errors) + len(self.warnings)
        if total_issues == 0:
            print("✨ All markdown links are valid!")
        else:
            print(f"Total issues: {total_issues}")
        print("="*80 + "\n")


def main():
    repo_root = os.getenv('REPO_ROOT', '.')
    
    validator = MarkdownLinkValidator(repo_root)
    error_count = validator.validate_all()
    validator.print_report()
    
    sys.exit(1 if error_count > 0 else 0)


if __name__ == '__main__':
    main()
