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
      assert_not_nil @edis.gen_digest(CREDS[:username], CREDS[:password])
    end
    
    should "thorw ArgumentError when document_id is missing" do
      assert_raise(ArgumentError) { @edis.find_attachments({}) }
    end 

    should "return an xml representiation of an attachment" do
      assert_not_nil @edis.find_attachments({document_id: 453695})
    end 
  end
end
