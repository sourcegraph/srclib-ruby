#export RUBY_SRC=~/.rvm/src/"$RUBY_VERSION"
#export RUBY_SRC=/tmp/sg/github.com/ruby/ruby
SLOWTESTS=false rspec -c -f d spec/handlers/local_variable_handler_spec.rb spec/handlers/reference_handler_spec.rb spec/type_inference
