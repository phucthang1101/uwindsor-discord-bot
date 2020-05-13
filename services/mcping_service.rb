require 'socket'
require 'timeout'
require 'json'

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

    @response = '' 

    # pings the server
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

  def ping()
    # initialize this stuff here to get around scope should i use instance variables, probably

    #gotta define this out of scope or it acts weird
    serv_connection = 0
    begin
      Timeout.timeout(@timeout) do
        start = Time.now
        serv_connection = TCPSocket.new(@server, @port)


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
        # packet length cause who cares
        unpack_varint(serv_connection)
        # packet id cause who cares
        unpack_varint(serv_connection)
        # string length
        size = unpack_varint(serv_connection)

        @response += serv_connection.recv(1024) while @response.size < size

        @online = true
        serv_connection.close
      end
    rescue Timeout::Error
      @online = false
      serv_connection.close
      puts "timed out"
      return
    # if the socket fails or timesout
    rescue StandardError => e
      puts "error boy #{e.message}"
      @online = false
      serv_connection.close
      puts "killed early"
      return
    end
    ping_response_json = JSON.parse(@response)

    @desc = ping_response_json["description"]["text"]
    @max = ping_response_json["players"]["max"]
    @onlinePlayers = ping_response_json["players"]["online"]
    
    puts @desc

  end

  def pack_data(data)
    "#{pack_varint(data.to_s.size)}#{data}"
  end

  # this stuff is kinda magic
  def pack_varint(val)
    varint = ""
    # do this forever but break if val is zero
    # order is important if rewriting this
    loop do
      tmp = val & 0x7f
      val >>= 7
      tmp |= 0x80 unless val.zero?
      varint += [tmp].pack("C")
      break if val.zero?
    end
    varint
  end

  # magic
  # search up varint to understand whats happening
  def unpack_varint(conn)
    data = 0
    4.times do |num|
      # gets a char turns it into a number and then gets the number value
      ordinal = conn.recv(1)

      # if no thing break
      break if ordinal.empty?

      # unpack and put it get the first element
      byte = ordinal.unpack("C").first

      # magic part
      data |= (byte & 0x7f) << (7 * num)
      break if (byte & 0x80).zero?
    end
    data
  end

  # getters
  attr_reader :online
  attr_reader :server
  attr_reader :desc
  attr_reader :onlinePlayers
  attr_reader :max
  attr_reader :players
  attr_reader :latency
end
