"""Offline checks for the installer; never builds or touches a real phone."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class AndroidInstallerTest(unittest.TestCase):
    def run_installer(self, devices='', args=(), build_exit=0, install_exit=0):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'scripts').mkdir()
            script = root / 'scripts/install_android.sh'
            shutil.copyfile(Path(__file__).resolve().parents[1] / 'install_android.sh', script)
            binaries = root / 'bin'
            binaries.mkdir()
            mocks = {
                'flutter': '''#!/bin/bash
printf 'build\\n' >> "$CALL_LOG"
[[ "$BUILD_EXIT" == 0 ]] || exit "$BUILD_EXIT"
mkdir -p build/app/outputs/flutter-apk
printf 'test-apk' > build/app/outputs/flutter-apk/app-release.apk
''',
                'adb': '''#!/bin/bash
if [[ "$1" == devices ]]; then
  printf 'List of devices attached\\n%s\\n' "$DEVICES"
else
  printf '%s\\n' "$@" >> "$CALL_LOG"
  exit "$INSTALL_EXIT"
fi
''',
            }
            for name, content in mocks.items():
                path = binaries / name
                path.write_text(content)
                path.chmod(0o755)
            log = root / 'calls'
            env = dict(os.environ, PATH=f'{binaries}:{os.environ["PATH"]}',
                       CALL_LOG=str(log), DEVICES=devices, BUILD_EXIT=str(build_exit),
                       INSTALL_EXIT=str(install_exit))
            result = subprocess.run(['bash', str(script), *args], cwd='/', env=env,
                                    text=True, capture_output=True)
            return result.returncode, log.read_text() if log.exists() else '', (root / 'build/phone/Hexora-latest.apk').exists()

    def test_phone_selected_over_emulator(self):
        code, calls, apk = self.run_installer('emulator-5554\tdevice\nphone\tdevice')
        self.assertEqual(code, 0)
        self.assertIn('-s\nphone\ninstall\n-r\n', calls)
        self.assertTrue(apk)

    def test_no_phone_saves_without_installing(self):
        code, calls, apk = self.run_installer('emulator-5554\tdevice')
        self.assertEqual((code, calls, apk), (0, 'build\n', True))

    def test_build_only(self):
        self.assertEqual(self.run_installer('phone\tdevice', ('--build-only',)), (0, 'build\n', True))

    def test_ambiguous_or_unauthorized_stops_before_build(self):
        for devices in ['phone\tunauthorized', 'one\tdevice\ntwo\tdevice']:
            code, calls, apk = self.run_installer(devices)
            self.assertNotEqual(code, 0)
            self.assertEqual(calls, '')
            self.assertFalse(apk)

    def test_explicit_device(self):
        code, calls, _ = self.run_installer('one\tdevice\ntwo\tdevice', ('--device', 'two'))
        self.assertEqual(code, 0)
        self.assertIn('-s\ntwo\ninstall\n-r\n', calls)

    def test_build_failure_never_installs(self):
        code, calls, apk = self.run_installer('phone\tdevice', build_exit=1)
        self.assertNotEqual(code, 0)
        self.assertEqual(calls, 'build\n')
        self.assertFalse(apk)

    def test_install_failure_keeps_apk_without_uninstall(self):
        code, calls, apk = self.run_installer('phone\tdevice', install_exit=1)
        self.assertNotEqual(code, 0)
        self.assertNotIn('uninstall', calls)
        self.assertTrue(apk)


if __name__ == '__main__':
    unittest.main()
