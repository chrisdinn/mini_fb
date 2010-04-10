# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mini_fb}
  s.version = "0.2.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Travis Reeder", "Aaron Hurley", "Chris Dinn"]
  s.date = %q{2010-04-10}
  s.description = %q{Tiny facebook library}
  s.email = %q{travis@appoxy.com}
  s.extra_rdoc_files = [
    "README.markdown"
  ]
  s.files = Dir.glob("lib/*") + ["README.markdown"]
  s.homepage = %q{http://github.com/chrisdinn/mini_fb}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Tiny facebook library}
  s.test_files = [
    "test/facebooksecret_test.rb",
    "test/mini_fb_test.rb", 
    "test/photos_test.rb", 
    "test/session_test.rb", 
    "test/user_test.rb", 
    "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-client>, [">= 0"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
    else
      s.add_dependency(%q<rest-client>, [">= 0"])
      s.add_dependency(%q<json>, [">= 0"])
    end
  else
    s.add_dependency(%q<rest-client>, [">= 0"])
    s.add_dependency(%q<json>, [">= 0"])
  end
end

