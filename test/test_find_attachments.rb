class TestFindAttachmentsClient < Test::Unit::TestCase
  context "a edis client when asked to find an attachement" do
    setup do
      @edis = EDIS::Client.new
    end
  
    should "thorw ArgumentError when document_id is missing" do
      assert_raise(ArgumentError) { @edis.find_attachments({}) }
    end 
  
    should "return an xml representation of an attachment" do
      result = @edis.find_attachments({document_id: 453695})
      assert result.results
    end 
  
    should "return a hash with errors when an attachement can not be found" do
      result = @edis.find_attachments({document_id: 000000}) 
      assert result.errors
    end 

    should "return a hash representiation of an attachment" do
      result = @edis.find_attachments({document_id: 453695})
      assert result.results
    end 
  end
end
