source 'https://rubygems.org'

# use bundle and bundle config to specify local gem locations
# bundle config local.GEM_NAME /path/to/local/git/repository

username = `whoami`.strip

#noinspection GemInspection
case username

  when 'moody'

    gem 'briar', :github => 'jmoody/briar', :branch => '1.0.1'
    gem 'calabash-cucumber', :github => 'jmoody/calabash-ios', :branch => 'master'
    gem 'xamarin-test-cloud', :git => 'git@github.com:jmoody/test-cloud-command-line.git', :branch => 'master'

  when 'your username here'

  else
    gem 'briar', '1.0.0'
end

gem 'pry'
