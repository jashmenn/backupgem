#!/usr/bin/ruby
require File.dirname(__FILE__) + "/tests_helper"

class RotationTest < Test::Unit::TestCase
  def setup
    # settings
    @promote_son_on    = 14 # fridays
    @promote_father_on =  4 # every fourth friday
    @keep_grandfather  =  6
    @promote_on        = :fri

    # derived
    @promote_father_mod = @promote_son_on * @promote_father_on
    @promote_on_offset = Time.num_from_day(@promote_on)

    # setup our config to test the objects
    @config = Backup::Configuration.new
    @config.load "standard"
    @rotator = Backup::Rotator.new(@config.actor) 
  end

  def test_rotation_days
    one_day = (60 * 60 * 24)
    t = Time.now
    0.upto(7) do 
      mod = (t.days_since_epoch + @promote_on_offset - 6) % @promote_son_on 
      mod_offset = mod #- @promote_on_offset + 6 
      puts t.strftime("%a: #{mod_offset}")  
      #puts t.num_from_day(t.strftime("%a").downcase.gsub(/:/, "").intern)
      t += one_day
    end
    puts @promote_on_offset
  end

  def test_rotator
    puts @rotator.promote_son_today?
  end

  # this all needs to be tested. modify the cde o make tesitng better. set it
  # up so that you can use the time ovject that is being tested. have it so
  # that it comparse the day name with the day that things are supposed to be
  # in the settings.

end
