require "socket"
require "thread"

class ChatClient
  def initialize(address, port)
    @sockets = Array.new

    @server = TCPSocket.new(address, port)
    #puts("Ruby chat server started on port #{port}\n")
    @sockets.push(@server)
    @sockets.push($stdin)

    run()
  end

  def run
    while true

      # The select method will take as an argument the array of sockets, and return a socket that has    
      # data to be read
      ioarray = select(@sockets, nil, nil, nil)

        # the socket that returned data will be the first element in this array
        for sock in ioarray[0]
          if sock == $stdin then
            @server.puts(sock.gets())
          else
            # Received something on a server socket
            if sock.eof? then
              str = "Client left #{sock.peeraddr[2]}"
              sock.close
              @sockets.delete(sock)
            else
              str = sock.gets()
              if (str.match(/^PING/) != nil) then
                @server.puts("PONG")
              end
              puts(sock.gets())
            end
          end
        end
    end
  end

end

myChatServer = ChatClient.new("127.0.0.1", 2700)

