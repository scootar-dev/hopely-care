"""Generate local secrets. Does not overwrite an existing environment."""
from pathlib import Path
import base64
import secrets
root=Path(__file__).resolve().parents[1]
path=root/'.env'
if path.exists():
    raise SystemExit('.env exists; edit it deliberately instead of overwriting secrets.')
text=(root/'.env.example').read_text()
values={'APP_KEY':'base64:'+base64.b64encode(secrets.token_bytes(32)).decode(), 'DB_PASSWORD':secrets.token_urlsafe(32),'MYSQL_ROOT_PASSWORD':secrets.token_urlsafe(32),'INTERNAL_SERVICE_KEY':secrets.token_urlsafe(48),'QDRANT_API_KEY':secrets.token_urlsafe(32),'DEMO_PASSWORD':secrets.token_urlsafe(20)}
for key,value in values.items():
    text=text.replace(key+'=\n',key+'='+value+'\n')
path.write_text(text)
path.chmod(0o600)
print('Created .env with unique local secrets. Keep it outside version control.')
