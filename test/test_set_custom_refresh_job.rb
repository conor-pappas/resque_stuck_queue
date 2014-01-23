require File.join(File.expand_path(File.dirname(__FILE__)), "test_helper")

class TestYourOwnRefreshJob < Minitest::Test

  include TestHelper

  def setup
    Resque::StuckQueue.config[:trigger_timeout] = 1
    Resque::StuckQueue.config[:heartbeat] = 1
    Resque::StuckQueue.config[:abort_on_exception] = true
    Resque::StuckQueue.config[:refresh_job] = nil
    Resque::StuckQueue.redis = Redis.new
    Resque::StuckQueue.redis.flushall
  end

  def teardown
    Resque::StuckQueue.reset!
    Resque::StuckQueue.config.clear
  end

  def test_will_trigger_with_unrefreshing_custom_heartbeat_job 
    # it will trigger because the key will be unrefreshed, hence 'old' and will always trigger.
    puts "#{__method__}"
    Resque::StuckQueue.config[:refresh_job] = proc { nil } # does not refresh global key
    @triggered = false
    Resque::StuckQueue.config[:handler] = proc { @triggered = true }
    start_and_stop_loops_after(3)
    assert @triggered, "will trigger because global key will be old"
  end

  def test_will_fail_with_bad_custom_heartbeat_job
    puts "#{__method__}"
    begin
      Resque::StuckQueue.config[:refresh_job] = proc { raise 'bad proc doc' } # does not refresh global key
      @triggered = false
      Resque::StuckQueue.config[:handler] = proc { @triggered = true }
      start_and_stop_loops_after(3)
      assert false, "should not succeed with bad refresh_job"
    rescue
      assert true, "will fail with bad refresh_job"
    end
  end

end
