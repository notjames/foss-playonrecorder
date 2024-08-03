# frozen_string_literal: true
# Author: Jim Conner
# Personal Project

require 'gli'

class Main
  include Helpers
  extend GLI::App
  extend Helpers

  cfg_file    = File.join(Dir.home, '.config', 'playonrecorder', 'config.json')
  dl_path     = File.join('', 'nas', 'nas-media-3', 'stage')
  credentials = nil

  wrap_help_text :verbatim

  program_desc 'Playon Recorder API CLI Tool'

  subcommand_option_handling :normal
  #arguments :strict

  accept(Date) do |string|
    Date.parse(string)
  end

  desc 'Verbosity level'
  flag [:verbose], type: :boolean

  desc 'config file'
  flag [:c, :config],  type: String,
                       default_value: cfg_file

  long_desc %{This tool allows you to manage your PlayOn Recorder. Before you can
              use this tool, you must authenticate with the PlayOn Recorder.
              Please use the 'auth' command to authenticate.}

  desc 'Email address used to auth to PlayOn Recorder'
  flag [:email],   type: String

  desc 'Manage credential management to the PlayOn Recorder'
  command :auth do |auth|
    auth.desc 'Name of the KDE wallet to use'
    auth.long_desc %{If --wallet is used, --folder and --entry are required.
                     Use of --wallet will invoke the KDE Wallet to retrieve
                     the playonrecorder password.}
    auth.flag [:wallet], type: String

    auth.desc 'Name of the folder in the KDE wallet'
    auth.long_desc %{If --wallet is used, --folder and --entry are required.}
    auth.flag [:folder], type: String, default_value: 'playonrecorder'

    auth.desc 'Name of the entry in the KDE wallet'
    auth.long_desc %{If --wallet is used, --folder and --entry are required.}
    auth.flag [:entry],  type: String, default_value: '< --email parameter >'

    auth.desc 'Authenticate with the PlayOn Recorder'
    auth.long_desc %{use either (KDE) --wallet or --email and --password. If --wallet
                     is used, --folder and --entry are required.}

    auth.action do |global, options, args|
      email    = global[:email]
      password = ENV['PLAYON_PASSWORD']

      raise 'Error: --email is required at global level.' if email.nil?

      options[:entry] = nil if options[:entry] =~ /--email/

      wallet   = options[:wallet]
      folder   = options[:folder]
      entry    = options[:entry] || email

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
        print 'Please enter your password: '
        password = $stdin.noecho(&:gets).chomp
        puts
      end

      auth = Auth.new(email, password, global[:c])
      unless auth.login
        warn 'Error: Authentication failed'
      end

      save_config(global[:c], {config:
                                {wallet: options[:wallet],
                                 folder: folder,
                                 entry: entry}})
      puts 'Authenticated'
    end
  end

  desc 'Manage videos on the PlayOn Recorder'
  command :videos do |videos|
    videos.switch [:a, :all],        type: :boolean,
                                     desc: 'show all videos',
                                     default_value: true
    videos.switch [:r, :'reverse'],  type: :boolean,
                                     desc: 'reverse the sort order',
                                     long_desc: %{Reverse the sort order based on --sort-by. Sort numerically
                                                 if --sort-by is a numerical value; alphabetically otherwise.},
                                     default_value: false
    videos.switch [:force],          type: :boolean,
                                     desc: 'force download of videos even if they already exist',
                                     default_value: false
    videos.switch [:progress],       type: :boolean,
                                     desc: 'show download progress',
                                     default_value: true
    videos.flag [:s, :'sort-by'],    type: :string,
                                     desc: 'sort by size, title, episode, download-date, rating, expiry, or year',
                                     default_value: 'title',
                                     must_match: /^size|title|episode|download-date|rating|year|expires$/
    videos.flag [:'by-series'],      type: :string,
                                     desc: 'just show videos from this series(s)',
                                     multiple: true
    videos.flag [:'by-season'],      type: :string,
                                     desc: 'just show videos from this season(s)',
                                     multiple: true
    videos.flag [:'show-as'],        type: :string,
                                     default_value: 'table',
                                     desc: 'show output as table, json, yaml, or csv',
                                     must_match: /^table|json|yaml|csv$/
    videos.flag [:title],            type: :string,
                                     desc: 'show or download videos with named title(s)',
                                     multiple: true
    videos.flag [:'dl-path'],        type: :string,
                                     default_value: dl_path,
                                     desc: 'path to which to download videos'

    vid_lib     = Library::Videos.new(cfg_file)

    videos.desc 'List videos on the PlayOn Recorder'
    videos.command [:ls, :list] do |list|
      list.action do |global, options, args|
        vid_lib.list(options, false)
      end
    end

    videos.desc 'Delete videos on the PlayOn Recorder'
    videos.command [:rm, :delete] do |rm|
      rm.action do |global, options, args|
        videos = vid_lib.list(options, true)
        vid_lib.delete(options, videos)
      end
    end

    videos.desc 'Download videos from the PlayOn Recorder'
    videos.command [:dl, :download] do |dl|
      dl.action do |global, options, args|
        videos = vid_lib.list(options, true)
        vid_lib.download(global, options, videos)
      end
    end
  end

  pre do |global, command, options, args|
    begin
      thing = command.name.to_s == 'auth'

      if thing
        contents = read_config(global[:config])
        global.merge!(contents) unless contents.nil?
      end
    rescue JSON::ParserError => e
      warn format('Error: Unable to parse config file: %s', e.message)
      exit_now!('You will have to re-authenticate')
    end
    true
  end
end
