require 'base64'
require 'crack'
require 'net/https'
require 'cgi'

#
# Friendly little GEM for interacting with the United States International
# Trade Commission's EDIS data REST services.
#
module EDIS
  class Client
    #
    # Construct a new instance. If passed a block will yeild passing
    # a config hash for proxy settings with the following options:
    #
    # :proxy_uri
    # :proxy_user
    # :proxy_pass
    #
    # edis = EDIS::Client.new do |proxy|
    #   proxy[:uri]      => 'https://my.domain.com'
    #   proxy[:user]     => 'matz' 
    #   proxy[:password] => 'changeit'
    # end
    #
    def initialize()
      @proxy = {}
      yeild @proxy if block_given?
      @proxy[:uri] = URI.parse(@proxy[:uri]) if @proxy[:uri]
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
      results = post_resource "/secretKey/#{username}", { password: password }
      raise ArgumentError, results['error'] if results['error']
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
      valiate_investigation_options options
      path   = build_path '/investigation', options, investigation_paths
      params = build_params options, investigation_params
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
    #                           :type => :between, :before, :after or :exact
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
      path   = build_path '/document', options, [:document_id] 
      params = build_params(options, document_params).merge \
        build_date_params options, document_date_params
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
    # Fetch a document.  If a block is given, it will yeild passing 
    # fragments of the stream as they are ready on the block.
    # 
    # Accepts an hash for the following:
    # :document_id   - the document id [REQUIRED]
    # :attachment_id - the actual attachment id [REQUIRED]
    # :digest        - the authorization digest returned 
    #                  from gen_digest [REQUIRED]
    #
    def download_attachment(options = {})
      validate_presenceof [:document_id, :attachemnt_id, :digest], options
      {}
    end
    
    ######################################################################################
    private
    
    # document related
    document_params      = [:page, :firm_org, :document_type, :security_level, :investigation_phase, :investigation_number]
    document_date_params = [:official_received_date,  :modified_date]

    # investigation related
    investigation_paths  = [:investigation_number, :investigation_phase]
    investigation_params = [:page, :investigation_type, :investigation_status]
    
    # lock em down
    [document_params, document_date_params, investigation_paths, investigation_params].each do |obj|
      obj.freeze
    end
    
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
    # Validates that when :investigation_phase is 
    # specified so is :investigation_number
    #
    def validate_investigation_options(options)    
      if options[:investigation_phase]
        validate_presenceof [:investigation_number], options, 
          ":investigation_number is required when :investigation_phase is specified."
      end
    end
    
    #
    # Invokes the api at the given path.  Returns a hash rooted at the
    # rest API's results node.
    #
    def get_resource(path, options, params = {})
      connect.start do |http|
        header = {'Authorization' => options[:digest]} if options[:digest]
        path   = path_with_params(path, params) unless params.empty?
        resp   = http.get("/data/#{path}", header || {})
        Crack::XML.parse(resp.body)['results']
      end
    end 
    
    #
    # Post resource.
    # 
    def post_resource(path, params)
      connect.start do |http|
        req  = Net::HTTP::Post.new("/data/#{path}")
        req.set_form_data params
        resp = http.request(req)
        result = Crack::XML.parse(resp.body)
        result['errors'] ? result['errors'] : result['results']
      end
    end
    
    #
    # Add the query string to the path.
    #
    def path_with_params(path, params)
      "#{path}?".concat(
        params.collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.reverse.join('&')
      )
    end
    
    #
    # Get the correct net:http class based on config
    # TODO: support proxy
    #  
    def connect
      uri  = URI.parse('https://edis.usitc.gov/')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http
    end
    
    #
    # Proxy connections?
    #
    def proxy?
      !@proxy.empty?
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
    # Builds the params hash from the options.
    #
    def build_params(options, optional_params)
      optional_params.inject({}) do |params, param|
        params[camelize(param.to_s, false)] = options[param] if options[param]
      end      
    end
    
    #
    # Appends to the params date comparisions.
    #
    def build_date_params(params, options, optional_date_params)
      optional_date_params.inject({}) do |params, date_param|
        if options[date_param]
          comparison = options[date_param]
          case comparison[:type]
            when :between
              params[camelize(date_param)] =
                "#BETWEEN:#{date_param[:from_date]}:#{date_param[:to_date]}"
            when :before, :after, :exact
              params[camelize(date_param)] = 
                "#{comparison[:type].uppercase}:#{comparision[:date]}"
            else
              raise ArgumentError, 
                "Unknown comparison type #{comparison[:comparison_type]}"
          end
        end
      end
    end
     
    #
    # Camelize a string, lifted from Rails.  
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