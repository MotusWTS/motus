TARGETS := $(shell ls -1 *.md | sed -e 's/md/html/')

all: $(TARGETS)

# subject to github.com's rate limitations (one request per minute), the .md files can
# be converted to .html like so:

%.html : %.md;
	jq --slurp --raw-input '{"text": "\(.)", "mode": "markdown"}' < $< | curl  --data @- https://api.github.com/markdown > $@
