require 'rubygems'
Gem::manage_gems
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'
require 'rake/testtask'

spec = Gem::Specification.new do |s|
  s.name = 'backupgem'
  s.version = '0.0.11'
  s.license = 'MIT'
  s.author = "Nate Murray"
  s.email = "nate@natemurray.com"
  s.homepage = "http://tech.natemurray.com/backup"
  s.platform = Gem::Platform::RUBY
  s.summary = "Beginning-to-end solution for backups and rotation."
  s.files = FileList["{bin,lib,tests,examples,doc}/**/*"].to_a
  s.require_path = "lib"
  s.autorequire = "backupgem"
  s.test_files = FileList["{tests}/**/*test.rb"].to_a
  s.bindir = "bin" # Use these for applications.
  s.executables = ['backup']
  s.default_executable = "backup"
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "CHANGELOG", "TODO", "Rakefile"]
  s.rubyforge_project = "backupgem"
  s.add_dependency("rake", ">= 0.7.1")
  s.add_dependency("runt", ">= 0.3.0")
  s.add_dependency("net-ssh", ">= 1.0.9")
  s.add_dependency("madeleine", ">= 0.7.3")
end
GEMSPEC = spec

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

desc "Create the rubygem"
task :gem => "pkg/#{spec.name}-#{spec.version}.gem" do
    puts "generated latest version"
end

desc "Run the unit tests in test/unit"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = 'tests/*_test.rb'
  t.verbose = true
end

desc "Reinstall the gem from a local package copy"
task :reinstall => [:package] do
  `sudo gem uninstall -x #{spec.name}`
  `sudo gem install pkg/#{spec.name}-#{spec.version}`
end

# rm -f pkg/backupgem-0.0.8.gem ; rake gem; sudo gem install --local pkg/backupgem-0.0.8.gem

desc "Publish the release files to RubyForge."
task :release => [ :gem ] do
  `rubyforge login`
  release_command = "rubyforge add_release #{GEMSPEC.name} #{GEMSPEC.name} 'REL #{GEMSPEC.version}' pkg/#{GEMSPEC.name}-#{GEMSPEC.version}.gem"
  puts release_command
  system(release_command)
end
