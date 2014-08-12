.PHONY: test-deps test

test-deps:
	cd testdata/case/ruby-sample-0 && rvm 2.1 do bundle install
	cd testdata/case/ruby_sample_xref_app && rvm 2.1 do bundle install
	cd testdata/case/sample_ruby_gem && rvm 2.1 do bundle install

test:
	rvm 2.1 do src -v test -m program
