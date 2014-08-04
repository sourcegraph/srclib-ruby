FROM ubuntu:14.04

RUN apt-get update -qq
RUN apt-get install -qq curl git

# Install Ruby
RUN curl -L https://get.rvm.io | bash -s stable
ENV PATH /usr/local/rvm/bin:$PATH
RUN rvm requirements
ENV RUBY_VERSION ruby-2.1
RUN rvm install $RUBY_VERSION
RUN rvm $RUBY_VERSION do gem install bundler --no-ri --no-rdoc

# Add this toolchain
ADD . /srclib/srclib-ruby/
WORKDIR /srclib/srclib-ruby
ENV PATH /srclib/srclib-ruby/.bin:$PATH

WORKDIR /src

ENTRYPOINT ["rvm", "all", "do", "srclib-ruby"]
