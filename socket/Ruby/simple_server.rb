require "socket"

class Server
  def initialize
    @server = TCPServer.new("", 2700)
    listen()
    run()
  end

  # When a client process attempts to connect, accept it and send acceptance msg
  def listen()
    @server = @server.accept
    puts("Accepted new client!")
    @server.puts("Welcome to the server")
  end

  # Continuously loop between getting input from STDIN and broadcasting
  def run()
    while true
      getinput()
      broadcast()
    end
  end

  # Get input from the STDIN device
  def getinput()
    @msg = gets
  end

  # broadcast a message to the client
  def broadcast()
    @server.puts("server >> #{@msg}")
  end
end

puts "Setting up a new server using port 2700..."
s = Server.new()

