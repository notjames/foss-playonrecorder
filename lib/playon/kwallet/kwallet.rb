# frozen_string_literal: true

require 'dbus'

# Implements the sub command for the kwallet sub command
# This class will retrieve the password from the KDE Wallet
# using ruby-dbus
#

class KWallet
  attr_reader :password

  def initialize(wallet, folder, entry)
    @svc_name = 'org.kde.kwalletd5'
    @obj_path = '/modules/kwalletd5'
    @if_name  = 'org.kde.KWallet'
    @wallet   = wallet
    @folder   = folder
    @entry    = entry
  end

  def get_password
    bus       = DBus.session_bus
    service   = bus.service(@svc_name)
    object    = service.object(@obj_path)

    object.introspect

    kwallet_iface = object[@if_name]

    begin
      handle = kwallet_iface.open(@wallet, 0, 'playon').first
      resp   = kwallet_iface.readPassword(handle, @folder, @entry, 'playon')

      @password = resp.first
    rescue DBus::Error => e
      warn format('Error: {}', e.message)
    end

    nil
  end
end
