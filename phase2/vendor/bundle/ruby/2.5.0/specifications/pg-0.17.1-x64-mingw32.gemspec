# -*- encoding: utf-8 -*-
# stub: pg 0.17.1 x64-mingw32 lib

Gem::Specification.new do |s|
  s.name = "pg".freeze
  s.version = "0.17.1"
  s.platform = "x64-mingw32".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze, "Lars Kanis".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDaDCCAlCgAwIBAgIBATANBgkqhkiG9w0BAQUFADA9MQ4wDAYDVQQDDAVrYW5p\nczEXMBUGCgmSJomT8ixkARkWB2NvbWNhcmQxEjAQBgoJkiaJk/IsZAEZFgJkZTAe\nFw0xMzAyMjYwODQ1NTlaFw0xNDAyMjYwODQ1NTlaMD0xDjAMBgNVBAMMBWthbmlz\nMRcwFQYKCZImiZPyLGQBGRYHY29tY2FyZDESMBAGCgmSJomT8ixkARkWAmRlMIIB\nIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApop+rNmg35bzRugZ21VMGqI6\nHGzPLO4VHYncWn/xmgPU/ZMcZdfj6MzIaZJ/czXyt4eHpBk1r8QOV3gBXnRXEjVW\n9xi+EdVOkTV2/AVFKThcbTAQGiF/bT1n2M+B1GTybRzMg6hyhOJeGPqIhLfJEpxn\nlJi4+ENAVT4MpqHEAGB8yFoPC0GqiOHQsdHxQV3P3c2OZqG+yJey74QtwA2tLcLn\nQ53c63+VLGsOjODl1yPn/2ejyq8qWu6ahfTxiIlSar2UbwtaQGBDFdb2CXgEufXT\nL7oaPxlmj+Q2oLOfOnInd2Oxop59HoJCQPsg8f921J43NCQGA8VHK6paxIRDLQID\nAQABo3MwcTAJBgNVHRMEAjAAMAsGA1UdDwQEAwIEsDAdBgNVHQ4EFgQUvgTdT7fe\nx17ugO3IOsjEJwW7KP4wGwYDVR0RBBQwEoEQa2FuaXNAY29tY2FyZC5kZTAbBgNV\nHRIEFDASgRBrYW5pc0Bjb21jYXJkLmRlMA0GCSqGSIb3DQEBBQUAA4IBAQCa3ThZ\n9qjyuFXe0kN4IwgHTTSqob3zPOyXAxAq1k65w1/hI/6e4HxCSH7Ds+dKj/xhScEu\nK5gaya1D69Fo+JTnzLvuSt2X8+mEHclduC9j++oSGc+szd7LKdeEQ7J4RefJjhD+\nvWI6lqglL4PijN0nOWtm0ygzXEELDcGYpb2WJ++KKNVLIU6pkiWpZUmGcFB7NclV\nI64m9iNdgWnDwedgUlqSMfVCUUB9S1Y5jI+doxYloPvIB6+6VsI4cmN2LcK0rQO6\nN3pmmsS0N5772vAmRMyNl8PV1OzCLIMhgPgdeLpfU7LUSYWj67q5VuyjAaH5h68g\nMlGgwc//cCsBG8sa\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2013-12-19"
  s.description = "Pg is the Ruby interface to the {PostgreSQL RDBMS}[http://www.postgresql.org/].\n\nIt works with {PostgreSQL 8.4 and later}[http://www.postgresql.org/support/versioning/].\n\nA small example usage:\n\n  #!/usr/bin/env ruby\n\n  require 'pg'\n\n  # Output a table of current connections to the DB\n  conn = PG.connect( dbname: 'sales' )\n  conn.exec( \"SELECT * FROM pg_stat_activity\" ) do |result|\n    puts \"     PID | User             | Query\"\n  result.each do |row|\n      puts \" %7d | %-16s | %s \" %\n        row.values_at('procpid', 'usename', 'current_query')\n    end\n  end".freeze
  s.email = ["ged@FaerieMUD.org".freeze, "lars@greiz-reinsdorf.de".freeze]
  s.extra_rdoc_files = ["Contributors.rdoc".freeze, "History.rdoc".freeze, "Manifest.txt".freeze, "README-OS_X.rdoc".freeze, "README-Windows.rdoc".freeze, "README.ja.rdoc".freeze, "README.rdoc".freeze, "ext/errorcodes.txt".freeze, "POSTGRES".freeze, "LICENSE".freeze, "ext/gvl_wrappers.c".freeze, "ext/pg.c".freeze, "ext/pg_connection.c".freeze, "ext/pg_errors.c".freeze, "ext/pg_result.c".freeze]
  s.files = ["Contributors.rdoc".freeze, "History.rdoc".freeze, "LICENSE".freeze, "Manifest.txt".freeze, "POSTGRES".freeze, "README-OS_X.rdoc".freeze, "README-Windows.rdoc".freeze, "README.ja.rdoc".freeze, "README.rdoc".freeze, "ext/errorcodes.txt".freeze, "ext/gvl_wrappers.c".freeze, "ext/pg.c".freeze, "ext/pg_connection.c".freeze, "ext/pg_errors.c".freeze, "ext/pg_result.c".freeze]
  s.homepage = "https://bitbucket.org/ged/ruby-pg".freeze
  s.licenses = ["BSD".freeze, "Ruby".freeze, "GPL".freeze]
  s.rdoc_options = ["-f".freeze, "fivefish".freeze, "-t".freeze, "pg: The Ruby Interface to PostgreSQL".freeze, "-m".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7".freeze)
  s.rubygems_version = "3.0.2".freeze
  s.summary = "Pg is the Ruby interface to the {PostgreSQL RDBMS}[http://www.postgresql.org/]".freeze

  s.installed_by_version = "3.0.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rdoc>.freeze, ["~> 4.0"])
      s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 0.9"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.5.1"])
      s.add_development_dependency(%q<hoe-deveiate>.freeze, ["~> 0.2"])
      s.add_development_dependency(%q<hoe-bundler>.freeze, ["~> 1.0"])
    else
      s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
      s.add_dependency(%q<rake-compiler>.freeze, ["~> 0.9"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.5.1"])
      s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.2"])
      s.add_dependency(%q<hoe-bundler>.freeze, ["~> 1.0"])
    end
  else
    s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
    s.add_dependency(%q<rake-compiler>.freeze, ["~> 0.9"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.5.1"])
    s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.2"])
    s.add_dependency(%q<hoe-bundler>.freeze, ["~> 1.0"])
  end
end
