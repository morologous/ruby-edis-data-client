require "helper"
require 'tempfile'
require 'digest/md5'

class TestDownloadAttachmentClient < Test::Unit::TestCase

  context "when an edis client is asked to download an attachment it" do
    # Called before every test method runs. Can be used
    # to set up fixture information.
    setup do
      @edis = EDIS::Client.new
      @tmp_file = Tempfile.new ['TestDownloadAttachmentClient', '.pdf']
    end

    teardown do
      @tmp_file.delete
    end

    should "it should download an attachment as expected" do
      expected_md5_digest_b64 = '1B2M2Y8AsgTpgAmY7PhCfg=='
      @edis.gen_digest(CREDS[:username], CREDS[:password])
      options = {
        attachment_id: 218944,
        document_id: 237197
      }
      @edis.download_attachment(options){ |chuck| @tmp_file.write chuck }

      assert_equal expected_md5_digest_b64, Digest::MD5.file(File.absolute_path @tmp_file.path).base64digest
    end

  end

end