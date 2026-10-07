#!/usr/bin/env python3
"""Run or build one brand.

Single source of truth for the brand build commands, so the ten --web-define
values are not duplicated across launch configs, batch files and CI.

    python tool/brand.py <brand> <target> [env] [-- extra flutter args]

      brand   apexdeals | toolshub
      target  web | chrome | apk | appbundle | ios | ipa
      env     dev | prod        (default: dev for chrome, prod otherwise)

Examples
    python tool/brand.py apexdeals chrome              # run Apex Deals on :8080
    python tool/brand.py toolshub  chrome              # run ToolsHub on :8081
    python tool/brand.py toolshub  web   prod          # release web build
    python tool/brand.py apexdeals apk   prod          # release APK
    python tool/brand.py apexdeals apk   dev -- --debug

This invokes flutter with an argument LIST rather than printing a command string,
because several brand values contain spaces and an em dash — splicing them into a
shell would word-split them and mangle the encoding.
"""
import json
import os
import subprocess
import sys

BRANDS = ('apexdeals', 'toolshub')
ENTRY = {'apexdeals': 'lib/main.dart', 'toolshub': 'lib/main_toolshub.dart'}
PORT = {'apexdeals': '8080', 'toolshub': '8081'}

# Different ports per brand is not just about collisions: a different port is a
# different browser origin, so localStorage, the cart and the auth session stay
# isolated and you can be signed into both brands at once.

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def brand_values(brand):
    path = os.path.join(REPO, 'tool', 'brands', brand + '.json')
    with open(path, encoding='utf-8') as fh:
        return json.load(fh)


def main(argv):
    extra = []
    if '--' in argv:
        cut = argv.index('--')
        argv, extra = argv[:cut], argv[cut + 1:]

    if len(argv) < 2 or argv[0] not in BRANDS:
        sys.stderr.write(__doc__)
        return 2

    brand, target = argv[0], argv[1]
    env = argv[2] if len(argv) > 2 else ('dev' if target == 'chrome' else 'prod')
    if env not in ('dev', 'prod'):
        sys.stderr.write('env must be dev or prod, got %r\n' % env)
        return 2

    values = brand_values(brand)
    web_defines = ['--web-define=%s=%s' % kv for kv in values.items()]
    common = ['-t', ENTRY[brand], '--dart-define=ENV=' + env]

    if target == 'chrome':
        # --flavor is accepted by `flutter run` even for -d chrome (it selects
        # nothing there), so one arg list serves web and mobile runs.
        cmd = (['flutter', 'run', '-d', 'chrome', '--web-port', PORT[brand],
                '--web-hostname', '127.0.0.1', '--flavor', brand]
               + common + web_defines)
    elif target == 'web':
        # `flutter build web` has NO --flavor flag; passing it is a hard error.
        # The entry point is the only brand selector on web.
        cmd = (['flutter', 'build', 'web', '--release',
                '-o', 'build/web/' + brand] + common + web_defines)
    elif target in ('apk', 'appbundle', 'ios', 'ipa'):
        # --web-define is NOT valid on native builds.
        cmd = ['flutter', 'build', target, '--release',
               '--flavor', brand] + common
    else:
        sys.stderr.write('unknown target %r\n' % target)
        return 2

    cmd += extra
    print('>', ' '.join(cmd), flush=True)
    return subprocess.call(cmd, cwd=REPO, shell=(os.name == 'nt'))


if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))
