TARGETS := $(shell ls -1 *.md | sed -e 's/md/html/')

all: $(TARGETS)

%.html : %.md;
	jq --slurp --raw-input '{"text": "\(.)", "mode": "markdown"}' < $< | curl  --data @- https://api.github.com/markdown > $@
