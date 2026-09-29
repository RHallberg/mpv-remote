require "kemal"
require "json"
require "uri"

MAIN_HTML = {{ read_file("public/index.html") }}

get "/" do |env|
  env.response.content_type = "text/html"
  MAIN_HTML
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
    # TODO: Post uri to mpv through unix socket

  rescue URI::Error
    next respond_with_error(env, 400, "Invalid uri")
  end
end


private def respond_with_error(env, status_code : Int32, message : String)
  env.response.status_code = status_code
  env.response.content_type = "application/json"

  {error: message}.to_json
end

Kemal.run
