#!/bin/python3

import argparse
import sys

parser = argparse.ArgumentParser(
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    description='write partial lines to stdout to demonstrate vagrant broken output handling')
parser.add_argument(
    '--lines',
    type=int,
    default=8,
    help='number of lines')
parser.add_argument(
    '--length',
    type=int,
    default=120,
    help='line length')
parser.add_argument(
    '--flush',
    default=True,
    action='store_true',
    help='flush after each written character')
parser.add_argument(
    '--no-flush',
    dest='flush',
    default=False,
    action='store_false',
    help='do not flush after each written character')
parser.add_argument(
    '--stdout',
    default=True,
    action='store_true',
    help='write to stdout')
parser.add_argument(
    '--no-stdout',
    dest='stdout',
    default=False,
    action='store_false',
    help='do not write to stdout')
parser.add_argument(
    '--stderr',
    default=True,
    action='store_true',
    help='write to stderr')
parser.add_argument(
    '--no-stderr',
    dest='stderr',
    default=False,
    action='store_false',
    help='do not write to stderr')
args = parser.parse_args()

streams = []
if args.stdout:
    streams.append(sys.stdout)
if args.stderr:
    streams.append(sys.stderr)

for n in range(1, args.lines+1):
    prefix = '# line %04d #' % n
    line = '%s%s\n' % (prefix, '#' * (args.length - len(prefix)))
    for stream in streams:
        for c in line:
            stream.write(c)
            if args.flush:
                stream.flush()
