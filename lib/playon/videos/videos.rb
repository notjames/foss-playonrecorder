# frozen_string_literal: true

require_relative 'list'
require_relative 'delete'
require_relative 'download'

module Library
  class Videos
    include Helpers

    attr_reader :videos

    def initialize(cfg_file)
      @cfg    = cfg_file
      auth
      @videos = nil
    end

    def auth
      config     = read_config(@cfg)
      @creds     = config[:auth]
      @config    = config[:config]

      email      = @creds.email
      cfg        = @cfg

      password   = ENV['PLAYON_PASSWORD']

      wallet     = @config.wallet
      folder     = @config.folder
      entry      = @config.entry

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

      config     = read_config(cfg)
      @creds     = config[:auth]
      @config    = config[:config]
      @jwt       = @creds.jwt
      @client    = WebClient.new(@jwt).client
      @dl_client = WebClient.new(@jwt)
    end
  end
end
