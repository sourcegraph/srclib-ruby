ifeq ($(OS),Windows_NT)
	BUNDLE = bundle.exe
	YARDOC = ../yard/bin/yardoc.bat
	RUBY_VERSION = ruby-2.2.2
else
	BUNDLE = bundle
	YARDOC = ../yard/bin/yardoc
endif

.PHONY: default test-dep test dep

default: dep stdlib

test-dep:
	cd testdata/case/ruby-sample-0 && $(BUNDLE) install
	cd testdata/case/ruby_sample_xref_app && $(BUNDLE) install
	cd testdata/case/sample_ruby_gem && $(BUNDLE) install
	cd testdata/case/rails-sample && $(BUNDLE) install

test:
	src -v test -m program

test-gen-program:
	src test -m program --gen

dep:
	$(BUNDLE) install
	cd yard && $(BUNDLE) install

RUBY_SOURCE_URL ?= http://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.2.tar.gz
RUBY_VERSION ?= ruby-2.1.2
stdlib: $(RUBY_VERSION) $(RUBY_VERSION)/.yardoc

$(RUBY_VERSION):
	[ -e $(RUBY_VERSION) ] || curl $(RUBY_SOURCE_URL) | tar -xz

$(RUBY_VERSION)/.yardoc:
	cp .yardopts_ruby $(RUBY_VERSION)/.yardopts && cd $(RUBY_VERSION) && $(YARDOC)
