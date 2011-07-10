class TestGenDigestClient < Test::Unit::TestCase
  context "a edis client when asked to geneate a digest" do
    setup do
      @edis = EDIS::Client.new
    end
    
    should "raise an ArugmentError for unregistered users" do
      assert_raise(ArgumentError) { @edis.gen_digest('!registered', 'password') }
    end
    
    should "return a digest when given valid credentials" do
      assert_not_nil @edis.gen_digest(CREDS[:username], CREDS[:password])
    end

    should "raise an ArugmentError for unregistered users" do
      assert_raise(ArgumentError) { @edis.gen_digest('!registered', 'password') }
    end    

    should "return a digest when given valid credentials" do
      assert_not_nil @edis.gen_digest(CREDS[:username], CREDS[:password])
    end
  end
end
