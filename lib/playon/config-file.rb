# frozen_string_literal: true

class ConfigFile
  def initialize(config_path)
    @config_path = config_path
  end

  def load
    if File.exist?(@config_path)
      JSON.parse(File.read(@config_path), symbolize_names: true)
    end
  end

  def save(contents)
    current = load || {}
    merged  = current.merge(contents)
    File.open(@config_path, 'w', perm: 0600) do |f|
      f.write(JSON.pretty_generate(merged))
    end
  end

  private

  def unlink
    File.unlink(@config_path) if File.exist?(@config_path)
  end
end
