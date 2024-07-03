# frozen_string_literal: true

require 'date'

# set the fuzz period to 5 mins meaning
# that if the token is within 5 mins of expiring
# we should renew it
EXPIRY_FUZZ = 60 * 5 # 5 mins

# Implments the authentication for the PlayOn Recorder API
# We can copy the functionality of the ofllowing httpie command:
class Auth
  def initialize(email, password, cfgpath)
    @email    = email
    @password = password
    @exp      = nil
    @jwt      = nil
    @at       = nil
    @cfgpath  = cfgpath

    @client   = WebClient.new(@jwt).client
  end

  def save_config
    config = ConfigFile.new(@cfgpath)
    config.save({
                 auth:
                   { email: @email,
                     exp:   @exp,
                     jwt:   @jwt,
                     at:    @at
                   }
                 })
  end

  def token_is_expired?
    return true if @exp.nil?

    now_w_fuzz = DateTime.now.to_time.to_i - EXPIRY_FUZZ
    now_w_fuzz <= @exp
  end

  def should_renew?
    return false if @exp.nil?

    now = DateTime.now.to_time.to_i
    @exp - now <= EXPIRY_FUZZ
  end

  def read_config
    config = ConfigFile.new(@cfgpath)
    cfg = config.load
    return unless cfg

    auth   = cfg[:auth]
    @email = auth[:email]
    @exp   = auth[:exp]
    @jwt   = auth[:jwt]
    config
  end

  # http --follow POST api.playonrecorder.com/v3/login x-mmt-app:web email==snafuxnj@yahoo.com password=="$(kwalletcli -f playonrecorder -e snafuxnj@yahoo.com)")"
  # note that email and password are sent as query parameters
  def login
    return read_config unless token_is_expired?

    renew_token && return if should_renew?

    uri  = '/v3/login'
    uri += format('?email=%s&password=%s',
                  URI.encode_www_form_component(@email),
                  URI.encode_www_form_component(@password))
    response  = @client.post(uri)
    resp_body = JSON.parse(response.body, symbolize_names: true)

    raise format('Login failed: %s', resp_body[:error_message]) unless resp_body[:success]

    resp_body = resp_body[:data]
    @exp      = resp_body[:exp]
    @jwt      = resp_body[:token]
    @at       = resp_body[:auth_token]
    save_config
    resp_body
  end

  # http --follow POST api.playonrecorder.com/v3/login/at x-mmt-app:web "Authorization: Bearer "$(jq -Mr '.data.token' <<< "$por_json")"" auth_token:"$(jq -Mr '.data.auth_token' <<< "$por_json")"
  # tokens last for three hours
  def renew_token
    uri  = '/v3/login/at'
    response = @client.post(uri) do |req|
      req.headers['auth_token']    = @at
      req.headers['Authorization'] = format('Bearer %s', @jwt)
    end
    resp_body = JSON.parse(response.body, symbolize_names: true)

    raise format('Token renewal failed: %s', resp_body[:message]) unless resp_body[:success]

    resp_body = resp_body[:data]
    @exp      = resp_body[:exp]
    @jwt      = resp_body[:token]
    @at       = resp_body[:auth_token]
    save_ config
    resp_body
  end
end
