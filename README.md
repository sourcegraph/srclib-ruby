# srclib-ruby [![Build Status](https://travis-ci.org/sourcegraph/srclib-ruby.png?branch=master)](https://travis-ci.org/sourcegraph/srclib-ruby)

## YARD

srclib-ruby uses [Loren Segal's](http://gnuu.org/)
[YARD](https://github.com/lsegal/yard) for Ruby analysis. A git subtree of the
[Sourcegraph](https://sourcegraph.com) fork of YARD is in the `yard/`
subdirectory. Commits to that subtree should be regularly sent upstream to the
[github.com/sourcegraph/yard](https://github.com/sourcegraph/yard) fork.

## Running tests

The `make test` target analyzes sample repositories in `testdata/case` and
checks that the actual output matches the expected output (which is committed to
the repository).

The sample repositories are git submodules, so you'll have to `git submodule
init && git submodule update` the first time you want to run the tests.

The output of the analyzer differs a bit depending on the version of Ruby you
have installed. The expected output was generated using Ruby 2.1.2. If you're
finding that your output differs from the expected, try **both** generating the
stdlib index and running the tests with that version of Ruby. If you're using
[rvm](https://rvm.io), this means running the following commands:

```
# in case you built the stdlib index using a different version of Ruby (e.g.,
# your system Ruby)
rm -rf ruby-2.1.2/.yardoc

# rebuild the stdlib index using Ruby 2.1.2 (run `rvm install 2.1.2` if you
# haven't already installed Ruby 2.1.2)
rvm 2.1.2 do make stdlib

# install gem deps for the test repos using Ruby 2.1.2
rvm 2.1.2 do make test-dep

# run the tests with Ruby 2.1.2
rvm 2.1.2 do make test
```

The same applies when you're generating new expected test output (after making
an improvement to the code, for example).

If you're having trouble getting your output to match the expected, post an
issue.

## TODO

* Check whether Ruby stdlib works
* Check whether xrefs work
* Add Travis-CI test for `src test` test cases and YARD specs
