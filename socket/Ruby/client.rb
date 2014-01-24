require "socket"
require "thread"
require "json"

class ChatClient
  def initialize(address, port)
    @sockets = Array.new

    puts("Please input group id : ")
    @roomid = gets
    @roomid = @roomid.chomp

    @server = TCPSocket.new(address, port)

    @sockets.push(@server)
    @sockets.push($stdin)

    # Send room ID to server
    # Update groupid : {"cmd":2, "roomid":"123","userid":"", "content":""}
    cmd = {"cmd" => 2, "roomid" => @roomid, "userid" => "", "content" => ""}
    @server.puts(JSON.generate(cmd))
    
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
            cmd = {"cmd" => 3, "roomid" => @roomid, "userid" => "", "content" => sock.gets().chomp}
            #@server.puts(sock.gets())
            @server.puts(JSON.generate(cmd))
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
              else
                puts(str)
              end
            end
          end
        end
    end
  end

end

myChatServer = ChatClient.new("127.0.0.1", 8080)

