#!/usr/bin/ruby
require File.dirname(__FILE__) + "/tests_helper"

class ActorTest < Test::Unit::TestCase
  def setup
    @config = Backup::Configuration.new
    @config.load "standard"
    @actor = @config.actor
    setup_tmp_backup_dir
  end

  def dont_test_exists
     assert @actor
  end

  def dont_test_is_file
    dir = create_tmp_files
    config = <<-END
      action :content, :is_file => "#{dir}/1"
    END
    @config.load :string => config
    assert result = @actor.content
    assert File.exists?(result)
    puts "content result is: #{result}"
    @actor.start_process! 
  end

  def dont_test_is_folder
    dir = create_tmp_files
    config = <<-END
      action :content, :is_folder => "#{dir}"
    END
    @config.load :string => config
    assert result = @actor.content
    assert File.exists?(result)
    assert File.directory?(result)
    puts "content result is: #{result}"
    @actor.start_process! 
  end

  def test_is_contents_of
    dir = create_tmp_files
    config = <<-END
      action :content, :is_contents_of => "#{dir}", :copy => true
    END
    @config.load :string => config
    #@actor.content
    #@actor.cleanup
    @actor.start_process! 
  end

  private
    def setup_tmp_backup_dir
      newtmp = @config[:tmp_dir] + "/backup_#{rand}_" + Time.now.strftime("%Y%m%d%H%M%S")
      sh "mkdir #{newtmp}"
      config = <<-END
        set :backup_path, "#{newtmp}" 
      END
      @config.load :string => config
    end

    def create_tmp_files
      newtmp = @config[:tmp_dir] + "/test_#{rand}_" + Time.now.strftime("%Y%m%d%H%M%S")
      sh "mkdir #{newtmp}"
      0.upto(5) { |i| sh "touch #{newtmp}/#{i}" }
      newtmp
    end

end

