require 'socket'
require 'timeout'

class McpingService

  TCP_TIMEOUT = 5

  def initialize(server, port, timeout = TCP_TIMEOUT)
    @server = server
    @port = port
    @timeout = timeout

    @online # online or naw

    @desc # description of server
    @onlinePlayers # players that are online
    @max # max player count
    @players # list of players
    @latency # latency of the server

    ping()
  end

  # ping function pings the server using the json method from server 1.7
  # returns nothing
  #
  # ping function for server 1.7 works like this
  # client sends
  #   \x00 <protocol version as varint (\x00)> <server address string> <port as uint> <state of response (1 for status, 2 for login)>
  #   \x00
  # server sends
  #   \x00 <length as varint> <json data as string>
  # all data has to be packed to send and unpacked to be read
  # sometimes notchian(mojang java) servers can be weird and will time out themselves and then send data(around 30 seconds)

  def self.ping()
    begin
      timeout(@timeout) do
        start = Time.now
        servConnection = TCPSocket.new(@server, @port)


        # Time object subtract time object returns a float, multiply that by 1000 to get miliseconds and then round
        @latency = ((Time.now - start)* 1000).round
        
        # the handshake data all packed up and sent
        packed_port = [@port].pack("S>")
        packed_host = pack_data(@server.encode("UTF-8"))
        handshake = pack_data("\x00\x00" + packed_host + packed_port + "\x01")
        serv_connection.write(handshake)

        # extra packet sent because specification says so
        serv_connection.write(pack_data("\x00"))

        # recieve and read the responses




      end
    # if the socket fails or timesout
    rescue
      @online = false
    # always close the connection
    ensure
      servConnection.close
    end

  end

  def self.pack_data(data)
    pack_varint(data.to_s.size) + data.to_s
  end

  # this stuff is kinda magic
  def self.pack_varint(val)
    varint = ""
    loop do
      tmp = val & 0x7f
      val >>= 7
      break unless val.zero? do
        varint += [tmp |= 0x80].pack("C")
      end
    end
    varint
  end

end
