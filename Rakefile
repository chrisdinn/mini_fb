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
  t.rcov_opts << "--text-report -x /.bundle/ -x /.gem/"  
  # t.verbose = true     # uncomment to see the executed command
end