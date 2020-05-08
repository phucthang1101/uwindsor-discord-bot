require 'socket'
require 'timeout'

class McpingService

  TCP_TIMEOUT = 5

  def initialize(server, port)
    @server = server
    @port = port

    @online # online or naw

    @desc # description of server
    @onlinePlayers # players that are online
    @max # max player count
    @players # list of players
    @latency # latency of the server

    ping()
  end

  def self.ping()

  end
end
