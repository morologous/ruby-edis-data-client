require 'helper'

class TestDownloadAttachmentValidationClient < Test::Unit::TestCase
  context "when an edis client is asked to download an attachment it" do
    setup do
      FakeWeb.allow_net_connect = false
      @edis = EDIS::Client.new
    end

    teardown do
      FakeWeb.allow_net_connect = true
      FakeWeb.clean_registry
    end

    should "raise an ArugmentError if a block is missing" do
      assert_raise(ArgumentError) { @edis.download_attachment() }
    end

    should "raise an ArugmentError when :document_id is not specified" do
      assert_raise(ArgumentError) {
        options = {
          :attachment_id => 12345,
          :digest        => 'digest'
        }
        @edis.download_attachment(options) { }
      }
    end

    should "raise an ArugmentError when :attachment_id is not specified" do
      assert_raise(ArgumentError) {
        options = {
          :document_id => 12345,
          :digest      => 'digest'
        }
        @edis.download_attachment(options) { }
      }
    end

    should "raise an ArugmentError when :digest isn't set" do
      assert_raise(ArgumentError) {
        options = {
          :attachment_id => 12345,
          :document_id   => 12345
        }
        @edis.download_attachment(options) { }
      }
    end

  end
end
