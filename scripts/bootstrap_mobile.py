"""Prepare missing native runners without replacing existing configuration."""
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'mobile'
missing = [platform for platform in ['android', 'ios'] if not (root / platform).exists()]
if missing:
    subprocess.run(['flutter','create','--project-name','hopely_care','--org','id.hopely','--platforms',','.join(missing),'--no-pub','.'],cwd=root,check=True)
# Only debug builds permit the HTTP emulator endpoint; release enforces HTTPS in Dart.
p=root/'android/app/src/debug/AndroidManifest.xml'
p.parent.mkdir(parents=True,exist_ok=True)
android = 'http://schemas.android.com/apk/res/android'
ET.register_namespace('android', android)
manifest = ET.fromstring(p.read_text(), parser=ET.XMLParser(target=ET.TreeBuilder(insert_comments=True))) if p.exists() else ET.Element('manifest')
if not any(n.get(f'{{{android}}}name') == 'android.permission.INTERNET' for n in manifest.findall('uses-permission')):
    ET.SubElement(manifest, 'uses-permission', {f'{{{android}}}name': 'android.permission.INTERNET'})
application = manifest.find('application')
if application is None:
    application = ET.SubElement(manifest, 'application')
application.set(f'{{{android}}}usesCleartextTraffic', 'true')
ET.indent(manifest)
p.write_text(ET.tostring(manifest, encoding='unicode') + '\n')
p=root/'android/app/src/main/AndroidManifest.xml'
s=p.read_text()
if 'android.permission.INTERNET' not in s:
    s=s.replace('<application','<uses-permission android:name="android.permission.INTERNET"/><application',1)
p.write_text(s)
subprocess.run(['flutter','pub','get'],cwd=root,check=True)
print('Native runners ready. Existing platform configuration preserved.')
