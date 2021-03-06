module Gplus
  # The main Gplus class, containing methods for initializing a Google+ client and requesting authorization
  class Client
    include Activity
    include Comment
    include Person

    # The default Google+ API endpoint that all requests are sent to.
    DEFAULT_ENDPOINT = 'https://www.googleapis.com/plus'
    # The default version of the Google+ API to send requests to.
    DEFAULT_API_VERSION = 'v1'

    attr_accessor :endpoint, :api_version

    # Create a Google+ API client. Read the {file:README.md README} to find learn about the different ways of initializing a client.
    #
    # @param [Hash] options
    # @option options [String] :api_key Your application's API key, used for non-authenticated requests (for public data).
    # @option options [String] :token The OAuth token to authorize the API client for authenticated requests (for non-public data). This can be supplied after initialization by calling {#authorize}.
    # @option options [String] :refresh_token The OAuth refresh_token, to request a new token if the provided token has expired.
    # @option options [Integer] :token_expires_at The time that the OAuth token expires at in seconds since the epoch.
    # @option options [String] :client_id Your application's Client ID. Required to generate an authorization URL with {#authorize_url}.
    # @option options [String] :client_secret Your application's Client Secret. Required to generate an authorization URL with {#authorize_url}.
    # @option options [String] :redirect_uri The default URI to redirect to after authorization. You can override this in many other methods. It must be specified as an authorized URI in your application's console. Required to generate an authorization URL with #authorize_url.
    # @return [Gplus::Client] A Google+ API client.
    def initialize(options = {})
      self.endpoint = DEFAULT_ENDPOINT
      self.api_version = DEFAULT_API_VERSION

      @api_key = options[:api_key]
      @token = options[:token]
      @refresh_token = options[:refresh_token]
      @token_expires_at = options[:token_expires_at]
      @client_id = options[:client_id]
      @client_secret = options[:client_secret]
      @redirect_uri = options[:redirect_uri]

      @oauth_client = OAuth2::Client.new(
        @client_id,
        @client_secret,
        :site => self.endpoint,
        :authorize_url => 'https://accounts.google.com/o/oauth2/auth',
        :token_url => 'https://accounts.google.com/o/oauth2/token'
      )
    end

    # Generate an authorization URL where a user can authorize your application to access their Google+ data.
    # @see https://code.google.com/apis/accounts/docs/OAuth2WebServer.html#formingtheurl The set of query string parameters supported by the Google Authorization Server for web server applications.
    #
    # @param [Hash] options Additional parameters used in the OAuth request.
    # @option options [String] :redirect_uri An optional over-ride for the redirect_uri you initialized the API client with. This must match the redirect_uri you use when you call #get_token.
    # @option options [String] :access_type ('online'). Indicates if your application needs to access a Google API when the user is not present at the browser. Allowed values are 'online' and 'offline'.
    # @return [String] A Google account authorization URL for your application.
    def authorize_url(options = {})
      defaults = { :scope => 'https://www.googleapis.com/auth/plus.me', :redirect_uri => @redirect_uri }
      options = defaults.merge(options)
      @oauth_client.auth_code.authorize_url(options)
    end

    # Retrieve an OAuth access token using the short-lived authentication code given to you after a user authorizes your application.
    # Note that if you specified an over-ride redirect_uri when you called #authorize_url, you must use the same redirect_uri when calling #get_token.
    #
    # @param [String] auth_code The code returned to your redirect_uri after the user authorized your application to access their Google+ data.
    # @param [Hash] params Additional parameters for the token endpoint (passed through to OAuth2::Client#get_token)
    # @param [Hash] opts Additional access token options (passed through to OAuth2::Client#get_token)
    # @return [OAuth2::AccessToken] An OAuth access token. Store access_token[:token], access_token[:refresh_token] and access_token[:expires_at] to get persistent access to the user's data until access_token[:expires_at].
    def get_token(auth_code, params = {}, opts = {})
      defaults = { :redirect_uri => @redirect_uri }
      params = defaults.merge(params)
      @access_token = @oauth_client.auth_code.get_token(auth_code, params, opts)
    end

    # Authorize a Gplus::Client instance to access the user's private data, after initialization
    #
    # @param [String] :token The OAuth token to authorize the API client for authenticated requests (for non-public data).
    # @param [String] :refresh_token The OAuth refresh_token, to request a new token if the provided token has expired.
    # @param [Integer] :token_expires_at The time that the OAuth token expires at in seconds since the epoch.
    # @return An OAuth2::AccessToken
    def authorize(token, refresh_token, token_expires_at)
      @token = token
      @refresh_token = refresh_token
      @token_expires_at = token_expires_at
      access_token
    end

    # Retrieve or create an OAuth2::AccessToken, using the :token and :refresh_token specified when the API client instance was initialized
    #
    # @return An OAuth2::AccessToken
    def access_token
      if @token
        @access_token ||= OAuth2::AccessToken.new(@oauth_client, @token, :refresh_token => @refresh_token, :expires_at => @token_expires_at)
        if @access_token.expired?
          @access_token = @access_token.refresh!
          @access_token_refreshed = true
        end
        @access_token
      end
    end

    # Return true if the user's access token has been refreshed. If so, you should store the new token's :token and :expires_at.
    def access_token_refreshed?
      @access_token_refreshed
    end

  private
    def get(path, params = {})
      if access_token
        response = access_token.get("#{self.api_version}/#{path}", :params => params)
      else
        response = @oauth_client.request(:get, "#{self.api_version}/#{path}", { :params => params.merge(:key => @api_key) })
      end
      MultiJson.decode(response.body)
    end
  end
end
