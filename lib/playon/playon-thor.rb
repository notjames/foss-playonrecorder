# frozen_string_literal: true`

require 'thor'

# Implements the command line interface for the PlayOn Recorder API
# The following globally scoped options will be implemented:
# * --verbose (optional)
#
# The following sub command
# * auth
#
# with the following options to be implemented:on the auth sub command:
# * --email    (required)
#
# --email is required, but password is only required if --kwallet is not
# specified. If --kwallet is specified, then the password will be retrieved
# from the system dbus.
#
# with the following sub-command will be implemented on auth::
# * kwallet (optional)
#
# with the following options to be implemented on the kwallet sub command:
# --wallet <wallet name>
# --folder <folder name>
# --entry  <entry name>
#
# The following sub command will be implemented:
# * videos
#
# with the following sub commands to be implemented on the videos sub command:
# * list
#
# The list sub command will have the following options implemented:
# * --all (default)
# * --by-title
# * --by-series
# * --by-season
# * --by-episode
# * --by-dl-date
#
# The following sub command will be implemented:
# * delete
#
# The delete sub command will have the following options implemented:
# * --all
# * --title
# * --series
# * --season
# * --episode
# * --dl-date

# Implements the sub command for the videos sub commands
class Videos < Thor
  desc 'list', 'List videos on the PlayOn Recorder'
  option :all, type: :boolean
  option 'by-title', type: :string
  option 'by-series', type: :string
  option 'by-season', type: :string
  option 'by-episode', type: :string
  option 'by-dl-date', type: :string
  def list
    puts 'List videos'
    Library::Videos.new.list
  end

  desc 'delete', 'Delete videos on the PlayOn Recorder'
  option :all, type: :boolean
  option 'title', type: :string
  option 'series', type: :string
  option 'season', type: :string
  option 'episode', type: :string
  option 'dl-date', type: :string
  def delete
    puts 'Delete videos'
    Library::Videos.new.delete
  end

  desc 'download', 'Download videos on the PlayOn Recorder'
  option :all, type: :boolean
  option 'title', type: :string
  option 'series', type: :string
  option 'season', type: :string
  option 'episode', type: :string
  option 'dl-date', type: :string
  def download
    puts 'Download videos'
    Library::Videos.new.download
  end
end

class Main < Thor
  class_option :verbose, type: :boolean

  desc 'login', 'Login to PlayOn API using email and password from env $PLAYON_PASSWORD'
  option :email, required: true
  long_desc <<-LONGDESC
  Performs the authentication to the PlayOn Recorder API. The email
  address is required, but the password is optional. If the password
  is not provided, then the password will be retrieved the environment
  variable called PLAYON_PASSWORD. If that doesn't exit then the password
  will be retrieved from the KDE Wallet. If that fails then the program
  will exit with an error.
  LONGDESC
  def login(*args)
    email    = options[:email] || ENV['PLAYON_EMAIL']
    password = ENV['PLAYON_PASSWORD']
    auth     = Auth.new(email, password)
    auth.login

    # Handle subcommands
    handle_videos_subcommand(args)
  end

  desc 'kwallet', 'Login to Playon API with email and by retrieving password from kwallet'
  option :email,  required: true
  option :wallet, required: true
  option :folder, required: true
  option :entry,  required: true
  def kwallet(*args)
    email  = options[:email]
    wallet = options[:wallet]
    folder = options[:folder]
    entry  = options[:entry]

    kwallet  = KWallet.new(wallet, folder, entry)
    kwallet.get_password

    password = kwallet.password

    auth     = Auth.new(email, password)
    auth.login

    # Handle subcommands
    handle_videos_subcommand(args)
  end

  desc 'videos', 'Subcommands for videos'
  subcommand 'videos', Videos

  def self.exit_on_failure?
    true
  end

  def help(*args)
    super
  end

  private

  def handle_videos_subcommand(args)
    return if args.empty?
    args  = args - ['videos']

    videos      = Videos.new
    method_name = args.shift

    # Call the method on Videos instance if it exists
    unless videos.respond_to?(method_name).nil?
      puts "Unknown subcommand: #{method_name}"
      return
    end

    videos.invoke(method_name, args)
  end
end

# The following is a test of the Main class
# This test
class TestParseArgs < Main
  desc 'test', 'Test the Main class'
  def test_auth
    options = { email: 'snafuxnj@yahoo.com', password: 'password' }
    auth = Auth.new(options[:email], options[:password])
    assert_equal(auth.login, 'success')

    options = { email: 'some@email.com', password: 'password' }
    auth = Auth.new(options[:email], options[:password])
    assert_equal(auth.login, 'success')
  end
end
