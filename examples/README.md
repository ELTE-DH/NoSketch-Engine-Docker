# Corpus configuration examples

The NoSketch Engine corpus configuration is not a trivial task for large corpora (e.g. 10^10 token).
Here we collect examples of corpus configurations for publicly available corpora to provide recipes.

For further information visit https://www.sketchengine.eu/documentation/corpus-configuration-file-all-features/

## Webcorpus 2.0

- Corpus homepage: https://hlt.bme.hu/hu/resources/webcorpus2
- Data: https://nessie.ilab.sztaki.hu/~ndavid/Webcorpus2_clean/
- Download helper script: [download_webcorpus.sh](download_webcorpus.sh)
- Format converter script: [convert_webcorpus.py](convert_webcorpus.py)
- Add additional analysis scripts: [reformat_emtsv.py](reformat_emtsv.py), [add_annotation.sh](add_annotation.sh), [content_check.sh](content_check.sh)
- Example config: [webcorpus](webcorpus)


Usage:

1. Put `webcorpus` file into [`corpora/registry`](../corpora/registry) folder
2. Run `download_webcorpus.sh` to download the corpus files (into `webcorpus_orig`) and check their integrity
3. Run `printf '%s\n' webcorpus_orig/2017_2018_{0001..3697}.tsv.gz webcorpus_orig/2019_{0001..0600}.tsv.gz webcorpus_orig/wiki_{0001..0168}.tsv.gz | xargs -I {} sh -c 'gzip -cd "$1" | python3 convert_webcorpus.py --filename "$1" --outdir webcorpus_ske | gzip -n > "webcorpus_ske/ske_$1"' _ {}`
   to convert the corpus into Sketch Engine format (into `webcorpus_ske`)
    - To add aditional rows use [add_annotation.sh](add_annotation.sh)
    - To check if the conversion was successful use [content_check.sh](content_check.sh)
4. Put the files in `webcorpus_ske` folder into [`corpora/webcorpus/vertical`](../corpora/webcorpus/vertical) folder
5. Run `make compile` to compile the corpus
