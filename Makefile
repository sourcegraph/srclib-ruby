ifeq ($(OS),Windows_NT)
	BUNDLE = bundle.exe
	YARDOC = ../yard/bin/yardoc.bat
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
	srclib -v test -m program

test-gen-program:
	srclib test -m program --gen

dep:
	$(BUNDLE) install
	cd yard && $(BUNDLE) install

RUBY_VERSION ?= ruby-2.2.2
RUBY_SOURCE_URL ?= http://cache.ruby-lang.org/pub/ruby/2.2/$(RUBY_VERSION).tar.gz
stdlib: $(RUBY_VERSION) $(RUBY_VERSION)/.yardoc

$(RUBY_VERSION):
	[ -e $(RUBY_VERSION) ] || curl $(RUBY_SOURCE_URL) | tar -xz

$(RUBY_VERSION)/.yardoc:
	cp $(CURDIR)/.yardopts_ruby $(CURDIR)/$(RUBY_VERSION)/.yardopts && cd $(CURDIR)/$(RUBY_VERSION) && $(YARDOC)
