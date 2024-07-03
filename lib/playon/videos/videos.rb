# frozen_string_literal: true

require_relative 'list'
require_relative 'delete'
require_relative 'download'

module Library
  class Videos
    include Helpers

    attr_reader :videos

    def initialize(credentials, cfg_file)
      # allows token refresh or newly authed client if necessary
      @creds  = credentials
      @cfg    = cfg_file
      auth

      @jwt    = credentials.auth.jwt
      @client = WebClient.new(@jwt).client
      @dl_client = WebClient.new(@jwt)
      @videos = nil
    end

    def auth
      email    = @creds.auth.email
      cfg      = @cfg

      password = ENV['PLAYON_PASSWORD']

      wallet   = @creds.config.wallet
      folder   = @creds.config.folder
      entry    = @creds.config.entry

      if wallet
        if folder.nil? || entry.nil?
          warn 'Error: --wallet requires --folder and --entry'
        end

        wallet = KWallet.new(wallet, folder, entry)

        wallet.get_password
        password = wallet.password

        if password.nil?
          warn 'Error: Unable to retrieve password from KDE Wallet'
        end
      end

      if password.nil?
        print 'Please (re-)enter your password: '
        password = $stdin.noecho(&:gets).chomp
        puts
      end

      auth  = Auth.new(email, password, cfg)
      unless auth.login
        warn 'Error: Authentication failed'
      end

      new_credentials = read_config(cfg)

      @creds = new_credentials
    end
  end
end
