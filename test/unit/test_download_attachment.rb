require 'helper'

class TestDownloadAttachmentClient < Test::Unit::TestCase
  context "when an edis client is asked to download an attachment it" do
    setup do
      FakeWeb.allow_net_connect = false
      @edis = EDIS::Client.new
    end

    teardown do
      FakeWeb.allow_net_connect = true
      FakeWeb.clean_registry
    end

    should "should return attachment data when digest retailed by client instance" do
      username = 'username'
      secret_key = 'some_key'
      doc_id = 12345
      attachment_id = 654321
      expected_body = 'this is the PDF'
      FakeWeb.register_uri :post, "https://edis.usitc.gov/data/secretKey/#{username}", :body => "<results><secretKey>#{secret_key}</secretKey></results>"
      FakeWeb.register_uri :get, "https://#{username}:#{secret_key}@edis.usitc.gov/data/download/#{doc_id}/#{attachment_id}", :body => expected_body

      @edis.gen_digest(username, 'mypassword')
      options = {
        :attachment_id => attachment_id,
        :document_id   => doc_id
      }
      actual_body = ""
      @edis.download_attachment(options) do |chunk|
        actual_body << chunk
      end
      assert_equal expected_body, actual_body
    end

    should "should return attachment data when digest passed as option" do
      doc_id = 123456
      attachment_id = 654321
      expected_body = 'this is the PDF'
      auth_digest = 'foo:boo'

      FakeWeb.register_uri :get, "https://#{auth_digest}@edis.usitc.gov/data/download/#{doc_id}/#{attachment_id}", :body => expected_body

      options = {
        attachment_id: attachment_id,
        document_id: doc_id,
        digest: Base64.strict_encode64(auth_digest)
      }

      actual_body = ""
      @edis.download_attachment(options) do |chunk|
        actual_body << chunk
      end
      assert_equal expected_body, actual_body
    end

  end
end