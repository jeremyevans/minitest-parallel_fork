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
  sh %{#{FileUtils::RUBY} #{"-w" if RUBY_VERSION >= '3'} #{'-W:strict_unused_block' if RUBY_VERSION >= '3.4'} spec/minitest_parallel_fork_spec.rb}
end

task :default=>:spec

desc "Run specs with coverage"
task :spec_cov do
  ENV['COVERAGE'] = '1'
  ENV['RUBY'] = FileUtils::RUBY
  sh %{#{FileUtils::RUBY} spec/minitest_parallel_fork_spec.rb}
end

### RDoc

desc "Generate rdoc"
task :rdoc do
  rdoc_dir = "rdoc"
  rdoc_opts = ["--line-numbers", "--inline-source", '--title', 'minitest-parallel_fork: fork-based parallelization for minitest']

  begin
    gem 'hanna'
    rdoc_opts.concat(['-f', 'hanna'])
  rescue Gem::LoadError
  end

  rdoc_opts.concat(['--main', 'README.rdoc', "-o", rdoc_dir] +
    %w"README.rdoc CHANGELOG MIT-LICENSE" +
    Dir["lib/**/*.rb"]
  )

  FileUtils.rm_rf(rdoc_dir)

  require "rdoc"
  RDoc::RDoc.new.document(rdoc_opts)
end
