require 'helper'

class TestEdisClient < Test::Unit::TestCase
  context "a edis client" do
    setup do
      @edis = EDIS::Client.new #{ |b| b.response :logger }
    end

    should "return a status of 500 for unregistered users trying to generate a digest" do
      assert_raise(ArgumentError) { @edis.gen_digest('!registered', 'password') }
    end
    
    should "return a digest when given valid credentials to generate a digest" do
      assert_equal 200, @edis.gen_digest(CREDS[:username], CREDS[:password]).status
    end
    # 
    # should "return an xml representiation of an attachment" do
    #   assert_equal 200, @edis.find_attachments({document_id: 453695}).status
    # end 
  end
end
