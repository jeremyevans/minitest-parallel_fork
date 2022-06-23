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
  sh %{#{FileUtils::RUBY} #{"-w" if RUBY_VERSION >= '3'} spec/minitest_parallel_fork_spec.rb}
end

task :default=>:spec

desc "Run specs with coverage"
task :spec_cov do
  ENV['COVERAGE'] = '1'
  ENV['RUBY'] = FileUtils::RUBY
  sh %{#{FileUtils::RUBY} spec/minitest_parallel_fork_spec.rb}
end

### RDoc

require "rdoc/task"

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.options += ["--quiet", "--line-numbers", "--inline-source", '--title', 'minitest-parallel_fork: fork-based parallelization for minitest', '--main', 'README.rdoc']

  begin
    gem 'hanna-nouveau'
    rdoc.options += ['-f', 'hanna']
  rescue Gem::LoadError
  end

  rdoc.rdoc_files.add %w"README.rdoc CHANGELOG MIT-LICENSE lib/**/*.rb"
end
