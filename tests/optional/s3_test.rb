require File.dirname(__FILE__) + "/tests_helper"

class S3Test < Test::Unit::TestCase

  # These tests require actual S3 access keys set as environment variables

  def setup
    @config = Backup::Configuration.new
    @config.load "standard"
    @config.set :backup_path, 'test_backup'
    @config.action :deliver, :method => :s3 
    @actor = Backup::S3Actor.new(@config) 
  end

  def test_exists
    assert @config
    assert @actor
  end

  def test_on_s3
    dir = create_tmp_files
    config = <<-END
      action :content, :is_folder => "#{dir}"
      action :rotate,  :method  => :via_s3
    END
    @config.load :string => config
    assert result = @config.actor.content
    assert File.exists?(result)
    @config.actor.start_process!
  end
  
  private
  
    def create_tmp_files
      newtmp = @config[:tmp_dir] + "/test_#{rand}_" + Time.now.strftime("%Y%m%d%H%M%S")
      sh "mkdir #{newtmp}"
      0.upto(5) { |i| sh "touch #{newtmp}/#{i}" }
      newtmp
    end
end
