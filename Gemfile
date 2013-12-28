source "http://rubygems.org"
gemspec :name => 'qu'

Dir['qu-*.gemspec'].each do |gemspec|
  plugin = gemspec.scan(/qu-(.*)\.gemspec/).flatten.first
  gemspec(:name => "qu-#{plugin}", :development_group => plugin)
end

group :test do
  gem 'activesupport', :require => false
  gem 'SystemTimer',  :platform => :mri_18
  gem 'rake'
  gem 'rspec', '~> 2.0'
  gem 'guard-rspec'
  gem 'guard-bundler'
end
