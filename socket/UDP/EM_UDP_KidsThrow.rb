#!/usr/bin/env ruby


# =======================
# Event Machine UDP
# =======================

require 'rubygems' # or use Bundler.setup
require 'eventmachine'
require 'json'
require 'logger'

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
  @@logger = Logger.new('Kidsthrow.log', 'daily')

  # ============================================================
  # EventMachine handlers
  # ============================================================
  def receive_data(data)
    data.chomp!
    port, ip = Socket.unpack_sockaddr_in(self.get_peername)

    @@logger.debug("From #{Socket.unpack_sockaddr_in(self.get_peername)} : #{data}")
    self.handle_command(data)
  end

  # ============================================================
  # Command handling
  # Init Connection     : {"cmd":1, "roomid":"123","userid":"123","content":""}
  # Send msg to room    : {"cmd":2, "roomid":"123","userid":"", "content":"PHAM ANH TAI"}
  # Leave room          : {"cmd":3, "roomid":"123","userid":"", "content":""}
  # Delete room         : {"cmd":4, "roomid":"123","userid":"", "content":""}
  # {"process":1, "group_id":"123","userid":"123","body":""}
  # ============================================================
  def handle_command(data)
    begin
      msg = JSON.parse(data)

      if (msg["process"] == "1") then 
        #Init connection, Add new user to group
        @@Clients.delete_if { |c| c.userid == msg["userid"]}

        port, ip = Socket.unpack_sockaddr_in(self.get_peername)
        newUser = Client.new(ip, port, msg["userid"], msg["group_id"])
        
        @@Clients.push(newUser)
        send_data(JSON.generate({:ip => ip, :port => port}))
      elsif (msg["process"] == "99") then
        # Remove user from group
        @@Clients.delete_if { |c| c.userid == msg["userid"]}
      else #Send to group
        findClient = @@Clients.select { |c| c.userid == msg["userid"]}
        if (findClient.size == 1) then
          self.send_to_group(data, msg["group_id"], msg["userid"])
        end
      end
    rescue Exception => ex
      puts ex.message
      puts ex.backtrace.join("\n")
    end
  end


  # ============================================================
  # Helpers
  # ============================================================
  def send_to_group(msg = nil, roomid = nil, userid = nil)
    connection = @@Clients.select { |c| c.roomid == roomid }
    # connection = connection.reject { |c| userid == c.userid }
    connection.each { |c| 
      send_datagram("#{msg}\n", c.ip, c.port)
      @@logger.debug("Send #{c.ip}:#{c.port} : #{msg}")
    } unless msg.empty?
      
  end

end
#EM.kqueue #MacOS
EM.epoll #Linux

EM.run do
  # hit Control + C to stop
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EM.open_datagram_socket('0.0.0.0', 8888, UDPHandler)
end