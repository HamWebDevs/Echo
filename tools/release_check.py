"""Fail closed on missing release-owner configuration. Does not publish anything."""
import json
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
metadata = json.loads((root / 'config/app_metadata.json').read_text())
problems = []
if not metadata.get('developer', '').strip(): problems.append('Public developer name is missing.')
if not re.fullmatch(r'[^\s@]+@[^\s@]+\.[^\s@]+', metadata.get('support_email', '')):
    problems.append('Public support email is missing or invalid.')
if not metadata.get('privacy_url', '').startswith('https://'):
    problems.append('A hosted HTTPS privacy policy URL is required.')
if metadata.get('brand_cleared') is not True:
    problems.append('Final branding has not been marked as cleared after review.')
services_path = root / 'config/services.json'
if not services_path.exists():
    problems.append('Production client service configuration has not been supplied.')
else:
    services = json.loads(services_path.read_text())
    if not services.get('revenuecat_android_api_key', '').startswith('goog_'):
        problems.append('Use the production Android public RevenueCat SDK key, not a test-store or secret key.')
    for key in ['firebase_app_id', 'firebase_project_id', 'firebase_api_key']:
        if not services.get(key): problems.append('Missing Firebase client field: ' + key)
policy = (root / 'docs/privacy-policy.html').read_text()
if '[SUPPORT EMAIL REQUIRED]' in policy or 'Publication draft:' in policy:
    problems.append('The privacy policy is still an unfinished publication draft.')
for problem in problems: print('BLOCKED:', problem)
if not problems:
    print('Configuration checks passed. Complete signed-artifact, device, purchase and Play release gates in docs/RELEASE.md.')
sys.exit(1 if problems else 0)
