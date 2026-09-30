require "socket"
require "json"

module Mpv
  SOCKNAME = "/tmp/mpv-remote.socket"

  class Process
    def self.start
      env = {
        "DISPLAY" => ENV["DISPLAY"] || ":0"
      }
      process = ::Process.new(
        "mpv",
        [
          "--idle=yes",
          "--input-ipc-server=#{SOCKNAME}",
          "--ytdl=yes",
          "--force-window=yes"
        ],
        env: env
      )
    end

    def self.stop(process : ::Process)
      process.terminate
      process.wait
    end
  end

  class Client

    def self.loadfile(uri : String)
      command(["loadfile", uri])
    end

    def self.toggle_play_pause
      command(["cycle", "pause"])
    end

    def self.change_volume(vol : Int32)
      command(["add","volume", vol])
    end

    def self.seek(percent : Int32)
      command(["seek", percent, "relative-percent"])
    end

    private def self.command(args : Array(String | Int32)) : String
      socket = UNIXSocket.new(SOCKNAME)

      begin
        message = {"command" => args}.to_json
        socket.puts(message)
        socket.gets.not_nil!
      ensure
        socket.close
      end
    end
  end
end
