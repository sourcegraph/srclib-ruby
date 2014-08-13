# srclib-ruby [![Build Status](https://travis-ci.org/sourcegraph/srclib-ruby.png?branch=master)](https://travis-ci.org/sourcegraph/srclib-ruby)

## YARD

srclib-ruby uses [Loren Segal's](http://gnuu.org/)
[YARD](https://github.com/lsegal/yard) for Ruby analysis. A git subtree of the
[Sourcegraph](https://sourcegraph.com) fork of YARD is in the `yard/`
subdirectory. Commits to that subtree should be regularly sent upstream to the
[github.com/sourcegraph/yard](https://github.com/sourcegraph/yard) fork.

## Running tests

**Always** run the tests wrapped in the rvm you want to use. If you're trying to
match the expected output checked into the repository, use:

```
make test-deps
rvm 2.1 do src test
```

Same goes for when you're generating new expected output (just add `--gen`).

## TODO

* Check whether Ruby stdlib works
* Check whether xrefs work
* Add Travis-CI test for `src test` test cases and YARD specs
