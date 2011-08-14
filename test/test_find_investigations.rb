require 'helper'

class TestFindInvestigationsClient < Test::Unit::TestCase
  context "when an edis client is asked to find investigations it" do
    setup do
      @edis = EDIS::Client.new
    end

    should "return a nil investigations list if investigation cannot be found" do
      result = @edis.find_investigations({investigation_number: '000000'})
      assert result.results.investigations.nil?
    end

    should "return a array of investigations" do
      result = @edis.find_investigations
      assert result.results.investigations
    end

    should "return an investigation when given an investigation id" do
      result = @edis.find_investigations({investigation_number: '103-007'})
      assert result.results.investigations
    end
  end
end
