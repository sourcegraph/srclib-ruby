require 'json'
require 'optparse'
require 'rubygems'
require 'net/https'
require 'uri'

module Srclib
  class DepResolve
    def self.summary
      "analyze Ruby code for defs and refs"
    end

    def option_parser
      OptionParser.new do |opts|
        opts.banner = "Usage: depresolve [options] < unit.json"
      end
    end

    def run(args)
      if Gem.win_platform?
      	opt_args = []
      	args.map do |arg|
      		opt_args << arg.sub(/^\//, '--')
      	end
      	args = opt_args
      end
      option_parser.order!(args)
      # raise "no args may be specified to depresolve (got #{args.inspect}); it only depresolves the current directory and accepts a JSON repr of a source unit via stdin" if args.length != 0

      srcunit = JSON.parse(STDIN.read)

      resolutions = (srcunit["Dependencies"] || []).map do |raw_dep|
        gem_name, req = raw_dep[0], raw_dep[1]
        res = {'Raw' => raw_dep}
        begin
          #gemspec = resolve_gem(gem_name, req)
          res['Target'] = {
            'ToUnit' => gem_name,
            'ToUnitType' => 'rubygem',
            'ToVersionString' => req,
            'ToRepoCloneURL' => self.class.get_gem_clone_url(gem_name),
          }
        rescue Exception => ex
          res['Error'] = ex.inspect
        end
        res
      end

      puts JSON.pretty_generate(resolutions)
    end

    def initialize
      @opt = {}
    end

    private

    # unused because it's slow and doesn't get us the source_code_uri
    def resolve_gem(gem_name, req)
      fetcher = Gem::SpecFetcher.fetcher
      gemdep = Gem::Dependency.new(gem_name, req)
      specs, errors = fetcher.spec_for_dependency(gemdep)
      if specs.length > 0
        specs[0][0]
      elsif errors.length > 0
        raise errors.inspect
      else
        raise "no errors or spec found for #{gem_name} #{req}"
      end
    end

    public

    def self.get_gem_clone_url(gem_name)
      if GEM_CLONE_URLS[gem_name]
        GEM_CLONE_URLS[gem_name]
      else
        uri = URI("https://rubygems.org/api/v1/gems/#{gem_name}.json")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Get.new(uri.request_uri)
        resp = http.request(req)
        info = JSON.parse(resp.body)
        info['source_code_uri'] or info['homepage_uri'] or raise "could not get gem clone URL for #{gem_name}"
      end
    end

  end
end

GEM_CLONE_URLS = {
	"ruby" =>  "https://github.com/ruby/ruby",

	"rails" =>          "https://github.com/rails/rails",
	"actionmailer" =>   "https://github.com/rails/rails",
	"actionpack" =>     "https://github.com/rails/rails",
	"actionview" =>     "https://github.com/rails/rails",
	"activerecord" =>   "https://github.com/rails/rails",
	"activemodel" =>    "https://github.com/rails/rails",
	"railties" =>       "https://github.com/rails/rails",
	"activesupport" =>  "https://github.com/rails/rails",

	"elasticsearch" =>             "https://github.com/elasticsearch/elasticsearch-ruby",
	"elasticsearch-api" =>         "https://github.com/elasticsearch/elasticsearch-ruby",
	"elasticsearch-extensions" =>  "https://github.com/elasticsearch/elasticsearch-ruby",
	"elasticsearch-transport" =>   "https://github.com/elasticsearch/elasticsearch-ruby",

	"sass" =>                       "https://github.com/nex3/sass",
	"json" =>                       "https://github.com/flori/json",
	"treetop" =>                    "https://github.com/nathansobo/treetop",
	"barkick" =>                    "https://github.com/ankane/barkick",
	"groupdate" =>                  "https://github.com/ankane/groupdate",
	"pretender" =>                  "https://github.com/ankane/pretender",
	"searchkick" =>                 "https://github.com/ankane/searchkick",
	"chartkick" =>                  "https://github.com/ankane/chartkick",
	"redis" =>                      "https://github.com/redis/redis-rb",
	"geocoder" =>                   "https://github.com/alexreisner/geocoder",
	"yajl" =>                       "https://github.com/brianmario/yajl-ruby",
	"plu" =>                        "https://github.com/ankane/plu",
	"active_median" =>              "https://github.com/ankane/active_median",
	"delayed_job" =>                "https://github.com/collectiveidea/delayed_job",
	"delayed_job_active_record" =>  "https://github.com/collectiveidea/delayed_job_active_record",
	"tire-contrib" =>               "https://github.com/karmi/tire-contrib",
}
