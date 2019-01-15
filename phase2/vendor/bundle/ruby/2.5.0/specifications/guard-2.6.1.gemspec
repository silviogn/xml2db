# -*- encoding: utf-8 -*-
# stub: guard 2.6.1 ruby lib

Gem::Specification.new do |s|
  s.name = "guard".freeze
  s.version = "2.6.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Thibaud Guillaume-Gentil".freeze]
  s.date = "2014-05-07"
  s.description = "Guard is a command line tool to easily handle events on file system modifications.".freeze
  s.email = ["thibaud@thibaud.gg".freeze]
  s.executables = ["guard".freeze]
  s.files = ["bin/guard".freeze]
  s.homepage = "http://guardgem.org".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.0.2".freeze
  s.summary = "Guard keeps an eye on your file modifications".freeze

  s.installed_by_version = "3.0.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<thor>.freeze, [">= 0.18.1"])
      s.add_runtime_dependency(%q<listen>.freeze, ["~> 2.7"])
      s.add_runtime_dependency(%q<pry>.freeze, [">= 0.9.12"])
      s.add_runtime_dependency(%q<lumberjack>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<formatador>.freeze, [">= 0.2.4"])
    else
      s.add_dependency(%q<thor>.freeze, [">= 0.18.1"])
      s.add_dependency(%q<listen>.freeze, ["~> 2.7"])
      s.add_dependency(%q<pry>.freeze, [">= 0.9.12"])
      s.add_dependency(%q<lumberjack>.freeze, ["~> 1.0"])
      s.add_dependency(%q<formatador>.freeze, [">= 0.2.4"])
    end
  else
    s.add_dependency(%q<thor>.freeze, [">= 0.18.1"])
    s.add_dependency(%q<listen>.freeze, ["~> 2.7"])
    s.add_dependency(%q<pry>.freeze, [">= 0.9.12"])
    s.add_dependency(%q<lumberjack>.freeze, ["~> 1.0"])
    s.add_dependency(%q<formatador>.freeze, [">= 0.2.4"])
  end
end
