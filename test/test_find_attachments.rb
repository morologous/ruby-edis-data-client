require 'helper'

class TestFindAttachmentsClient < Test::Unit::TestCase
  context "when an edis client is asked to find an attachement it" do
    setup do
      @edis = EDIS::Client.new
    end
  
    should "thorw ArgumentError when document_id is missing" do
      assert_raise(ArgumentError) { @edis.find_attachments({}) }
    end 
  
    should "return errors when an attachement can not be found" do
      result = @edis.find_attachments({document_id: 000000}) 
      assert result.errors
    end 

    should "return an attachment" do
      result = @edis.find_attachments({document_id: 453695})
      assert result.results
    end   
  end
end
