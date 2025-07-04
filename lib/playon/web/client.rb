# frozen_string_literal: true

API_URL = 'https://api.playonrecorder.com/v3'
WWW_URL = 'https://www.playonrecorder.com'
TMP_EXT = '.download'

class WebClient
  attr_accessor :client

  def initialize(jwt = nil)
    @jwt    = jwt
    @client = create_client
  end

  # TODO: Put version in user-agent string
  def create_client
    Faraday.new(url: API_URL, headers:
                              {
                                'User-Agent':   'Faraday playonrecorder-cli/0.1',
                                'Accept':       'application/json',
                                'Content-Type': 'application/json',
                                'x-mmt-app':    'web',
                                'Authorization': unless @jwt.nil?
                                                   format('Bearer %s', @jwt)
                                                 end
                              })
  end

  def create_dl_client(url)
    Faraday.new(url: url, headers:
                          {
                            'User-Agent':   'Faraday playonrecorder-cli/0.1, Downloader',
                            'Accept':       'application/json',
                            'Content-Type': 'application/json',
                          })
  end

  # filename is not used...for now
  def do_download(url, options, filename, dl_path, dl_tmp, &progress_callback)
    dl_handle      = File.open(dl_tmp, 'wb')
    dl_handle.sync = true

    begin
      create_dl_client(url).get do |req|
        req.options.on_data = proc do |chunk, overall_received_bytes, env|
          dl_handle.write(chunk)
          progress_callback.call(overall_received_bytes) if progress_callback
        end
      end
    rescue StandardError => e
      raise format('Download failed: %s', e)
    end

    true
  end
end
