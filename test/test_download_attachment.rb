require 'helper'

class TestDownloadAttachmentClient < Test::Unit::TestCase
  context "when an edis client is asked to download an attach it" do
    setup do
      @edis = EDIS::Client.new
    end

    should "not raise an error when all required fields are specified" do
      options = {
        :attachment_id => 12345,
        :document_id   => 12345,
        :digest        => 'digest'
      }
      assert_nothing_thrown { @edis.download_attachment(options){ } }
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

    should "not raise an error when a digest is set in the session" do
      @edis.gen_digest(CREDS[:username], CREDS[:password])
      options = {
        :attachment_id => 12345,
        :document_id   => 12345
      }
      assert_nothing_thrown { @edis.download_attachment(options){ } }
    end

    should "not raise an error when a digest is set in the session" do
      @edis.gen_digest(CREDS[:username], CREDS[:password])
      options = {
        :attachment_id => 642415,
        :document_id   => 453695
      }

      @edis.download_attachment(options) do |chunk|
        puts "#{chunk}"
      end
    end
  end
end
