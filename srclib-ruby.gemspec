Gem::Specification.new do |spec|
  spec.authors = ["Quinn Slack"]
  spec.description = %q{Ruby toolchain for srclib}
  spec.email = ['sqs@sourcegraph.com']
  spec.files += Dir.glob("{.bin,lib,spec}/**/*.rb")
  spec.homepage = 'https://sourcegraph.com/sourcegraph/srclib-ruby'
  spec.licenses = ['BSD']
  spec.name = 'srclib-ruby'
  spec.require_paths = ['lib']
  spec.bindir = '.bin'
  spec.executables = ['srclib-ruby']
  spec.required_ruby_version = '>= 1.9.2'
  spec.required_rubygems_version = '>= 1.3.5'
  spec.summary = "Analyze and scan Ruby source code for stdlib"
  spec.version = '0.0.1'
end
