require 'helper'

class TestEdisClient < Test::Unit::TestCase
  context "a edis client" do
    setup do
      @edis = EDIS::Client.new
    end

    should "raise an ArugmentError for unregistered users trying to generate a digest" do
      assert_raise(ArgumentError) { @edis.gen_digest('!registered', 'password') }
    end
    
    should "return a digest when given valid credentials to generate a digest" do
      assert_not_nil @edis.gen_digest(CREDS[:username], CREDS[:password])
    end
    
    should "thorw ArgumentError when document_id is missing" do
      assert_raise(ArgumentError) { @edis.find_attachments({}) }
    end 
    
    should "return an xml representation of an attachment" do
      assert_not_nil @edis.find_attachments({document_id: 453695})
    end 
    
    should "return a hash with errors when an attachement can not be found" do
      assert @edis.find_attachments({document_id: 000000}).key? "errors"
    end 

    should "return a hash representiation of an attachment" do
      assert_not_nil @edis.find_attachments({document_id: 453695})
    end 
    
    should "return a hash with errors when a document can not be found" do
      assert @edis.find_documents({document_id: 000000}).key? "errors"
    end 
  end
end
