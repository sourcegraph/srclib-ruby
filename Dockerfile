FROM ubuntu:14.04

RUN apt-get update -qq
RUN apt-get install -qq curl git

# Install Ruby
RUN curl -L https://get.rvm.io | bash -s stable
ENV PATH /usr/local/rvm/bin:$PATH
RUN rvm requirements
ENV RUBY_VERSION ruby-2.1
RUN rvm install $RUBY_VERSION
RUN rvm fetch $RUBY_VERSION
RUN rvm $RUBY_VERSION do gem install asciidoctor rdoc bundler --no-ri --no-rdoc

ENV IN_DOCKER_CONTAINER true

# Pre-install YARD's gems for faster builds
RUN rvm $RUBY_VERSION do gem install RedCloth -v 4.2.9 --no-rdoc --no-ri && \
    rvm $RUBY_VERSION do gem install diff-lcs -v 1.1.3 --no-rdoc --no-ri && \
    rvm $RUBY_VERSION do gem install locale -v 2.0.9 --no-rdoc --no-ri && \
    rvm $RUBY_VERSION do gem install text -v 1.2.3 --no-rdoc --no-ri && \
    rvm $RUBY_VERSION do gem install gettext -v 3.0.2 --no-rdoc --no-ri && \
    rvm $RUBY_VERSION do gem install mob_spawner -v 1.0.0 --no-rdoc --no-ri && \
    rvm $RUBY_VERSION do gem install multi_json -v 1.8.2 --no-rdoc --no-ri && \
    rvm $RUBY_VERSION do gem install rack -v 1.5.2 --no-rdoc --no-ri && \
    rvm $RUBY_VERSION do gem install redcarpet -v 1.17.2 --no-rdoc --no-ri && \
    rvm $RUBY_VERSION do gem install rspec-core -v 2.12.2 --no-rdoc --no-ri && \
    rvm $RUBY_VERSION do gem install rspec-expectations -v 2.12.1 --no-rdoc --no-ri && \
    rvm $RUBY_VERSION do gem install rspec-mocks -v 2.12.2 --no-rdoc --no-ri && \
    rvm $RUBY_VERSION do gem install rspec -v 2.12.0 --no-rdoc --no-ri && \
    rvm $RUBY_VERSION do gem install rvm-tester -v 1.1.0 --no-rdoc --no-ri && \
    rvm $RUBY_VERSION do gem install simplecov-html -v 0.7.1 --no-rdoc --no-ri && \
    rvm $RUBY_VERSION do gem install simplecov -v 0.7.1 --no-rdoc --no-ri

# Add this toolchain
ADD . /srclib/srclib-ruby/
WORKDIR /srclib/srclib-ruby
ENV PATH /srclib/srclib-ruby/.bin:$PATH

# Set up YARD
WORKDIR /srclib/srclib-ruby/yard
RUN rvm all do bundle
ENV RUBY_STDLIB_YARDOC_DIR /tmp/ruby-stdlib-yardoc-dir

# Add srclib (unprivileged) user
RUN useradd -ms /bin/bash srclib
RUN mkdir /src
RUN chown -R srclib /src /srclib /usr/local/rvm
USER srclib

# Generate YARD doc for the stdlib
RUN cd /usr/local/rvm/src/$RUBY_VERSION.* && rvm all do /srclib/srclib-ruby/yard/bin/yard doc -n -c .yardoc *.c **/*.rb

WORKDIR /src

ENTRYPOINT ["rvm", "all", "do", "srclib-ruby"]
