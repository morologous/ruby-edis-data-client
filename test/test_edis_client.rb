require 'helper'

class TestEdisClient < Test::Unit::TestCase
  context "a edis client" do
    setup do
      @edis = EDIS::Client.new { |b| b.response :logger }
    end

    should "return a status of 404 for unregistered users trying to generate a key" do
      assert_equal 404, @edis.gen_key('!registered', 'password').status
    end
    
    should "return a digest when given valid credentials to generate a key" do
      assert_equal 200, @edis.gen_key(CREDS[:username], CREDS[:password]).status
    end
  end
end
