require 'base64'
require 'crack'
require 'faraday'
require 'json'

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
      @conn = Faraday.new(url: 'https://edis.usitc.gov') do |builder|
        builder.request :url_encoded
        builder.adapter :net_http
        yield builder if block_given?
      end
    end

    #
    # Generates a digest for api usage.  Users must be preregistered with
    # the edis app.
    #
    # Args:
    # username - your EDIS registered username [REQUIRED]
    # password - your EDIS registered password [REQUIRED]
    #
    def gen_digest(username, password)
      resp = @conn.post "/data/secretKey/#{username}", { password: password }
      raise ArgumentError, "Invalid credentials." unless resp.status == 200
      results = Crack::XML.parse(resp.body)['results']
      Base64.encode64 "#{username}:#{results['secretKey']}"
    end

    #
    # Find investigations.
    #
    # Accepts an hash for the following options:
    # :investigation_number - the investigation number.
    # :investigation_phase  - the name of the investigation phase.
    #                         :investgation_number is required when
    #                         using this option
    # :investigation_type   - the name of the investigation type
    # :investigation_status - the name of the investigation status
    # :page                 - the page number for result pagination.
    # :digest               - the authorization digest returned from gen_digest
    #
    def find_investigations(options = {})
      []
    end

    #
    # Fetch document metadata.
    #
    # Accepts an hash for the following options:
    # :security_level         - the security level name.
    # :investigation_number   - the investigation number.
    # :investigation_phase    - the name of the investigation phase.
    #                           :investgation_number is required when
    #                           using this option
    # :document_type          - the document type
    # :official_received_date - the document's offical received date
    # :modified_date          - the docuemnt's last modified date
    # :firm_org               - the firm that filed the doc
    # :page                   - the page number for result pagination.
    # :digest                 - the authorization digest returned from gen_digest
    #
    def find_documents(options = {})
      []
    end

    #
    # Fetch a document's attachments.  Returns a hash rooted at the
    # rest API's results node.
    #
    # Accepts an hash for the following options:
    # :document_id - the document id [REQUIRED]
    # :digest      - The authorization digest returned from gen_digest
    #
    def find_attachments(options = {})
      validate_presenceof :document_id, options
      resp = @conn.get "/data/attachment/#{options[:document_id]}", header(options)
      Crack::XML.parse(resp.body)['results']
    end

    #
    # Fetch a document.
    #
    # Accepts an hash for the following:
    # :document_id   - the document id [REQUIRED]
    # :attachment_id - the actual attachment id [REQUIRED]
    # :username      - the EDIS registered username [REQUIRED] 
    # :digest        - the authorization digest returned from gen_digest [REQUIRED]
    #
    def download_attachment(options = {})
      validate_presenseof [:document_id, :attachemnt_id, :username, :digest], options
    end
    
    ######################################################################################
    private
    
    #
    # Validates the requires are present in the options.  Raises 
    # ArgumentError if not.
    #
    def validate_presenceof(*requires, options)
      requires.each do |required|
        unless options.key? required
          raise ArgumentError, "Missing one or more required options #{requires}" 
        end
      end
    end
    
    def header(options)
      options[:digest] ? { 'Authorization' => options[:digest] } : {}
    end    
  end
end
