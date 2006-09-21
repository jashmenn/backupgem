require File.dirname(__FILE__) + "/tests_helper"

class SSHTest < Test::Unit::TestCase
  def setup
    @config = Backup::Configuration.new
    @config.load "standard"
    @config.action :deliver, :method => :via_ssh 
    @actor = Backup::SshActor.new(@config) 
  end

  def test_exists
    assert @config
    assert @actor
  end

  def test_on_remote
    @actor.on_remote do
      run "echo \"hello $HOSTNAME\""
    end
  end
end
