module Files
  DIR = File.expand_path(ENV.fetch("MPVREMOTE_FILES_DIR", "files"))

  # Only regular, non-hidden files directly inside DIR are exposed.
  def self.available : Array(String)
    return [] of String unless Dir.exists?(DIR)

    Dir.children(DIR)
      .reject(&.starts_with?('.'))
      .select { |name| File.file?(File.join(DIR, name)) }
      .sort
  end

  def self.path(name : String) : String
    File.join(DIR, name)
  end
end
