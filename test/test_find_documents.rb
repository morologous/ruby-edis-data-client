require 'helper'

class TestFindDocumentsClient < Test::Unit::TestCase
  context "when an edis client is asked to find documents it" do
    setup do
      @edis = EDIS::Client.new
    end

    should "return a nil documents list if document cannot be found" do
      result = @edis.find_documents({document_id: 000000})
      assert result.results.documents.nil?
    end 

    should "return a array of documents" do
      result = @edis.find_documents
      assert result.results.documents
    end 

    should "return a document when given a document id" do
      result = @edis.find_documents({document_id: 453695})
      assert result.results.documents
    end 
  end  
end
