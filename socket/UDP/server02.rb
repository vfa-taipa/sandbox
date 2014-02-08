require 'socket'
host = 'localhost'
port = 1234
s = UDPSocket.new
s.bind(nil, port)
clients = Array.new
while true
	text, sender = s.recvfrom(16)
	if clients.index(sender) == nil then
		clients.push(sender)
	end
	
	remote_host = sender[3]
	puts("Clients count : #{clients.length}")
	puts "#{sender[3]}:#{sender[1]} sent #{text}"
  	response = "From server : #{text}"
  	clients.each {|c| 
  		s.send(response, 0, c[3], c[1])	
  	}
end