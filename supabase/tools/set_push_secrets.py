"""Gives the push secrets to Supabase without printing them.

Usage (from the project folder):
    python supabase/tools/set_push_secrets.py "C:\\path\\to\\firebase-key.json"

Sets on the hosted project:
  PUSH_SECRET           read from supabase/.env (shared with push_config SQL)
  FCM_SERVICE_ACCOUNT   the Firebase service account JSON (the key file)

The key file is only read here; nothing is written to the repository.
"""
import json
import os
import subprocess
import sys
import tempfile

PROJECT_REF = 'zycgqyugzzijpgbnlflt'
here = os.path.dirname(os.path.abspath(__file__))
env_path = os.path.join(here, '..', '.env')

if len(sys.argv) != 2:
    sys.exit(__doc__)

key = json.load(open(sys.argv[1], encoding='utf-8'))
if key.get('type') != 'service_account' or 'private_key' not in key:
    sys.exit('This is not a Firebase service account key file.')

push_secret = None
for line in open(env_path, encoding='utf-8'):
    if line.startswith('PUSH_SECRET='):
        push_secret = line.split('=', 1)[1].strip()
if not push_secret:
    sys.exit('PUSH_SECRET is missing from supabase/.env')

# One-line JSON in single quotes: the env-file parser keeps it as is.
one_line = json.dumps(key, separators=(',', ':'))
if "'" in one_line:
    sys.exit('Unexpected quote in the key file.')

fd, tmp = tempfile.mkstemp(suffix='.env')
try:
    with os.fdopen(fd, 'w', encoding='utf-8') as f:
        f.write(f'PUSH_SECRET={push_secret}\n')
        f.write(f"FCM_SERVICE_ACCOUNT='{one_line}'\n")
    r = subprocess.run(
        ['supabase', 'secrets', 'set', '--env-file', tmp,
         '--project-ref', PROJECT_REF],
        capture_output=True, text=True, shell=os.name == 'nt',
    )
    out = (r.stdout + r.stderr).replace(push_secret, '***')
    print(out.strip() or 'done')
    if r.returncode != 0:
        sys.exit(r.returncode)
    print(f'OK: push secrets set for project {key.get("project_id")}.')
finally:
    os.remove(tmp)
