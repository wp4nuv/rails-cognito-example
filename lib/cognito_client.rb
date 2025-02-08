# require "cognito_jwt_keys"
require "cognito_manager"
require "cognito_pool_tokens"
require "cognito_urls"

class CognitoClient

  def initialize(params = {})
    @client_id = params[:client_id] || ENV['AWS_COGNITO_APP_CLIENT_ID']
    @pool_id = params[:pool_id] || ENV['AWS_COGNITO_POOL_ID']
    @client_id = params[:client_id] || ENV['AWS_COGNITO_APP_CLIENT_ID']
    cognito_client = Aws::CognitoIdentityCredentials(@pool_id, Aws::CognitoIdentity::Client.new(Aws.config[:region]))
    manager = CognitoManager.new(cognito_client)
    manager.list_user_pools
=begin
var (
    clientID     = "3fmu81rd31pna82uujpdccu6vn"
    clientSecret = "<client secret>"
    redirectURL  = "https://d84l1y8p4kdic.cloudfront.net"
    issuerURL    = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_Xhb8xytmT"
    provider     *oidc.Provider
    oauth2Config oauth2.Config
)
    @pool_id = params[:pool_id] || ENV['AWS_COGNITO_POOL_ID']
    @client_id = params[:client_id] || ENV['AWS_COGNITO_APP_CLIENT_ID']
    @client_secret = params[:client_secret] || ENV['AWS_COGNITO_APP_CLIENT_SECRET']
    @redirect_uri = params[:redirect_uri]
=end
  end

  def get_pool_tokens(authorization_code)
    params = {
      grant_type: 'authorization_code',
      code: authorization_code,
      client_id: @client_id,
      redirect_uri: @redirect_uri
    }

    resp = Excon.new(token_uri,
                      :user => @client_id,
                      :password => @client_secret,
                      :body => URI.encode_www_form(params),
                      :headers => { "Content-Type" => "application/x-www-form-urlencoded"})

    unless resp.status == 200
      Rails.logger.warn("Invalid code: #{authorization_code}: #{resp.body}")
      return nil
    end

    CognitoPoolTokens.new(CognitoJwtKeysProvider.keys, JSON.parse(resp.body))
  end

  # From: https://medium.com/tensult/how-to-refresh-aws-cognito-user-pool-tokens-d0e025cedd52
  def refresh_id_token(refresh_token)
    params = {
      ClientId: @client_id,
      AuthFlow: 'REFRESH_TOKEN_AUTH',
      AuthParameters: {
        REFRESH_TOKEN: refresh_token,
        SECRET_HASH: @client_secret
      }
    }

    hdrs = {
      "X-Amz-Target": "AWSCognitoIdentityProviderService.InitiateAuth",
      "Content-Type": "application/x-amz-json-1.1"
    }

    resp = Excon.new(CognitoUrls.refresh_token_uri,
                      :headers => hdrs,
                      :body => params.to_json)
    if resp.status != 200
      return nil
    end

    json = JSON.parse(resp.body)

    # Key names are different here, so need to translate :-/
    tokens = {
      'id_token' => json['AuthenticationResult']['IdToken'],
      'access_token' => json['AuthenticationResult']['AccessToken']
    }

    CognitoPoolTokens.new(CognitoJwtKeysProvider.keys, tokens)
  end

private

  def token_uri
    CognitoUrls.token_uri
  end
end
