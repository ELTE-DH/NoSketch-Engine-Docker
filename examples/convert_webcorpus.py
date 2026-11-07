#!/usr/bin/env python3

import sys
import argparse
from pathlib import Path
from urllib.parse import urlparse
from collections import defaultdict, Counter


def close_tags(tags, last, empty_counter, fn, lineno, out_fh):
    for tag in tags:
        if last[tag]:  # True/False
            print(f'</{tag}>', file=out_fh)
            if empty_counter[tag] == 0:
                print('WARNING: EMPTY ELEMENT', tag, fn, lineno, file=sys.stderr)
            empty_counter[tag] = 0
            last[tag] = False


def process_one_file(fn, inp_fh, out_fh):
    suffixes = ''.join(fn.suffixes)
    file_name_wo_suffixes = fn.name[:-len(suffixes)] if len(suffixes) > 0 else fn.name
    lineno = -1
    curr_docid = 1
    curr_sentid = 1
    last = defaultdict(bool)
    empty_counter = Counter()

    header = next(inp_fh).strip().split('\t')  # emtsv header
    for lineno, line in enumerate(inp_fh, start=2):
        line = line.strip()
        if line.startswith('# newdoc id = '):  # New doc
            docid = f'{file_name_wo_suffixes}_{curr_docid}'
            curr_docid += 1
            curr_sentid = 1
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
            print(f'<s id="{curr_sentid}">', file=out_fh)  # Open s
            curr_sentid += 1
            last['s'] = True
            empty_counter['s'] = 0
        elif last['doc'] and last['p'] and last['s'] and len(line) > 0:  # New token in doc, p and s
            try:
                form, wsafter, lemma, pos, *others = line.split('\t')
            except ValueError:
                print('ERROR: cannot split to form, wsafter, lemma and pos', fn, lineno, line, file=sys.stderr)
                break

            # Check others
            if len(others) != len(header[4:]):
                print('ERROR: Line/header mismatch', fn, lineno, line, header, file=sys.stderr)
                break

            # Escapes for the vertical format
            new_elems = []
            for elem in (form, lemma, pos, *others):
                elem = elem.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('\t', '_')
                if len(elem) == 0:
                    elem = '_'
                    print('ERROR: Empty elem', fn, lineno, line, file=sys.stderr)
                new_elems.append(elem)

            print(*new_elems, sep='\t', file=out_fh)
            if len(wsafter) == 2:  # "" -> No whitespace after
                print('<g/>', file=out_fh)
            empty_counter['doc'] += 1
            empty_counter['p'] += 1
            empty_counter['s'] += 1
        elif len(line) == 0:
            pass  # Empty line between sentences -> Nothing to do
        else:
            print('ERROR: Unexpected line', fn, lineno, line, file=sys.stderr)
            break

    close_tags(('s', 'p', 'doc'), last, empty_counter, fn, lineno, out_fh)  # Close file ending s-p-doc


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--filename', required=True,
                        help='Filename of input file (used for error messages and ID generation.'
                             ' Content is read from STDIN')
    parser.add_argument('--outdir', required=True,
                        help='Output directory (used for creating and checking emptiness.'
                             ' Content is written to STDOUT')
    args = parser.parse_args()

    filename = Path(args.filename)
    out_dir = Path(args.outdir)
    out_dir.mkdir(exist_ok=True)

    print(f'Processing: {filename}', file=sys.stderr)
    process_one_file(filename, inp_fh=sys.stdin, out_fh=sys.stdout)
