require 'base64'
require 'crack'
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
      if options[:investigation_phase]
        msg = ":investigation_number is required when :investigation_phase is specified."
        validate_presenceof [:investigation_number], options, msg
      end
      
      path = build_path '/investigation', options, [
        :investigation_number, :investigation_phase
      ]
            
      params = build_params options, [
        :page, :investigation_type, :investigation_status  
      ]
      
      get_resource path, params, options
    end

    #
    # Fetch document metadata.
    #
    # Accepts an hash for the following options:
    # :document_id            - the document id.
    # :security_level         - the security level name.
    # :investigation_number   - the investigation number.
    # :investigation_phase    - the name of the investigation phase.
    # :document_type          - the document type
    # :official_received_date - the document's official received date comparision.
    #                           this should be a hash of the following keys:
    #                           :comparision_type => :between, :before, :after or :exact
    #                             when the type is :exact, :before, :after then
    #                               the hash must also contain :date
    #                             for :between the hash must contain the 2 following
    #                               keys :from_date, :to_date
    # :modified_date          - the docuemnt's last modified date comparision.
    #                           this should be a hash of the following keys:
    #                           :comparision_type => :between, :before, :after or :exact
    #                             when the type is :exact, :before, :after then
    #                               the hash must also contain :date
    #                             for :between the hash must contain the 2 following
    #                               keys :from_date, :to_date
    # :firm_org               - the firm that filed the doc
    # :page                   - the page number for result pagination.
    # :digest                 - the authorization digest returned from gen_digest
    #
    def find_documents(options = {})
      path = build_path '/document', options, [:document_id] 
      params = build_params options, [
        :page, :firm_org, :document_type, :security_level, :investigation_phase, :investigation_number
      ]
      
      append_date_params params, options, [
        :official_received_date,  :modified_date
      ]
      get_resource path, params, options
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
      validate_presenceof [:document_id], options
      get_resource "/attachment/#{options[:document_id]}", options
    end

    #
    # Fetch a document.
    # 
    # Accepts an hash for the following:
    # :document_id   - the document id [REQUIRED]
    # :attachment_id - the actual attachment id [REQUIRED]
    # :digest        - the authorization digest returned from gen_digest [REQUIRED]
    #
    def download_attachment(options = {})
      validate_presenceof [:document_id, :attachemnt_id, :digest], options
      {}
    end
    
    ######################################################################################
    private
    
    #
    # Validates the requires are present in the options.  Raises 
    # ArgumentError if not.
    #
    def validate_presenceof(requires, options, msg = nil)
      requires.each do |required|
        unless options[required]
          raise ArgumentError, msg || "Missing one or more required options #{requires}"
        end
      end
    end
    
    #
    # Invokes the api at the given path.  Returns a hash rooted at the
    # rest API's results node.
    #
    def get_resource(path, options, params = {})
      resp = @conn.get do |req|
        req.url "/data/#{path}"
        req.headers['Authorization'] = options[:digest] if options[:digest]
        req.params = params if params
      end
      Crack::XML.parse(resp.body)['results']
    end    

    #
    # Builds a path with optional resources paths if specified.
    #
    def build_path(root, options, optional_resources)
      optional_resources.inject(root) do |path, resource|
        path << "/#{options[resource]}" if options[resource]
      end
    end
    
    #
    # Builds the params hash from the q
    #
    def build_params(options, optional_params)
      optional_params.inject({}) do |params, param|
        params[camelize(param.to_s, false)] = options[param] if options[param]
      end      
    end
    
    #
    # Appends to the params date comparisions.
    #
    def append_date_params(params, options, *optional_date_params)
      optional_date_params.each do |date_param|
        if options[date_param]
          comparison = options[date_param]
          case comparison[:comparison_type]
            when :between
              params[camelize(date_param)] =
                "#BETWEEN:#{date_param[:from_date]}:#{date_param[:to_date]}"
            when :before, :after, :exact
              params[camelize(date_param)] = 
                "#{comparison[:comparison_type].uppercase}:#{comparision[:date]}"
            else
              raise ArgumentError, 
                "Unknown comparison type #{comparison[:comparison_type]}"
          end
        end
      end
    end
     
    #
    # Camelize a symbol, lifted from Rails.  
    # TODO: monkey patch String or Symbol with this
    #
    def camelize(s, first_letter_in_uppercase = true)
      if first_letter_in_uppercase
        s.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
      else
        s.to_s[0].chr.downcase + camelize(s)[1..-1]
      end
    end    
  end
end