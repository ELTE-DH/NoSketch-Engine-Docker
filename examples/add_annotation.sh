#!/bin/bash

# You may set: --memory=8g down to 2g except for 2017_2018_0247.tsv.gz and 2019_0199.tsv.gz
# e.g. The word "É-D-É-D-É-D-É-D-É-D-É-D-É-D-É-D" need 8GB because the combinatorial explosion of analyses
# Set the number of parallel processes
PROC=$(nproc)
export LC_ALL="C.UTF-8" && printf '%s\n' webcorpus_orig/2017_2018_{0001..3697}.tsv.gz \
        webcorpus_orig/2019_{0001..0600}.tsv.gz webcorpus_orig/wiki_{0001..0168}.tsv.gz | \
        parallel --halt now,fail=1 -j"${PROC}" -I {} 'pigz -cd {} \
        | docker run --rm --memory=8g --memory-swap=-1 -i --entrypoint python3 \
        mtaril/emtsv:latest /app/main.py --conllu-comments chunk,morph \
        | python3 reformat_emtsv.py --filename {} | python3 convert_webcorpus.py --filename {} --outdir webcorpus_ske \
        | pigz -n > webcorpus_ske/ske_{}'
