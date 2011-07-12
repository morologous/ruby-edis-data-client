require 'base64'
require 'cgi'
require 'crack/xml'
require 'net/https'
require 'recursive_open_struct'

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
    # edis = EDIS::Client.new({
    #   :uri      => 'https://my.domain.com',
    #   :user     => 'matz',
    #   :password => 'changeit'
    # })
    #
    def initialize(proxy = nil)
      @env = {}
      unless proxy.nil?
        @env[:proxy] = proxy
        @env[:proxy][:uri] = URI.parse(@env[:proxy][:uri])
      end
    end

    #
    # Generates a digest for api usage.  Users must be preregistered with
    # the edis app.  The digest can be retained (default) for the life of this
    # instance (session), ensuring all subseqent api calls pass the digest to
    # the endpoint.  In this mode clients need not worry about retaining
    # and passing this to other api calls.
    #
    # Args:
    # username - your EDIS registered username [REQUIRED]
    # password - your EDIS registered password [REQUIRED]
    #
    def gen_digest(username, password, retain = true)
      results = post_resource "/secretKey/#{username}", { password: password }
      raise ArgumentError, results.errors if results.errors
      secret_key = results.results.secretKey
      digest = Base64.encode64 "#{username}:#{secret_key}"
      @env[:digest] = digest if retain
      digest
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
      get_resource path, options, params
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
      validate_presence_of [:document_id], options
      get_resource "/attachment/#{options[:document_id]}", options
    end

    #
    # Fetch a document.  The result is streamed and therefore
    # clients must provide a block to read each chunk of the
    # response.
    # 
    # Accepts an hash for the following:
    # :document_id   - the document id [REQUIRED]
    # :attachment_id - the actual attachment id [REQUIRED]
    # :digest        - the authorization digest returned 
    #                  from gen_digest [REQUIRED]
    #
    def download_attachment(options = {})
      raise ArgumentError, "Missing block." unless block_given?
      validate_download options
      path = build_path '/download', options, download_paths
      puts "#{path}"
      stream_resource(path, options) { |chunk| yield chunk }
    end

    ######################################################################################
    private

    # document related
    def document_params
      [:page, :firm_org, :document_type, :security_level, :investigation_phase, :investigation_number]
    end
    def document_date_params
      [:official_received_date,  :modified_date]
    end

    # investigation related
    def investigation_paths
      [:investigation_number, :investigation_phase]
    end
    def investigation_params
      [:page, :investigation_type, :investigation_status]
    end

    # download released
    def download_paths
      [:document_id, :attachment_id]
    end

    #
    # Validates the requires are present in the options.  Raises
    # ArgumentError if not.
    #
    def validate_presence_of(requires, options, msg = nil)
      requires.each do |required|
        unless options[required]
          raise ArgumentError, msg || "Missing one or more required options #{requires}"
        end
      end
    end

   #
   # Validate that is digest is available and the required fields are present
   #
   def validate_download(options)
     validate_digest options 
     validate_presence_of [:document_id, :attachment_id], options
   end

    #
    # Validate either the digest is specified or that it is set in the env.
    #
    def validate_digest(options)
      unless options[:digest] || @env[:digest]
        raise ArgumentError, "A digest is required.  Please use gen_digest."
      end
    end

    #
    # Validates that when :investigation_phase is
    # specified so is :investigation_number
    #
    def validate_investigation_options(options)
      if options[:investigation_phase]
        validate_presence_of [:investigation_number], options,
          ":investigation_number is required when :investigation_phase is specified."
      end
    end

    #
    # Get the resource at the given path.
    #
    def get_resource(path, options, params = {})
      connect.start do |http|
        path = path_with_params(path, params) unless params.empty?
        xml  = http.get("/data/#{path}", header(options) || {}).body
        RecursiveOpenStruct.new Crack::XML.parse(xml)
      end
    end

    #
    # Get the resource at the given path streaming the result, in chunks, to
    # the block.
    #
    def stream_resource(path, options)
      connect.start do |http|
        http.get("/data/#{path}", header(options) || {}) do |chunk|
          yield chunk
        end
      end
    end

    #
    # Post resource.
    #
    def post_resource(path, params)
      connect.start do |http|
        req = Net::HTTP::Post.new("/data/#{path}") and req.set_form_data params
        xml = http.request(req).body
        RecursiveOpenStruct.new Crack::XML.parse(xml)
      end
    end

    #
    # Generate a query string reprsentation of the params and append to the path.
    #
    def path_with_params(path, params)
      "#{path}?".concat \
        params.collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.reverse.join('&')
    end

    #
    # Get the correct net:http class based on config
    #
    def connect
      uri  = URI.parse('https://edis.usitc.gov/')
      http = net_http_class.new(uri.host, uri.port)
      http.use_ssl = true and http
    end

    #
    # Creates the authorization header if the digest is present in the
    # options or if it was specified as being retained when gen_disgest
    # was called.
    #
    def header(options)
      digest = if options[:digest]
        options[:digest]
      elsif @env[:digest]
        @env[:digest]
      else
        false
      end
      {'Authorization' => digest} if digest
    end

    #
    # Proxy connections?
    #
    def proxy?
      @env.key? :proxy
    end

    #
    # Get the correct class based on proxy settings.
    #
    def net_http_class
      if proxy?
        proxy = @env[:proxy]
        Net::HTTP::Proxy(proxy[:uri].host, proxy[:uri].port, proxy[:user], proxy[:password])
      else
        Net::HTTP
      end
    end

    #
    # Builds a path with optional resources paths if specified.
    #
    def build_path(root, options, optional_resources)
      optional_resources.inject(root) do |path, resource|
        path << "/#{options[resource]}" if options[resource]
        path
      end
    end

    #
    # Builds the params hash from the options.
    #
    def build_params(options, optional_params)
      optional_params.inject({}) do |params, param|
        params[camelize(param.to_s, false)] = options[param] if options[param]
        params
      end
    end

    #
    # Appends to the params date comparisions.
    #
    def build_date_params(options, optional_date_params)
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
        params
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
