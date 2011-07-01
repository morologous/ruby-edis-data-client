require 'faraday'

#
# Friendly little GEM for interacting with the United States International
# Trade Commission's EDIS data REST services.
#
module EDIS
  class Client
    #
    # Construct a new instance. A block can be given to provide additional
    # configuration to Faraday.
    #
    #   edis = EDIS::Client.new { |b| b.response :logger }
    #
    def initialize
      @conn = Faraday.new(:url => 'https://edis.usitc.gov/data') do |builder|
        builder.request :url_encoded
        builder.adapter :net_http
        yield builder if block_given?
      end
    end

    #
    # Fetch a digest for api usage.  Users must be preregistered with
    # the edis app.
    #
    # Args:
    # username - Your EDIS registered username [REQUIRED]
    # password - Your EDIS registered password [REQUIRED]
    def gen_key(username, password)
      validate_creds username, password
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
    # :key                  - the authorization digest
    #
    def find_investigations(options = {})
      return if options.empty?
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
    # :key                  - the authorization digest
    #
    def find_documents(options = {})
      return if options.empty?
    end

    #
    # Fetch a documents attachments.
    #
    # Accepts a hash with the following keys:
    # :document_id - the document id [REQUIRED]
    # :key         - the authorization digest
    #
    def findAttachments
      return if options.empty?
    end

    #
    # Fetch a document.
    #
    # Accepts a hash with the following keys:
    # :document_id   - the document id [REQUIRED]
    # :attachment_id - the actual attachment id [REQUIRED]
    # :username      - The EDIS registered username [REQUIRED] 
    # :key           - The authorization key returned from gen_key [REQUIRED]
    #
    def downloadAttachment
    end
    
    ######################################################################################
    private
    
    def validate_creds(username, password)
    end
  end
end
