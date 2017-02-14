default: help

help:
	@echo 'all - doc data'
	@echo 'doc - Generate the docs'
	@echo 'data - Generate data/ files from test/ files'
	@echo 'help - Show help'

all: doc data

.PHONY: doc
doc: ReadMe.pod

ReadMe.pod: doc/yaml-test-suite.swim
	swim --to=pod --complete --wrap < $< > $@

link-update:
	rm -fr test/name/ test/tags/
	perl bin/generate-links

#------------------------------------------------------------------------------
data:
	git clone $$(git config remote.origin.url) -b data $@

data-update: data
	perl bin/generate-data

data-status:
	@(cd data; git add -Af .; git status --short)

data-diff:
	@(cd data; git add -Af .; git diff --cached)

data-push:
	@[ -z "$$(cd data; git status --short)" ] || { \
	    cd data; \
	    git add -Af .; \
	    git commit -m 'Regenerated data files'; \
	    git push --force origin data; \
	}

#------------------------------------------------------------------------------
.PHONY: matrix
matrix: gh-pages data
	mkdir -p matrix
	for f in `YAML_EDITOR=$$PWD/../yaml-editor ./bin/run-framework-tests -l`; \
	    do bash -c "printf '%.0s-' {1..80}; echo"; \
	    YAML_EDITOR=$$PWD/../yaml-editor time ./bin/run-framework-tests $$f; done
	./bin/create-matrix
	rm -fr gh-pages/*.html gh-pages/css/
	cp -r $@/html/*.html $@/html/css/ gh-pages/

perl5-%:
	YAML_EDITOR=$$PWD/../yaml-editor ./bin/run-framework-tests $@
	./bin/create-matrix
	rm -fr gh-pages/*.html gh-pages/css/
	cp -r matrix/html/*.html matrix/html/css/ gh-pages/

gh-pages:
	git clone $$(git config remote.origin.url) -b $@ $@

matrix-push:
	@[ -z "$$(cd gh-pages; git status --short)" ] || { \
	    cd gh-pages; \
	    git add -Af .; \
	    git commit -m 'Regenerated matrix files'; \
	    git push --force origin gh-pages; \
	}

#------------------------------------------------------------------------------
clean:
	rm -fr data matrix
	git clean -dxf

.PHONY: test
test:
	@echo "We don't run tests here."