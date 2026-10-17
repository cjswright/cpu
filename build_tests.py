#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys


def assemble(wasm, wlink, source):
    name, _ = os.path.splitext(source)
    obj = name + '.o'
    srec = name + '.srec'

    if os.path.exists(srec) and os.path.getmtime(srec) >= os.path.getmtime(source):
        return False

    subprocess.run([wasm, '-o', obj, source],
                   check=True, stdout=sys.stdout, stderr=sys.stderr)
    subprocess.run([wlink, '-o', srec, obj],
                   check=True, stdout=sys.stdout, stderr=sys.stderr)
    return True


def build_tests(wasm, wlink, tests_dir):
    errors = 0

    for f in sorted(os.listdir(tests_dir)):
        if not f.endswith('.s'):
            continue

        source = os.path.join(tests_dir, f)
        try:
            if assemble(wasm, wlink, source):
                print(f'{f} ok')
        except subprocess.CalledProcessError:
            print(f'failed to assemble {f}')
            errors += 1

    if errors > 0:
        print(f'failed to assemble {errors} file[s]')
        return 1

    return 0


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    toolchain = os.path.join(here, '..', '..', 'wramp', 'toolchain')

    parser = argparse.ArgumentParser(description='Assemble tests/*.s into tests/*.srec')
    parser.add_argument('--wasm', default=os.path.join(toolchain, 'wasm'))
    parser.add_argument('--wlink', default=os.path.join(toolchain, 'wlink'))
    parser.add_argument('--tests', default=os.path.join(here, 'tests'))
    args = parser.parse_args()

    return build_tests(args.wasm, args.wlink, args.tests)


if __name__ == '__main__':
    sys.exit(main())
