require "socket"
require "thread"
require "json"

class ChatServer
  def initialize(port)
    # All socket
    @sockets = Array.new

    # Save last update time in this array for check timeout of each socket client
    @lastUpdate = Array.new

    # Group id lists
    @groupids = Array.new

    mutex = Mutex.new

    @server = TCPServer.new("", port)
    puts("Ruby chat server started on port #{port}\n")
    @sockets.push(@server)
    @lastUpdate.push(Time.now)
    @groupids.push("0")

    # New thread for check client socket is alive by timeout in 5s
    th = Thread.new do
      while true
        #puts("Client Number : #{@sockets.count}")
        @sockets.each do |client|
          if client != @server then
            n = Time.now
            s = n - @lastUpdate[@sockets.index(client)]
            if (s > 5) then # If lastupdate is over 5s, remove this socket client.
              puts("Remove Client : #{client.peeraddr[2]}\n")
              mutex.synchronize do
                client.close
                @lastUpdate.delete_at(@sockets.index(iclient))
                @groupids.delete_at(@sockets.index(iclient))
                @sockets.delete(client)
              end
            elsif (s > 2)
              # If lastupdate is over than 2s, send PING sign
              client.puts("PING")
            end
            #client.puts("PING")
          end
        end
        sleep(1)
      end
    end

    run()

    th.join
  end

  def run
    while true

      begin
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
              @groupids.delete_at(@sockets.index(sock))
              @sockets.delete(sock)
            else
              str = sock.gets()
              @lastUpdate[@sockets.index(sock)] = Time.now

              if (str.match(/^PONG/) == nil) then
                cmd = JSON.parse(str)
                if (cmd["cmd"] == 2) # Update group id
                  @groupids[@sockets.index(sock)] = cmd["roomid"]
                else
                  str1 = "[#{sock.peeraddr[2]}]: #{str}"
                  broadcast_to_room(str1, sock, cmd["roomid"])
                end
              else
                #puts("PONG from : #{sock.peeraddr[2]}")
              end
            end
          end
        end
      rescue
        puts("ERROR !")
      end
    end
  end

  #======================================
  # Accept new client
  #======================================
  def accept_client
    newsocket = @server.accept # Accept newsocket's connection request

    # add newsockets to the list of connected sockets
    @sockets.push(newsocket)
    @lastUpdate.push(Time.now)
    @groupids.push("TEMP_ID")
    
    # Inform the socket that it has connected, then inform all sockets of the new connection
    newsocket.puts("You're connected to the Ruby Chat Server! Woohoo")
    str = "Client joined #{newsocket.peeraddr[2]}\n"
    broadcast(str, newsocket)
  end

  #======================================
  # Broadcast to all
  #======================================
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

  #======================================
  # Broadcast to a group
  #======================================
  def broadcast_to_room(str, omit_sock, groupid)
    # Send the string argument to every socket that is not the server,
    # and not the socket the broadcast originated from.
    @sockets.each do |client|
      group = @groupids[@sockets.index(client)]
      if client != @server && client != omit_sock && group == groupid then
        client.puts(str)
        puts("Send to : #{client.peeraddr[2]}\n")
      end
    end
    print(str)
  end
end

myChatServer = ChatServer.new(2700)

# message format : {"cmd":1, "roomid":"","userid":"","content":""}
# Update groupid : {"cmd":2, "roomid":"123","userid":"", "content":""}
# Send msg to room : {"cmd":3, "roomid":"123","userid":"", "content":"PHAM ANH TAI"}
#
#
#

