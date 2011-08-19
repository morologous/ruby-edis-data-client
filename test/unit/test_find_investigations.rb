require 'helper'

class TestFindInvestigationsClient < Test::Unit::TestCase
  context "when an edis client is asked to find investigations it" do
    setup do
      FakeWeb.allow_net_connect = false
      @edis = EDIS::Client.new
    end

    teardown do
      FakeWeb.allow_net_connect = true
      FakeWeb.clean_registry
    end

    should "return a array of investigations" do
      # the expected_response is truncated -- but the client doesn't care
      expected_response = "<results><investigations>"\
        "<investigation><investigationNumber>A</investigationNumber><investigationPhase>Final-A</investigationPhase></investigation>"\
        "<investigation><investigationNumber>B</investigationNumber><investigationPhase>Final-B</investigationPhase></investigation>"\
        "</investigations></results>"
      FakeWeb.register_uri(:get, "https://edis.usitc.gov/data/investigation", :body => expected_response)

      result = @edis.find_investigations

      assert_equal 2, result.results.investigations.investigation.size
      #when more than one investigation is returned ... each investigation is a hash
      assert_equal "A", result.results.investigations.investigation[0]['investigationNumber']
      assert_equal "Final-B", result.results.investigations.investigation[1]['investigationPhase']
    end

    should "return a nil investigations list if investigation cannot be found" do
      inv_num = '000000'
      FakeWeb.register_uri(:get, "https://edis.usitc.gov/data/investigation/#{inv_num}", :body => '<results><investigations/></results>')

      result = @edis.find_investigations({investigation_number: inv_num})

      assert result.results.investigations.nil?
    end

    should "return an investigation when given an investigation id" do
      inv_num = '103-007'
      # the expected_response is truncated -- but the client doesn't care
      expected_response = "<results><investigations><investigation>"\
        "<investigationNumber>#{inv_num}</investigationNumber>"\
        "</investigation></investigations></results>"
      FakeWeb.register_uri(:get, "https://edis.usitc.gov/data/investigation/#{inv_num}", :body => expected_response)

      result = @edis.find_investigations({investigation_number: inv_num})

      assert_equal inv_num, result.results.investigations.investigation.investigationNumber
    end

    should "raise an exception when investigation_phase is specified but not investigation_number" do
      assert_raise(ArgumentError) do
        @edis.find_investigations investigation_phase: "foo"
      end
    end

  end
end
