"""Install pinned official SDK archives locally, verifying repository checksums.

Usage: python tools/setup_android.py /absolute/sdk/path
The Android SDK remains subject to Google's SDK licence terms.
"""
import hashlib
from pathlib import Path
import os
import shutil
import sys
import tempfile
import urllib.request
import xml.etree.ElementTree as ET
import zipfile

target = Path(sys.argv[1]).resolve()
base = 'https://dl.google.com/android/repository/'
with urllib.request.urlopen(base + 'repository2-1.xml', timeout=60) as response:
    repository = ET.fromstring(response.read())
packages = {
    'build-tools_r36_linux.zip': target / 'build-tools' / '36.0.0',
    'build-tools_r36.1_linux.zip': target / 'build-tools' / '36.1.0',
    'platform-36_r02.zip': target / 'platforms' / 'android-36',
    'platform-tools_r37.0.1-linux.zip': target / 'platform-tools',
}
for filename, destination in packages.items():
    archive = next(a for a in repository.findall('.//archive') if a.findtext('./complete/url') == filename)
    checksum = archive.find('./complete/checksum')
    algorithm = checksum.get('type', 'sha1')
    if destination.exists():
        print('Already installed:', destination, flush=True)
        continue
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / filename
        print('Downloading', filename, flush=True)
        urllib.request.urlretrieve(base + filename, path)
        digest = hashlib.new(algorithm, path.read_bytes()).hexdigest()
        if digest != checksum.text.strip():
            raise SystemExit('Checksum mismatch for ' + filename)
        with zipfile.ZipFile(path) as bundle:
            extracted = Path(tmp) / 'unpacked'
            for member in bundle.infolist():
                resolved = (extracted / member.filename).resolve()
                if not resolved.is_relative_to(extracted.resolve()):
                    raise SystemExit('Unsafe archive path')
                bundle.extract(member, extracted)
                permissions = member.external_attr >> 16
                if permissions:
                    resolved.chmod(permissions & 0o777)
            roots = list(extracted.iterdir())
            assert len(roots) == 1, roots
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(roots[0]), destination)
        print('Installed:', destination, flush=True)
print('ANDROID_HOME=' + str(target))
