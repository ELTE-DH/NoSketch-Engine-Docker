#!/usr/bin/env python3

import sys
from os.path import basename
from os import makedirs, listdir
from urllib.parse import urlparse
from gzip import open as gzip_open
from collections import defaultdict, Counter


def close_tags(tags, last, empty_counter, fn, lineno, out_fh):
    for tag in tags:
        if last[tag]:  # True/False
            print(f'</{tag}>', file=out_fh)
            if empty_counter[tag] == 0:
                print('WARNING: EMPTY ELEMENT', tag, fn, lineno)
            empty_counter[tag] = 0
            last[tag] = False


def process_one_file(fn, out_fn):
    with gzip_open(fn, 'rt', encoding='UTF-8') as fh, \
            gzip_open(out_fn, 'wt', encoding='UTF-8') as out_fh:
        last = defaultdict(bool)
        empty_counter = Counter()
        next(fh)
        for lineno, line in enumerate(fh, start=2):
            line = line.strip()
            if line.startswith('# newdoc id = '):  # New doc
                docid = line[len('# newdoc id = '):]
                url = line[len('# newdoc id = '):].replace('"', '%22')
                close_tags(('s', 'p', 'doc'), last, empty_counter, fn, lineno, out_fh)  # Close s-p-doc
                if '://' in url:
                    domain = urlparse(url).netloc
                else:
                    domain = url
                print(f'<doc id="{docid}" name="{url}" domain="{domain}">', file=out_fh)  # Open doc
                last['doc'] = True
                empty_counter['doc'] = 0
            elif last['doc'] and line.startswith('# newpar id = '):  # New p in doc
                parid = line[len('# newpar id = '):]
                close_tags(('s', 'p'), last, empty_counter, fn, lineno, out_fh)  # Close s-p
                print(f'<p id="{parid}">', file=out_fh)  # Open p
                last['p'] = True
                empty_counter['p'] = 0
            elif last['doc'] and last['p'] and line.startswith('# text = '):  # New s in doc and p
                close_tags(('s',), last, empty_counter, fn, lineno, out_fh)  # Close s
                print('<s>', file=out_fh)  # Open s
                last['s'] = True
                empty_counter['s'] = 0
            elif last['doc'] and last['p'] and last['s'] and len(line) > 0:  # New token in doc, p and s
                try:
                    form, wsafter, lemma, pos = line.split('\t')
                except ValueError:
                    print('ERROR:', fn, lineno, line, file=sys.stderr)
                    break
                print(form, lemma, pos, sep='\t', file=out_fh)
                if len(wsafter) == 2:  # "" -> No whitespace after
                    print('<g/>', file=out_fh)
                empty_counter['doc'] += 1
                empty_counter['p'] += 1
                empty_counter['s'] += 1
            elif len(line) == 0:
                pass  # Empty line between sentences -> Nothing to do
            else:
                print('ERROR:', fn, lineno, line, file=sys.stderr)
                break

        close_tags(('s', 'p', 'doc'), last, empty_counter, fn, lineno, out_fh)  # Close file ending s-p-doc


if __name__ == '__main__':
    filename = sys.argv[1]  # TODO argparse...
    out_dir = 'webcorpus_ske'
    makedirs(out_dir, exist_ok=True)
    if len(listdir(out_dir)) != 0:
        print(f'Output directory ({out_dir}) is not empty!')
        exit(1)
    print(f'Processing: {filename}', file=sys.stderr)
    process_one_file(filename, f'{out_dir}/ske_{basename(filename)}')
