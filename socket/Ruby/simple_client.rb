require "socket"

class Client
  def initialize(hostname, port)
    @client = TCPSocket.new(hostname, port)
    run()
  end

  # Continuously wait for messages and then display them
  def run()
    while true
      getmessage()
      displaymessage()
    end
  end

  # Wait for a message to become available in the client socket
  def getmessage()
    @msg = @client.gets
  end
  
  # Display the client socket's message
  def displaymessage()
    puts @msg.chop
  end
end

c = Client.new("127.0.0.1", 2700)

