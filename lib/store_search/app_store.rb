require 'uri'
require 'cgi'
require 'timeout'
require 'net/http'
require 'json'

module StoreSearch
  class AppStore

    LOOKUP_URL              = URI.parse('https://itunes.apple.com/lookup')
    AVAILABLE_LOOKUP_PARAMS = %i[id country lang]
    AVAILABLE_ATTRIBUTES    = %i[language_code country_code fallback_country_codes]

    TIMEOUTS = 20

    attr_accessor *AVAILABLE_ATTRIBUTES, :country_codes

    class << self
      # Public: Makes itunes lookups for a given store id.
      #
      # app_store_id - given application itunes store id.
      # params       - additional hash with attributes, see #initialize
      #
      # Examples
      #
      # Search::AppStore.fetch_app_details 12341234, country_code: 'DE'
      # # => <Search::AppStoreParser title: '...', etc... />
      #
      # Returns parsed itunes response.
      # Raises - see #lookup!
      def fetch_app_details(app_store_id, params = {})
        AppStoreParser.parse new(params).find(app_store_id)
      end
    end

    # Public: Initializes Search::AppStore with the given attributes.
    #
    # attributes[:language_code]          - requested language code.
    # attributes[:country_code]           - requested store in a given country
    # attributes[:fallback_country_codes] - list of fallback stores country codes, that
    #                                       should be checked if app is missing in the
    #                                       given country_code
    def initialize(attributes = {})
      AVAILABLE_ATTRIBUTES.each do |attr|
        send "#{attr}=", attributes[attr] if !!attributes.has_key?(attr) && !attributes[attr].empty?
      end

      self.country_codes = [country_code] | Array(fallback_country_codes)
      self.country_codes = country_codes.compact
     end

    # Public: Tries to find the app in different stores.
    #
    # app_store_id - given application itunes store id.
    def find(app_store_id)
      country_codes.each do |country_code|
        begin
          return lookup!(id: app_store_id, country: country_code, lang: language_code)
        rescue NoResultsError
          next
        end
      end

      raise NoResultsError, "Could not find game in any country(#{ country_codes.join(', ') })"
    end

    # Public: Makes a request to itunes store in a specified country,
    #         to fetch informations about given app_store_id.
    #
    # options - AVAILABLE_LOOKUP_PARAMS
    #
    # Returns hash with app details.
    # Raises Search::NoResultsError when it can't find an app.
    # Raises Search::RequestError on invalid response from itunes.
    # Raises Search::InvalidCountryError on invalid ISO country code.
    # Raises Search::MalformedResponseError on strange itunes response.
    def lookup!(options = {})
      response = get_json uri_with_query(options)

      validate_response_errors!      response, options[:country]
      validate_response_format!      response
      validate_response_application! response

      application_details response
    end

    # Public: Gets the application details from the itunes response.
    def application_details(response)
      response['results'][0]
    end

    private

    # Private: Builds the itunes request uri with the given query_hash.
    #
    # query_hash - AVAILABLE_LOOKUP_PARAMS
    #
    # Returns itunes URI with proper query parameters.
    def uri_with_query(query_hash)
      LOOKUP_URL.dup.tap do |uri|
        uri.query = query_hash.select { |param, value|
          !value.empty? && AVAILABLE_LOOKUP_PARAMS.include?(param)
        }.map{|k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v)}"}.join("&")
      end
    end

    def get_json(uri)
      req = Net::HTTP::Get.new(uri.request_uri)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.read_timeout = TIMEOUTS
        http.request(req)
      end

      return JSON.parse(response.body) if response.kind_of?(Net::HTTPOK) && !response.body.nil?

      error_msg = "URL: #{uri} - RESPONSE: #{response.inspect}"
      case response
      when Net::HTTPOK;             raise HTTPEmptyBodyError.new(error_msg) if response.body.blank?
      when Net::HTTPUnauthorized;   raise HTTPUnauthorizedError.new(error_msg)
      when Net::HTTPForbidden;      raise HTTPForbiddenError.new(error_msg)
      else                          raise UnexpectedHTTPResponseError.new(error_msg)
      end
    end

    def validate_response_errors!(response, country_code)
      if response && (error = response['errorMessage'])
        case error
        when 'Invalid value(s) for key(s): [country]'
          raise InvalidCountryError, "Could not find app for given country, or country code is invalid: \"#{ country_code }\"."
        else
          raise RequestError, "Request have failed with given error message: \"#{ error }\"."
        end
      end
    end

    def validate_response_format!(response)
      if !response || !response['resultCount'] || !response['results']
        raise MalformedResponseError, 'Response has an invalid format'
      end
    end

    def validate_response_application!(response)
      raise NoResultsError, 'Response is valid, but the application was not found' if response['resultCount'].zero?
    end

  end
end
