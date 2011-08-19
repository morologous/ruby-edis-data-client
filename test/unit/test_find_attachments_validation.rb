require 'helper'

class TestFindAttachmentsValidationClient < Test::Unit::TestCase
  context "when an edis client is asked to find an attachement it" do
    setup do
      FakeWeb.allow_net_connect = false
      @edis = EDIS::Client.new
    end

    teardown do
      FakeWeb.allow_net_connect = true
      FakeWeb.clean_registry
    end

    should "throw ArgumentError when document_id is missing" do
      assert_raise(ArgumentError) { @edis.find_attachments({}) }
    end
  end
end