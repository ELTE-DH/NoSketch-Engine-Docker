# Analyse `txt` by e-magyar and convert to NoSkE input

`source` is a NoSkE input file created from `input.txt` by
running `e-magyar` analysis and some postprocessing on it.

Run
```bash
make
```
to recreate `source` from `input.txt`.
Intermediate file after analysis is `input.tsv`.

## Use this with _your_ corpus

1. Put your corpus here as `CORPUS.txt`.
2. Run `make FILE=CORPUS`.
3. Then head to the __Usage__ part of the main `README.md`.
4. And use you your brand new corpus.

