# -*- encoding: utf-8 -*-
# stub: rgl 0.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rgl".freeze
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Horst Duchene".freeze]
  s.autorequire = "rgl/base".freeze
  s.date = "2008-08-27"
  s.description = "RGL is a framework for graph data structures and algorithms.  The design of the library is much influenced by the Boost Graph Library (BGL) which is written in C++ heavily using its template mechanism.  RGL currently contains a core set of algorithm patterns:  * Breadth First Search  * Depth First Search   The algorithm patterns by themselves do not compute any meaningful quantities over graphs, they are merely building blocks for constructing graph algorithms. The graph algorithms in RGL currently include:  * Topological Sort  * Connected Components  * Strongly Connected Components  * Transitive Closure * Transitive Reduction * Graph Condensation * Search cycles (contributed by Shawn Garbett)".freeze
  s.email = "monora@gmail.com".freeze
  s.extra_rdoc_files = ["README".freeze]
  s.files = ["README".freeze]
  s.homepage = "http://rgl.rubyforge.org".freeze
  s.rdoc_options = ["--title".freeze, "RGL - Ruby Graph Library".freeze, "--main".freeze, "README".freeze, "--line-numbers".freeze]
  s.requirements = ["Stream library, v0.5 or later".freeze]
  s.rubygems_version = "3.0.2".freeze
  s.summary = "Ruby Graph Library".freeze

  s.installed_by_version = "3.0.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 2

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<stream>.freeze, [">= 0.5"])
      s.add_runtime_dependency(%q<rake>.freeze, [">= 0"])
    else
      s.add_dependency(%q<stream>.freeze, [">= 0.5"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<stream>.freeze, [">= 0.5"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
