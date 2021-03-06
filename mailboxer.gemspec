Gem::Specification.new do |s|
  s.name = "mailboxer"
  s.version = "0.11.0.2"

  s.authors = ["Eduardo Casanova Cuesta"]
  s.summary = "Messaging system for rails apps."
  s.description = "A Rails engine that allows any model to act as messageable, adding the ability to exchange messages " +
                   "with any other messageable model, even different ones. It supports the use of conversations with " +
                   "two or more recipients to organize the messages. You have a complete use of a mailbox object for " +
                   "each messageable model that manages an inbox, sentbox and trash for conversations. It also supports " +
                   "sending motifications to messageable models, intended to be used as system motifications."
  s.email = "ecasanovac@gmail.com"
  s.homepage = "https://github.com/ging/mailboxer"
  s.files = `git ls-files`.split("\n")
  s.license = 'MIT'

  # Gem dependencies
  #
  # SQL foreign keys
  s.add_runtime_dependency('foreigner', '>= 0.9.1')

  # Development Gem dependencies
  s.add_runtime_dependency('rails', '>= 3.2.0')
  s.add_runtime_dependency('carrierwave', '>= 0.5.8')
  s.add_runtime_dependency('sunspot_rails', '>= 2.1.0')

  s.add_development_dependency('sunspot_solr', '>= 2.1.0')

  # Debugging
  if RUBY_VERSION < '1.9'
    s.add_development_dependency('ruby-debug', '>= 0.10.3')
  end

  if RUBY_ENGINE == "rbx" && RUBY_VERSION >= "2.1.0"
    # Rubinius has it's own dependencies
    s.add_runtime_dependency     'rubysl'
    s.add_development_dependency 'racc'
  end
  # Specs
  s.add_development_dependency('rspec-rails', '>= 2.6.1')
  s.add_development_dependency("appraisal")
  s.add_development_dependency('shoulda-matchers')
  # Fixtures
  #if RUBY_VERSION >= '1.9.2'
   # s.add_development_dependency('factory_girl', '>= 3.0.0')
  #else
    #s.add_development_dependency('factory_girl', '~> 2.6.0')
  #end
  s.add_development_dependency('factory_girl', '~> 2.6.0')
  # Population
  s.add_development_dependency('forgery', '>= 0.3.6')
  # Integration testing
  s.add_development_dependency('capybara', '>= 0.3.9')
  # Testing database
  if RUBY_PLATFORM == 'java'
    s.add_development_dependency('jdbc-sqlite3')
    s.add_development_dependency('activerecord-jdbcsqlite3-adapter', '1.3.0.rc1')
  else
    s.add_development_dependency('sqlite3')
  end
end
