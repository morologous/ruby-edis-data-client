require 'helper'

class TestGenDigestClient < Test::Unit::TestCase
  context "when an edis client is asked to geneate a digest it" do
    setup do
      FakeWeb.allow_net_connect = false
      @edis = EDIS::Client.new
    end

    teardown do
      FakeWeb.allow_net_connect = true
      FakeWeb.clean_registry
    end

    should "raise an ArugmentError for unregistered users" do
      assert_raise(ArgumentError) { @edis.gen_digest('!registered', 'password') }
    end

    should "return a digest when given valid credentials" do
      assert_not_nil @edis.gen_digest(CREDS[:username], CREDS[:password])
    end
  end
end
