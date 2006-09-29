#!/usr/bin/ruby
require File.dirname(__FILE__) + "/tests_helper"
require 'runt'
require 'date'

class RotationTest < Test::Unit::TestCase
  def setup
    # setup our config to test the objects
    @config = Backup::Configuration.new
    @config.load "standard"
    @rotator = Backup::Rotator.new(@config.actor) 
  end

  def test_rotator
    t = Date.today
    r = @rotator
    0.upto(14) do |i|
      $test_time = t
      print t.to_s + t.strftime(" #{i} %a ").to_s 
      puts r.todays_generation 
      t += 1
    end
  end

  def test_date_parsing
    dp = Backup::DateParser.new
    assert fri   = dp.date_from(:fri)
    assert daily = dp.date_from(:daily)
    assert last  = dp.date_from(:last_mon_of_the_month)
    assert_raise(RuntimeError) { dp.date_from(:asdfasdf) }
  end
end
