require 'faraday'

#
# Friendly little API for interacting with the United States International 
# Trade Commission's EDIS data REST services.
#
module EDIS
  class Client
    #
    # Construct a new instance. A block can be given to provide additional
    # configuration to Faraday.
    #
    def initialize
      @conn = Faraday.new(:url => 'https://edis.usitc.gov/data') do |builder|
        builder.request :url_encoded
        builder.adapter :net_http
        yield builder if block_given?
      end
    end
    
    #
    # Fetch a digest for api usage.
    #
    # Required args:
    # username
    #
    def gen_key(username, password)
      @conn.post "/#{username}", { :password => password }
    end
  
    #
    # Find investigations. 
    #
    # Accepts an options hash of the following keys:
    # :investigation_number - the investigation number.
    # :investigation_phase  - the name of the investigation phase.
    #                         :investgation_number is required when 
    #                         using this option
    # :investigation_type   - the name of the investigation type
    # :investigation_status - the name of the investigation status
    #
    def find_investigations(options = {})
    end
  
    #
    # Fetch documents
    #
    # Accepts a hash with the following keys:
    # :security_level       - the security level name.
    # :investigation_number - the investigation number.
    # :investigation_phase  - the name of the investigation phase.
    #                         :investgation_number is required when 
    #                         using this option
    # :document_type        - the document type
    # :firm_org             - the firm that filed the doc
    #
    def find_documents(options = {})
    end
  
    def findAttachments
    end
  
    def downloadAttachment
    end
  end
end