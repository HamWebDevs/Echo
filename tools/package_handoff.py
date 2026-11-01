"""Create reviewable source/store archives without credentials, caches or toolchains."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / 'dist'
DIST.mkdir(exist_ok=True)
(DIST / '.gdignore').touch()
EXCLUDED_DIRS = {'.git', '.godot', '.tools', '.gradle', 'node_modules', 'build', 'artifacts', 'dist', '__pycache__'}
EXCLUDED_NAMES = {'local.properties', 'services.properties', 'services.json', '.build_version', '.DS_Store'}

def source_file(path):
    relative = path.relative_to(ROOT)
    return (path.is_file() and not any(part in EXCLUDED_DIRS for part in relative.parts)
            and path.name not in EXCLUDED_NAMES
            and path.suffix.lower() not in {'.keystore', '.jks', '.log', '.pyc'})

source = DIST / 'project-echo-source.zip'
with zipfile.ZipFile(source, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    for file in sorted(ROOT.rglob('*')):
        if source_file(file):
            archive.write(file, Path('project-echo') / file.relative_to(ROOT))
    names = archive.namelist()
    assert 'project-echo/android/plugins/echo-services-release.aar' in names
    assert 'project-echo/android/plugin/gradle/wrapper/gradle-wrapper.jar' in names
    assert not any(name.endswith('/config/services.json') for name in names)

store = DIST / 'project-echo-store-kit.zip'
with zipfile.ZipFile(store, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    media = ROOT / 'docs/media'
    for directory in [ROOT / 'docs', ROOT / 'assets/store']:
        for file in sorted(directory.rglob('*')):
            if file.is_file() and 'media' not in file.relative_to(ROOT).parts and file.suffix in {'.md', '.html', '.txt', '.png', '.svg', '.mp4'}:
                archive.write(file, file.relative_to(ROOT))
    for file in sorted(media.glob('*')):
        if file.suffix in {'.png', '.mp4'}:
            archive.write(file, Path('artifacts/store') / file.name)
    archive.writestr('READ-ME-FIRST.txt',
        'HamWebDev / Project ECHO — prerelease materials.\n'
        'The name is a working title. Screenshots and clips demonstrate the actual Godot game.\n'
        'Showcase clips use scripted steering, not human playtests or retention evidence.\n'
        'Complete branding, support contact, privacy hosting and release gates before publishing.\n')

files = [source, store]
for name in ['project-echo-preview.apk', 'project-echo-unsigned.aab']:
    artifact = ROOT / 'build/android' / name
    if artifact.exists(): files.append(artifact)
manifest = {'generated_at_utc': datetime.now(timezone.utc).isoformat(), 'artifacts': []}
for file in files:
    with file.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    entry = {'path': str(file.relative_to(ROOT)), 'bytes': file.stat().st_size, 'sha256': digest}
    manifest['artifacts'].append(entry)
    print(entry['path'], entry['bytes'], entry['sha256'])
(DIST / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
