"""Generate native runners using the installed stable Flutter SDK."""
import subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'mobile'
missing = [platform for platform in ['android', 'ios'] if not (root / platform).exists()]
if missing:
    subprocess.run(['flutter','create','--project-name','hopely_care','--org','id.hopely','--platforms',','.join(missing),'--no-pub','.'],cwd=root,check=True)
# Only debug builds permit the HTTP emulator endpoint; release enforces HTTPS in Dart.
p=root/'android/app/src/debug/AndroidManifest.xml'
p.parent.mkdir(parents=True,exist_ok=True)
p.write_text('<manifest xmlns:android="http://schemas.android.com/apk/res/android"><uses-permission android:name="android.permission.INTERNET"/><application android:usesCleartextTraffic="true"/></manifest>')
p=root/'android/app/src/main/AndroidManifest.xml'
s=p.read_text()
if 'android.permission.INTERNET' not in s:
    s=s.replace('<application','<uses-permission android:name="android.permission.INTERNET"/><application',1)
p.write_text(s)
subprocess.run(['flutter','pub','get'],cwd=root,check=True)
print('Native runners ready. Existing platform configuration preserved.')
