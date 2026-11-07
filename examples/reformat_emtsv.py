#!/usr/bin/env python3

import sys
import argparse
from json import loads as json_loads
from itertools import chain, zip_longest


def parse_emtsv_format(input_iterator, keep_fields=None):
    """
    Parse the emtsv raw format into a Python structure
     (iterator, sentences as lists, tokens as dicts, keys field names, values the token's properties)
    :param input_iterator: str iterator on lines of emtsv raw data
    :param keep_fields: list or set of field names to keep or None to keep all fields
    :return: iterator: sentences as lists, tokens as dicts, keys field names, values the token's properties
    """
    header = next(input_iterator, '')
    header_splitted = [col for col in header.rstrip('\n').split('\t') if len(col) > 0]
    # Check duplicate or empty fields in header!
    if header.count('\t') + 1 != len(set(header_splitted)):
        raise ValueError(f'Input header is not valid ({header_splitted}) !')

    header_filtered, len_header_filtered = header_splitted, len(header_splitted)
    if isinstance(keep_fields, list):  # Argparse returns list which must be cast to set
        keep_fields = set(keep_fields)
    if isinstance(keep_fields, set):
        header_filtered = []
        for col in header_splitted:
            if col in keep_fields:
                header_filtered.append(col)  # Fields to keep are denoted with their name
            else:
                header_filtered.append(None)  # Fields to omit are denoted with None

    comment, sent = [], []
    for i, line in enumerate(input_iterator, start=2):  # Header is already processed, the loop starts from the 2nd line
        line = line.rstrip('\n')
        if len(line) == 0:  # State 1: empty line (after sentences)
            yield comment, sent  # Yield the collected sentence and start a new empty one
            comment, sent = [], []
        elif line.startswith('# '):  # State 2: Comment, metadata
            comment.append(line[2:])  # Strip '# ' prefix and add the comments line by line without further processing
        else:  # State 3: A line containing a token
            line_splitted = line.split('\t')  # Split to columns
            # Filter out columns not in keep_fields therefore denoted by None in header_filtered

            # zip(*_,strict=True) is available to raise ValueError in Python >=3.10
            if len_header_filtered != len(line_splitted):
                ValueError(f'For line {i} fields length ({len(line_splitted)}) does not match'
                           f' the length of the header ({len(header_splitted)}: {(header_splitted, line_splitted)} !')

            # The others are put into a token dictionary with their field name as key
            token = {k: v for k, v in zip(header_filtered, line_splitted) if k is not None}
            sent.append(token)

    if len(comment) > 0 or len(sent) > 0:  # Yield all remaining tokens or metadata lines
        yield comment, sent


def process_file(filename, inp_fh):
    header_orig = next(inp_fh)

    # Check expected header
    header = header_orig.strip().split()
    if any(ah != rh for ah, rh in zip_longest(header, ('form', 'wsafter', 'lemma', 'xpostag', 'NP-BIO', 'anas'))):
        print(f'Wrong header: {filename} {header}', file=sys.stderr)
        exit(1)

    new_header = ('form', 'wsafter', 'lemma', 'xpostag', 'NP-BIO', 'deep', 'surface', 'morphtags')
    yield '\t'.join(new_header)  # Yield new header
    for comments, sent in parse_emtsv_format(chain([header_orig], inp_fh)):
        for c in comments:
            yield f'# {c}'  # Restore comments
        for token in sent:
            deep_trip, morphtags_trip, surface_trip = format_columns(token, filename)
            token['deep'] = '+'.join(deep_trip) if len(deep_trip) > 0 else '_'
            token['morphtags'] = '+'.join(morphtags_trip) if len(morphtags_trip) > 0 else '_'
            token['surface'] = '+'.join(surface_trip) if len(surface_trip) > 0 else '_'

            yield '\t'.join(token[k] for k in new_header)


def format_columns(token, filename):
    form = token['form']
    lemma = token['lemma']
    xpostag = token['xpostag']
    anas_json = token['anas']
    anas = json_loads(anas_json)
    uniq_anas = set()

    if len(anas) == 0:
        return (), (), ()

    ret = handle_ana(form, lemma, xpostag, anas, uniq_anas, filename, pred=match_lemma_and_tag)

    return ret


def match_lemma_and_tag(ana_lemma, lemma, ana_tag, tag):
    return ana_lemma == lemma and ana_tag == tag


def match_tag(_, __, ana_tag, tag):
    return ana_tag == tag


