require 'rubygems'
Gem::manage_gems
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = "backupgem"
  s.version = "0.0.5"
  s.author = "Nate Murray"
  s.email = "nate@natemurray.com"
  s.homepage = "http://tech.natemurray.com/backup"
  s.platform = Gem::Platform::RUBY
  s.summary = "Beginning-to-end solution for backups and rotation."
  s.files = FileList["{bin,lib,tests,examples,doc}/**/*"].to_a
  s.require_path = "lib"
  s.autorequire = "backupgem"
  s.test_files = FileList["{tests}/**/*test.rb"].to_a
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "CHANGELOG", "TODO"]
  s.add_dependency("rake", ">= 0.7.1")
  s.add_dependency("runt", ">= 0.3.0")
  s.add_dependency("net-ssh", ">= 1.0.9")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

desc "Create the rubygem"
task :gem => "pkg/#{spec.name}-#{spec.version}.gem" do
    puts "generated latest version"
end
