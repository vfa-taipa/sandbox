#!/usr/bin/env ruby


# =======================
# Event Machine UDP
# =======================

require 'rubygems' # or use Bundler.setup
require 'eventmachine'
require 'json'

class Client
  attr_reader :userid
  attr_reader :roomid
  attr_reader :ip
  attr_reader :port
  attr_reader :lastupdate

  def initialize(ip, port, userid, roomid)
    @ip = ip
    @port = port
    @userid = userid
    @roomid = roomid
  end
end

class UDPHandler < EM::Connection

  @@Clients = Array.new

  # ============================================================
  # EventMachine handlers
  # ============================================================
  def receive_data(data)
    puts("=======================================")
    data.chomp!
    port, ip = Socket.unpack_sockaddr_in(self.get_peername)

    puts("Received #{data}")
    puts("#{Socket.unpack_sockaddr_in(self.get_peername)}")

    findClient = @@Clients.select { |c| c.ip == ip && c.port == port }

    if (findClient.size == 0) then
      newClient = Client.new(ip, port, nil, nil)
      @@Clients.push(newClient)

      puts "A client has connected..."
    end

    puts("Client count : #{@@Clients.size}")

    #Send to all
    @@Clients.each { |c| 
      send_datagram("Server : #{data}\n", c.ip, c.port)
    }
  end

  # ============================================================
  # Command handling
  # Init Connection  : {"cmd":1, "roomid":"123","userid":"123","content":""}
  # Send msg to room : {"cmd":2, "roomid":"123","userid":"", "content":"PHAM ANH TAI"}
  # ============================================================
  def handle_command(data)
    puts(data)
    begin
      cmd = JSON.parse(data)

      if (cmd["cmd"] == 1) then
        @@Clients.delete_if { |c| c.userid == cmd["userid"]}

        port, ip = Socket.unpack_sockaddr_in(self.get_peername)
        newUser = Client.new(ip, port, cmd["userid"], cmd["roomid"])
        
        @@Clients.push(newUser)

        puts("cmd 1 \n")
      elsif (cmd["cmd"] == 2) then
        puts("cmd 2 \n")
        self.setUserInfo(cmd)
      elsif (cmd["cmd"] == 3) then
        puts("cmd 3 \n")
        findClient = @@Clients.select { |c| c.userid == cmd["userid"]}
        if (findClient.size == 1) then
          self.send_to_group(cmd["content"], "", cmd["roomid"], cmd["userid"])
        end
      end
    rescue Exception => e
      puts("JSON Error !!!")
    end
  end


  # ============================================================
  # Helpers
  # ============================================================
  def send_to_group(msg = nil, prefix = "[chat server]", roomid = nil, userid = nil)
    connection = @@Clients.select { |c| c.roomid == roomid }
    connection = connection.reject { |c| userid == c.userid }
    connection.each { |c| 
      send_datagram("#{prefix} #{msg}\n", c.ip, c.port) } unless msg.empty?
  end

end

EM.kqueue #MacOS
#EventMachine.epoll #Linux

EM.run do
  # hit Control + C to stop
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EM.open_datagram_socket('0.0.0.0', 8080, UDPHandler)
end