require "kemal"

MAIN_HTML = {{ read_file("public/index.html") }}

get "/" do |env|
  env.response.content_type = "text/html"
  MAIN_HTML
end

Kemal.run
