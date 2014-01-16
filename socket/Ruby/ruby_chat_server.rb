require "socket"
require "thread"

class ChatServer
  def initialize(port)
    @sockets = Array.new

    @server = TCPServer.new("", port)
    puts("Ruby chat server started on port #{port}\n")
    @sockets.push(@server)

    th = Thread.new do
      while true
        puts("Client Number : #{@sockets.count}")
        sleep(3)  
      end
    end

    run()

    th.join
  end

  def run
    while true

      # The select method will take as an argument the array of sockets, and return a socket that has    
      # data to be read
      ioarray = select(@sockets, nil, nil, nil)

        # the socket that returned data will be the first element in this array
        for sock in ioarray[0]
          if sock == @server then
            accept_client
          else
            # Received something on a client socket
            if sock.eof? then
              str = "Client left #{sock.peeraddr[2]}"
              broadcast(str, sock)
              sock.close
              @sockets.delete(sock)
            else
              str = "[#{sock.peeraddr[2]}]: #{sock.gets()}"
              broadcast(str, sock)
            end
          end
        end
    end
  end

  def accept_client
    newsocket = @server.accept # Accept newsocket's connection request

    # add newsockets to the list of connected sockets
    @sockets.push(newsocket)
    
    # Inform the socket that it has connected, then inform all sockets of the new connection
    newsocket.puts("You're connected to the Ruby Chat Server! Woohoo")
    str = "Client joined #{newsocket.peeraddr[2]}\n"
    broadcast(str, newsocket)
  end

  def broadcast(str, omit_sock)
    # Send the string argument to every socket that is not the server,
    # and not the socket the broadcast originated from.
    @sockets.each do |client|
      if client != @server && client != omit_sock then
        client.puts(str)
      end
    end
    # Print all broadcasts to the server's STDOUT
    print(str)
  end
end

myChatServer = ChatServer.new(2700)

