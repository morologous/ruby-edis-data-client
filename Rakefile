# encoding: utf-8
require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "edis_client"
  gem.homepage = "https://github.com/morologous/ruby-edis-data-client"
  gem.license = "Apache"
  gem.summary = %Q{Ruby client to the EDIS Data Webservice, a service provided by the United States International Trade Commission.}
  gem.description = "Provides easy access to the USITC's EDIS data web service (contains international trade investigation data) via an object spewing ruby class - no fuss no muss and definately no XML! This gem is not officially supported by the USITC. This gem is pretty experimental and should see modifications in the near future."
  gem.authors = ['Sean McDaniel', 'Carlos Fernandez'] #mostly sean
  gem.files = 'lib/edis_client.rb'
  gem.version = '0.0.3'
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

require 'rake/testtask'
Rake::TestTask.new(:test_unit) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/unit/**/*_test.rb'
  test.verbose = true
end

require 'rake/testtask'
Rake::TestTask.new(:test_integration) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/integration/**/*_test.rb'
  test.verbose = true
end

desc "Run RSpec with code coverage"
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task[:test].execute
end

task :default => :test

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "edis_client #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
