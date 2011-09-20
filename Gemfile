source "http://rubygems.org"
gemspec :name => 'qu'

group :mongo do
  gemspec :name => 'qu-mongo', :development_group => :mongo
  gem 'bson_ext'
end

group :redis do
  gemspec :name => 'qu-redis', :development_group => :redis
end

group :test do
  gem 'SystemTimer', :platform => :mri_18
  gem 'ruby-debug',  :platform => :mri_18
  gem 'rake'
  gem 'rspec', '~> 2.0'
  gem 'guard-rspec'
  gem 'guard-bundler'
end