def handle_ana(form, lemma, xpostag, anas, uniq_anas, filename, pred):
    for ana in anas:
        # Check for matching ana (first equal lemma and tag, then only by tag)
        if pred(ana['lemma'], lemma, ana['tag'], xpostag):
            morphana = ana['morphana']
            if len(morphana) > 0:
                deep_forms, morphtags, surfaces = list(zip(*parse_twolevel(ana['twolevel'])))
                deep_forms_ecaped = tuple([s.replace('+', '__PLUS__').replace(' ', '_') for s in deep_forms])
                morphtags_escaped = tuple([s.replace('+', '__PLUS__').replace(' ', '_') for s in morphtags])
                surfaces_escaped = tuple([s.replace('+', '__PLUS__').replace(' ', '_') for s in surfaces])
                morphana_triplet = (deep_forms_ecaped, morphtags_escaped , surfaces_escaped)
                uniq_anas.add(morphana_triplet)
            else:
                uniq_anas.add(((), (), ()))

    if len(uniq_anas) == 0:
        if pred != match_tag:
            # Recurse for last resort matching just on tag
            ret = handle_ana(form, lemma, xpostag, anas, uniq_anas, filename, pred=match_tag)
        else:
            print(f'No matching ana found for {lemma} and {xpostag} in {anas}', file=sys.stderr)
            return (), (), ()
    elif len(uniq_anas) > 1:
        # The least number of parts or smallest in lexicographical order
        # print(f'Multiple matching anas, chosing the shortest {lemma} and {xpostag} in {anas}', file=sys.stderr)
        shortest = min(uniq_anas, key=lambda x: (len(x[0]), x))
        ret = shortest
    else:
        ret = uniq_anas.pop()
    return ret


def parse_twolevel(inp):
    """Copied from emmorphpy (_parse_stem) + wrap tags with square brackets"""
    item_surface = ''
    item_tag = ''
    item_lexical = ''
    items = []
    state = 0
    for ch in inp:
        if state in (0, 2):
            if ch == ':':
                state += 1
            elif ch == ' ':
                item_surface += ch
            else:
                if len(item_tag) > 0:
                    items.append((item_lexical, f'[{item_tag}]', item_surface))
                    item_lexical, item_tag, item_surface, = '', '', ''

                item_surface += ch
        elif state == 1:
            if ch == '[':  # tag opening
                state = 3
                if len(item_tag) > 0:
                    items.append((item_lexical, f'[{item_tag}]', item_surface))
                    item_lexical, item_tag, item_surface, = '', '', ''
            elif ch == ' ':  # beginning of next pair
                state = 0
            else:
                item_lexical += ch
        elif state == 3:
            if ch == ']':  # tag closing
                state = 1
                items.append((item_lexical, f'[{item_tag}]', item_surface))
                item_lexical, item_tag, item_surface, = '', '', ''
            elif ch == ' ':  # beginning of next pair (remember we are inside a tag)
                state = 2
            else:
                item_tag += ch
    if len(item_tag) > 0 or len(item_lexical) > 0 or len(item_surface) > 0:
        items.append((item_lexical, f'[{item_tag}]', item_surface))

    return items  # Ez megy a stemmerbe... '+'.join(...)


def split_ana(morphana):
    """Parse the morphana format, kept for reference"""
    deep_forms = []
    tags = []
    surfaces = []
    state = 'deep'

    deep = []
    tag = []
    surface = []
    for char in morphana:
        if state == 'deep':
            if char != '[':
                deep.append(char)
            else:
                state = 'tag'
                tag.append(char)  # The first [ of a tag
        elif state == 'tag':
            if char != '=' or len(tag) == 0 or tag[-1] != ']':  # i.e. ']=' because [_PerfPtcp_Subj=tA/Adj] 'mosta'
                tag.append(char)
            else:
                state = 'surface'
        elif state == 'surface':
            if char != '+':
                surface.append(char)
            else:
                deep_forms.append(''.join(deep))
                tags.append(''.join(tag))
                surfaces.append(''.join(surface))

                deep = []
                tag = []
                surface = []
                state = 'deep'
        else:
            raise NotImplementedError(f'Unknown immediate state is not deep: {state}')

    # Handle the final triplet, which has no trailing '+'
    if state == 'surface':
        deep_forms.append(''.join(deep))
        tags.append(''.join(tag))
        surfaces.append(''.join(surface))
    else:
        raise NotImplementedError(f'Last state is not surface: {state}')

    return tuple([s.replace('+', 'PLUS').replace(' ', '_') for s in deep_forms]), \
        tuple([s.replace('+', 'PLUS').replace(' ', '_') for s in tags]), \
        tuple([s.replace('+', 'PLUS').replace(' ', '_') for s in surfaces])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--filename', required=True)
    args = parser.parse_args()

    for line in process_file(args.filename, sys.stdin):
        print(line, file=sys.stdout)
    print(f'Done {args.filename}', file=sys.stderr)


if __name__ == '__main__':
    main()
