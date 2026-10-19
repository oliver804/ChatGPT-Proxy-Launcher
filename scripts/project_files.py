"""Explicit export boundary: never publish a whole working directory recursively."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent
ROOT_FILES = {
    '.editorconfig', '.gitattributes', '.gitignore', 'VERSION', 'LICENSE', 'Makefile',
    'THIRD_PARTY_NOTICES.md', 'README.md', 'README.en.md', 'AUTHORS.md', 'CHANGELOG.md', 'CONTRIBUTING.md', 'SECURITY.md',
}
# Only reviewed documentation and brand images are included in source exports.
DOCUMENTATION_IMAGES = {'docs/images/preview-dark.png', 'docs/images/preview-light.png', 'site/assets/icon.png', 'docs/images/preview-dark.en.png', 'docs/images/preview-light.en.png'}
SOURCE_DIRS = {'.github', 'Sources', 'Tests', 'Resources', 'scripts', 'docs', 'site', 'Windows'}
EXTENSIONS = {'.swift', '.py', '.sh', '.md', '.txt', '.plist', '.html', '.yml', '.yaml', '.css', '.js', '.cs', '.csproj', '.manifest', '.ps1', '.iss'}


def version():
    value = (ROOT / 'VERSION').read_text().strip()
    if not re.fullmatch(r'\d+\.\d+\.\d+', value):
        raise ValueError('Invalid VERSION')
    return value


def source_files():
    result = []
    for name in sorted(ROOT_FILES | DOCUMENTATION_IMAGES):
        path = ROOT / name
        if path.exists():
            if path.is_symlink():
                raise ValueError('Symlinks are not allowed in source exports')
            result.append(path)
    for name in sorted(SOURCE_DIRS):
        directory = ROOT / name
        if directory.is_symlink():
            raise ValueError('Symlinked source directories are not allowed')
        if not directory.exists():
            continue
        for path in sorted(directory.rglob('*')):
            if path.is_symlink():
                raise ValueError('Symlinks are not allowed in source exports')
            if path.is_file() and path.suffix in EXTENSIONS and not {'__pycache__', 'bin', 'obj'}.intersection(path.relative_to(ROOT).parts):
                result.append(path)
    return sorted(result)
