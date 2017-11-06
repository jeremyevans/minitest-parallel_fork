require "rake"
require "rake/clean"

CLEAN.include ["minitest-parallel_fork-*.gem", "rdoc", "coverage"]

desc "Build minitest-parallel_fork gem"
task :package=>[:clean] do |p|
  sh %{#{FileUtils::RUBY} -S gem build minitest-parallel_fork.gemspec}
end

### Specs

desc "Run specs"
task :spec do
  ENV['RUBY'] = FileUtils::RUBY
  sh %{#{FileUtils::RUBY} spec/minitest_parallel_fork_spec.rb}
end

task :default=>:spec

### RDoc

RDOC_DEFAULT_OPTS = ["--quiet", "--line-numbers", "--inline-source", '--title', 'minitest-parallel_fork: fork-based parallelization for minitest']

begin
  gem 'hanna-nouveau'
  RDOC_DEFAULT_OPTS.concat(['-f', 'hanna'])
rescue Gem::LoadError
end

rdoc_task_class = begin
  require "rdoc/task"
  RDoc::Task
rescue LoadError
  require "rake/rdoctask"
  Rake::RDocTask
end

RDOC_OPTS = RDOC_DEFAULT_OPTS + ['--main', 'README.rdoc']

rdoc_task_class.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.options += RDOC_OPTS
  rdoc.rdoc_files.add %w"README.rdoc CHANGELOG MIT-LICENSE lib/**/*.rb"
end

