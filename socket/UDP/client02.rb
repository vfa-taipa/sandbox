##client
require 'socket'

ds = UDPSocket.new
#ds.connect('localhost', 3000)
ds.send("INIT-SOCKET", 0,'localhost', 1234)
read_thr = Thread.new {
	while true
		response,address = ds.recvfrom(1024)
    	puts response
    end
}

while line=gets
    ds.send(line.chomp, 0,'localhost', 1234)
end

read_thr.join