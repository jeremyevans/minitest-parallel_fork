spec = Gem::Specification.new do |s|
  s.name = 'minitest-parallel_fork'
  s.version = '1.0.3'
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "CHANGELOG", "MIT-LICENSE"]
  s.rdoc_options += ["--quiet", "--line-numbers", "--inline-source", '--title', 'minitest-parallel_fork: fork-based parallelization for minitest', '--main', 'README.rdoc']
  s.license = "MIT"
  s.summary = "Fork-based parallelization for minitest"
  s.author = "Jeremy Evans"
  s.email = "code@jeremyevans.net"
  s.homepage = "http://github.com/jeremyevans/minitest-parallel_fork"
  s.files = %w(MIT-LICENSE CHANGELOG README.rdoc Rakefile) + Dir["{spec,lib}/**/*.rb"]
  s.description = <<END
minitest-parallel_fork adds fork-based parallelization to Minitest.  Each test/spec
suite is run one of the forks, allowing this to work correctly when using
before_all/after_all/around_all hooks provided by minitest-hooks.  Using separate
processes via fork can significantly improve spec performance when using MRI,
and can work in cases where Minitest's default thread-based parallelism do not work,
such as when specs modify the constant namespace.
END

  s.add_development_dependency "minitest", '>5.11.0'
end
