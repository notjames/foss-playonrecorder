
VER_FILE = File.join(File.dirname(__FILE__), '..', 'version.rb')

class Version
  def self.to_s
    File.read(VER_FILE).strip
  end
end
