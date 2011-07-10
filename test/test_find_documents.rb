class TestFindDocumentsClient < Test::Unit::TestCase
  context "a edis client when asked to find documents" do
    setup do
      @edis = EDIS::Client.new
    end

    should "return a hash with a nil documents list if document cannot be found" do
      result = @edis.find_documents({document_id: 000000})
      assert result.results.documents.nil?
    end 

    should "return a hash representation of a documents" do
      result = @edis.find_documents
      assert result.results.documents
    end 

    should "return a hash representation of a document when given a document id" do
      result = @edis.find_documents({document_id: 453695})
      assert result.results.documents
    end 
  end  
end
