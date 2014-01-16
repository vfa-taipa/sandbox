require "socket"
require "thread"

class ChatServer
  def initialize(port)
    @sockets = Array.new
    @lastUpdate = Array.new

    @server = TCPServer.new("", port)
    puts("Ruby chat server started on port #{port}\n")
    @sockets.push(@server)
    @lastUpdate.push(Time.now)

    th = Thread.new do
      while true
        puts("Client Number : #{@sockets.count}")
        @sockets.each do |client|
          if client != @server then
            n = Time.now
            s = n - @lastUpdate[@sockets.index(client)]
            if (s > 10) then
              puts("Remove Client : #{client.peeraddr[2]}\n")
              #client.close
              #@lastUpdate.delete_at(@sockets.index(client))
              #@sockets.delete(client)
            elsif (s > 2)
              client.puts("PING")
            end
            #client.puts("PING")
          end
        end
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
              @lastUpdate.delete_at(@sockets.index(sock))
              @sockets.delete(sock)
            else
              str = sock.gets()
              str1 = "[#{sock.peeraddr[2]}]: #{str}"
              @lastUpdate[@sockets.index(sock)] = Time.now

              if (str.match(/^PONG/) == nil) then
                broadcast(str1, sock)
              else
                #puts("PONG from : #{sock.peeraddr[2]}")
              end
            end
          end
        end
    end
  end

  def accept_client
    newsocket = @server.accept # Accept newsocket's connection request

    # add newsockets to the list of connected sockets
    @sockets.push(newsocket)
    @lastUpdate.push(Time.now)
    
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
        puts("Send to : #{client.peeraddr[2]}\n")
      end
    end
    # Print all broadcasts to the server's STDOUT
    print(str)
  end
end

myChatServer = ChatServer.new(2700)

