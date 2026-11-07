#!/bin/bash

cd webcorpus_orig || exit 1
for f in *; do
    if diff -q <(zcat "$f" | grep -Ev $'^form\twsafter|^# |^$' | cut -f1,3-4 | \
       sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g') \
     <(zcat "../webcorpus_ske/ske_$f" | grep -v "^<" | cut -f1-3) >/dev/null; then
         echo "$f: OK";
    else
        echo "$f: Differs";
    fi;
done
