begin
    require 'jeweler'
    Jeweler::Tasks.new do |gemspec|
        gemspec.name = "mini_fb"
        gemspec.summary = "Tiny facebook library"
        gemspec.description = "Tiny facebook library"
        gemspec.email = "travis@appoxy.com"
        gemspec.homepage = "http://github.com/appoxy/mini_fb"
        gemspec.authors = ["Travis Reeder", "Aaron Hurley"]
        gemspec.files = FileList['lib/**/*.rb']
        gemspec.add_dependency 'rest-client'
    end
rescue LoadError
    puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake/testtask'
Rake::TestTask.new('test') do |t|
    t.libs << 'test'
	  t.pattern = 'test/*_test.rb'
	  t.verbose = true
	  t.warning = false
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
  t.ruby_opts << "-Ilib:test"
  t.rcov_opts << "--text-report -x /.bundle/"  
  # t.verbose = true     # uncomment to see the executed command
end