.PHONY: default test-dep test dep

default: dep stdlib

test-dep:
	cd testdata/case/ruby-sample-0 && rvm 2.1 do bundle install
	cd testdata/case/ruby_sample_xref_app && rvm 2.1 do bundle install
	cd testdata/case/sample_ruby_gem && rvm 2.1 do bundle install

test:
	rvm 2.1 do src -v test -m program

dep:
	bundle install
	cd yard && bundle install

RUBY_VERSION ?= 2.1.2
RUBY_SRC=$(shell dirname `which rvm`)/../src/ruby-$(RUBY_VERSION)
stdlib:
	rvm fetch $(RUBY_VERSION)
	rvm $(RUBY_VERSION) do yard/bin/yard doc -n -c .yardoc $(RUBY_SRC)/*.c $(RUBY_SRC)/lib/**/*.rb
