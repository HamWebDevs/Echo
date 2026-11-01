"""Build native services and export a test APK or an unsigned release AAB.

Requires Godot 4.6.3 + export templates, JDK 17, Android SDK 36, build-tools
36.0.0 and 36.1.0, and platform-tools. No production signing keys are generated.
"""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import urllib.parse
import zipfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--sdk', default=os.environ.get('ANDROID_HOME'))
parser.add_argument('--java', default=os.environ.get('JAVA_HOME'))
parser.add_argument('--gradle', default=os.environ.get('ECHO_GRADLE'))
parser.add_argument('--aab', action='store_true', help='Also export an unsigned release bundle')
args = parser.parse_args()
if not args.sdk or not args.java:
    parser.error('Provide --sdk and --java, or ANDROID_HOME and JAVA_HOME.')
sdk, java = Path(args.sdk).resolve(), Path(args.java).resolve()
if not (java / 'bin/javac').exists():
    parser.error('JAVA_HOME must point to a full JDK, not a JRE.')
version = subprocess.check_output(['godot', '--version'], text=True).strip()
if not version.startswith('4.6.3.stable'):
    parser.error('This project is pinned to Godot 4.6.3.stable.')
templates = Path(os.environ.get('GODOT_EXPORT_TEMPLATES', str(Path.home() / '.local/share/godot/export_templates/4.6.3.stable')))
source = templates / 'android_source.zip'
if not source.exists():
    parser.error('Install the matching Godot export templates first.')

env = {**os.environ, 'JAVA_HOME': str(java), 'ANDROID_HOME': str(sdk)}
proxy_args = []
proxy = urllib.parse.urlparse(os.environ.get('HTTPS_PROXY', ''))
if proxy.hostname:
    for scheme in ['http', 'https']:
        proxy_args += [f'-D{scheme}.proxyHost={proxy.hostname}', f'-D{scheme}.proxyPort={proxy.port or 80}']
    # Trust the machine's installed enterprise/proxy CA without disabling TLS.
    if Path('/etc/ssl/certs/java/cacerts').exists():
        proxy_args += ['-Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts']
env['JAVA_TOOL_OPTIONS'] = ' '.join(filter(None, [os.environ.get('JAVA_TOOL_OPTIONS', ''), *proxy_args]))

build = ROOT / 'android/build'
if not (build / '.build_version').exists():
    build.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(source) as archive:
        archive.extractall(build)
    (build / '.build_version').write_text('4.6.3.stable')
    (build / '.gdignore').touch()
(ROOT / 'android/.build_version').write_text('4.6.3.stable')
(build / 'gradlew').chmod(0o755)
for project in [build, ROOT / 'android/plugin']:
    (project / 'local.properties').write_text('sdk.dir=' + str(sdk) + '\n')

logs = ROOT / 'artifacts'
logs.mkdir(exist_ok=True)
(logs / '.gdignore').touch()

def run(command, logfile, cwd=ROOT):
    with (logs / logfile).open('w') as log:
        result = subprocess.run(command, env=env, cwd=cwd, stdout=log, stderr=subprocess.STDOUT)
    text = (logs / logfile).read_text()
    if result.returncode or 'SCRIPT ERROR:' in text or 'ERROR:' in text or 'BUILD FAILED' in text:
        print(text[-12000:])
        raise SystemExit(f'Failed: {logfile}')
    print(f'Passed: {logfile}', flush=True)

gradle = [args.gradle] if args.gradle else ['bash', str(ROOT / 'android/plugin/gradlew')]
run([*gradle, '-p', str(ROOT / 'android/plugin'), 'assembleRelease', '--console=plain', '--no-daemon'], 'native-build.log')
shutil.copy2(ROOT / 'android/plugin/build/outputs/aar/echo-services-release.aar', ROOT / 'android/plugins/echo-services-release.aar')

debug_key = ROOT / '.tools/debug.keystore'
debug_key.parent.mkdir(exist_ok=True)
if not debug_key.exists():
    subprocess.run([str(java / 'bin/keytool'), '-genkeypair', '-keystore', str(debug_key),
        '-storepass', 'android', '-keypass', 'android', '-alias', 'androiddebugkey',
        '-keyalg', 'RSA', '-keysize', '2048', '-validity', '10000',
        '-dname', 'CN=Android Debug,O=Android,C=US'], check=True, env=env)

# Godot stores SDK locations in editor settings; preserve unrelated settings.
settings = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'godot/editor_settings-4.6.tres'
if not settings.exists():
    subprocess.run(['godot', '--headless', '--editor', '--path', str(ROOT), '--quit'], check=True, env=env)
text = settings.read_text()
for key, value in {
    'export/android/android_sdk_path': str(sdk),
    'export/android/java_sdk_path': str(java),
    'export/android/debug_keystore': str(debug_key),
    'export/android/debug_keystore_user': 'androiddebugkey',
    'export/android/debug_keystore_pass': 'android',
}.items():
    line = f'{key} = "{value}"'
    pattern = '^' + re.escape(key) + ' = .*$'
    if re.search(pattern, text, re.M):
        text = re.sub(pattern, lambda _: line, text, flags=re.M)
    else:
        text += '\n' + line + '\n'
settings.write_text(text)

destination = ROOT / 'build/android'
destination.mkdir(parents=True, exist_ok=True)
(ROOT / 'build/.gdignore').touch()
run(['godot', '--headless', '--path', str(ROOT), '--export-debug', 'Android APK',
     str(destination / 'project-echo.apk')], 'android-apk.log')
run(['godot', '--headless', '--path', str(ROOT), '--export-release', 'Android Preview',
     str(destination / 'project-echo-preview-unsigned.apk')], 'android-preview.log')
run([str(sdk / 'build-tools/36.1.0/apksigner'), 'sign', '--ks', str(debug_key),
     '--ks-key-alias', 'androiddebugkey', '--ks-pass', 'pass:android', '--key-pass', 'pass:android',
     '--out', str(destination / 'project-echo-preview.apk'),
     str(destination / 'project-echo-preview-unsigned.apk')], 'preview-signing.log')
run([str(sdk / 'build-tools/36.1.0/apksigner'), 'verify', '--verbose',
     str(destination / 'project-echo-preview.apk')], 'preview-signature.log')
if args.aab:
    run(['godot', '--headless', '--path', str(ROOT), '--export-release', 'Android AAB',
         str(destination / 'project-echo-unsigned.aab')], 'android-aab.log')
print('APK:', destination / 'project-echo.apk')
print('OPTIMIZED PREVIEW APK (development key):', destination / 'project-echo-preview.apk')
if args.aab:
    print('UNSIGNED AAB:', destination / 'project-echo-unsigned.aab')
    print('Use your own upload key and release configuration before submitting to Google Play.')
