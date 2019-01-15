# -*- encoding: utf-8 -*-
# stub: listen 2.7.9 ruby lib

Gem::Specification.new do |s|
  s.name = "listen".freeze
  s.version = "2.7.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Thibaud Guillaume-Gentil".freeze]
  s.date = "2014-06-20"
  s.description = "The Listen gem listens to file modifications and notifies you about the changes. Works everywhere!".freeze
  s.email = "thibaud@thibaud.gg".freeze
  s.executables = ["listen".freeze]
  s.files = ["bin/listen".freeze]
  s.homepage = "https://github.com/guard/listen".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.0.2".freeze
  s.summary = "Listen to file modifications".freeze

  s.installed_by_version = "3.0.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<celluloid>.freeze, [">= 0.15.2"])
      s.add_runtime_dependency(%q<rb-fsevent>.freeze, [">= 0.9.3"])
      s.add_runtime_dependency(%q<rb-inotify>.freeze, [">= 0.9"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 1.3.5"])
      s.add_development_dependency(%q<celluloid-io>.freeze, [">= 0.15.0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0.0rc1"])
      s.add_development_dependency(%q<rspec-retry>.freeze, [">= 0"])
    else
      s.add_dependency(%q<celluloid>.freeze, [">= 0.15.2"])
      s.add_dependency(%q<rb-fsevent>.freeze, [">= 0.9.3"])
      s.add_dependency(%q<rb-inotify>.freeze, [">= 0.9"])
      s.add_dependency(%q<bundler>.freeze, [">= 1.3.5"])
      s.add_dependency(%q<celluloid-io>.freeze, [">= 0.15.0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0.0rc1"])
      s.add_dependency(%q<rspec-retry>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<celluloid>.freeze, [">= 0.15.2"])
    s.add_dependency(%q<rb-fsevent>.freeze, [">= 0.9.3"])
    s.add_dependency(%q<rb-inotify>.freeze, [">= 0.9"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.3.5"])
    s.add_dependency(%q<celluloid-io>.freeze, [">= 0.15.0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0.0rc1"])
    s.add_dependency(%q<rspec-retry>.freeze, [">= 0"])
  end
end
