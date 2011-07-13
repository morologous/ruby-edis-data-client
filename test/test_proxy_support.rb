require "helper"
require "net/http"

class TestProxySupportClient < Test::Unit::TestCase
  context "when passing EDIS::Client.new a block with proxy configuration" do
    def setup
      @expected_host = 'my.domain.com'
      @expected_port = 124
      @expected_user = 'matz'
      @expected_password = 'changeit'

      config = {
        proxy: {
          uri: "https://#@expected_host:#@expected_port",
          user: @expected_user,
          password: @expected_password        
        }
      }

      @client = EDIS::Client.new config
    end

    should "return a proxy http class from net_http_class" do
      # shady way to access a private method
      def @client.public_net_http_class
        net_http_class
      end

      result = @client.public_net_http_class
      assert_equal @expected_host, result.proxy_address
      assert_equal @expected_port, result.proxy_port
      assert_equal @expected_user, result.proxy_user
      assert_equal @expected_password, result.proxy_pass
    end
  end
end