source "http://rubygems.org"
gemspec :name => 'qu'

Dir['qu-*.gemspec'].each do |gemspec|
  plugin = gemspec.scan(/qu-(.*)\.gemspec/).flatten.first

  group plugin do
    gemspec(:name => "qu-#{plugin}", :development_group => plugin)
  end
end

group :test do
  gem 'SystemTimer',  :platform => :mri_18
  gem 'ruby-debug',   :platform => :mri_18
  gem 'debugger',     :platform => :mri_19 #, :require => 'ruby-debug'
  gem 'rake'
  gem 'rspec', '~> 2.0'
  gem 'guard-rspec'
  gem 'guard-bundler'
end
