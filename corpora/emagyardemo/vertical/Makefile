
FILE=input

all: analyse postprocess

analyse:
	cat $(FILE).txt | docker run --rm -i mtaril/emtsv tok,morph,pos,conv-morph,dep,chunk,ner > $(FILE).tsv

postprocess:
	(echo '<doc file="A01" n="1">\n<s>' ; tail -n +2 $(FILE).tsv | sed "s/^$$/<\/s>\n<s>/"; echo '</s>\n</doc>') > source 

