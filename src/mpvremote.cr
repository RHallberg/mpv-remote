require "kemal"
require "json"
require "uri"
require "./mpv/mpv"
require "./files/files"

MAIN_HTML = {{ read_file("public/index.html") }}

FILES_HTML    = {{ read_file("public/files.html") }}
STYLE_CSS     = {{ read_file("public/style.css") }}
MANIFEST_JSON = {{ read_file("public/manifest.json") }}

get "/" do |env|
  env.response.content_type = "text/html"
  MAIN_HTML
end

get "/files" do |env|
  env.response.content_type = "text/html"
  FILES_HTML
end

get "/style.css" do |env|
  env.response.content_type = "text/css"
  STYLE_CSS
end

get "/api/files" do |env|
  env.response.content_type = "application/json"
  Files.available.to_json
end

post "/loadfile" do |env|
  data = JSON.parse(env.request.body.not_nil!.gets_to_end).as_h
  name = data["file"]?.try(&.as_s?)

  unless name && Files.available.includes?(name)
    next respond_with_error(env, 404, "File not found")
  end

  puts "File requested: #{name}"
  Mpv::Client.loadfile(Files.path(name))
  {result: "ok"}.to_json
end

get "/manifest.json" do |env|
  env.response.content_type = "application/manifest+json"
  MANIFEST_JSON
end

post "/loadurl" do |env|
  data = JSON.parse(env.request.body.not_nil!.gets_to_end).as_h
  url = data["url"].as_s

  begin
    uri = URI.parse(url)

    unless uri.scheme.in?("http", "https") && uri.host
      next respond_with_error(env, 400, "Incorrect uri scheme. Needs http or https")
    end

    puts "URL posted: #{uri}"
    Mpv::Client.loadfile(url)
    {result: "ok"}.to_json

  rescue URI::Error
    next respond_with_error(env, 400, "Invalid uri")
  end
end

post "/play-pause" do
  Mpv::Client.toggle_play_pause
end

post "/vol-up" do
  Mpv::Client.change_volume(5)
end

post "/vol-down" do
  Mpv::Client.change_volume(-5)
end

post "/seek-forward" do
  Mpv::Client.seek(2)
end

post "/seek-backward" do
  Mpv::Client.seek(-2)
end

private def respond_with_error(env, status_code : Int32, message : String)
  env.response.status_code = status_code
  env.response.content_type = "application/json"

  {error: message}.to_json
end

mpv_proc = Mpv::Process.start

at_exit do
  Mpv::Process.stop(mpv_proc) unless mpv_proc.terminated?
  File.delete(Mpv::SOCKNAME) if File.exists?(Mpv::SOCKNAME)
end

spawn do
  mpv_proc.wait
  STDERR.puts "mpv exited, shutting down"
  exit 1
end

Kemal.config.port = ENV.fetch("MPVREMOTE_PORT", "3005").to_i
Kemal.run
