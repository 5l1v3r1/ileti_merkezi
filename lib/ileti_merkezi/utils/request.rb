# frozen_string_literal: true

module IletiMerkezi
  # Request
  # :reek:TooManyInstanceVariables { max_instance_variables: 6 }
  class Request
    include XmlBuilder

    DEFAULT_OPTIONS = {
      use_ssl: false,
      verify_mode: OpenSSL::SSL::VERIFY_PEER,
      read_timeout: 30,
      open_timeout: 30
    }.freeze

    DEFAULT_HEADERS = {
      'accept' => 'xml',
      'content-type' => 'text/xml;charset=utf-8'
    }.freeze

    private_constant :DEFAULT_OPTIONS
    private_constant :DEFAULT_HEADERS

    # :reek:Attribute
    attr_writer :uri

    def initialize(body: nil, payload: '', path: '')
      @config  = IletiMerkezi.configuration
      @payload = payload
      @path    = path
      @body    = body
      @uri     = URI.parse(@config.endpoint + @path)
    end

    def call
      req      = Net::HTTP::Post.new(@uri.request_uri, DEFAULT_HEADERS)
      req.body = @body || body
      Response.new http.request(req)
    end

    private

    attr_reader :config, :uri, :payload

    def body
      hash_to_xml(
        request: {
          authentication: Authentication.to_hash,
          order: payload
        }
      )
    end

    def http
      options = DEFAULT_OPTIONS.merge(config.request_overrides)
      http    = Net::HTTP.new(
        uri.hostname, (options[:use_ssl] ? 443 : @uri.port)
      )
      http_configure(http, options)
    end

    def http_configure(http, options)
      options.each do |option, value|
        setter = "#{option.to_sym}="
        http.send(setter, value) if http.respond_to?(setter)
      end
      http
    end
  end
end
