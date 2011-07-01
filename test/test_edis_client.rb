require 'helper'

class TestEdisClient < Test::Unit::TestCase
  context "a edis client" do
    setup do
      @edis = EDIS::Client.new
    end
    
    should "return a status of 404 for unregistered users" do
      assert_equal 404, @edis.gen_key('unregistered', 'password').status
    end
  end
end
