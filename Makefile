.PHONY: default test-dep test dep

default: dep stdlib

test-dep:
	cd testdata/case/ruby-sample-0 && bundle install
	cd testdata/case/ruby_sample_xref_app && bundle install
	cd testdata/case/sample_ruby_gem && bundle install

test:
	src -v test -m program

test-gen-program:
	src test -m program --gen

dep:
	bundle install
	cd yard && bundle install

RUBY_SOURCE_URL ?= http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.2.tar.gz
RUBY_VERSION ?= ruby-2.1.2
stdlib: $(RUBY_VERSION) $(RUBY_VERSION)/.yardoc

$(RUBY_VERSION):
	[ -e $(RUBY_VERSION) ] || curl $(RUBY_SOURCE_URL) | tar -xz

$(RUBY_VERSION)/.yardoc:
	yard/bin/yard doc -n -c $(RUBY_VERSION)/.yardoc $(RUBY_VERSION)/*.c $(RUBY_VERSION)'/lib/**/*.rb'
