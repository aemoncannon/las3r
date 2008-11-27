require 'webrick'
require 'net/http'
require 'fileutils'
require 'cgi'
require 'socket'
include WEBrick


HTTP_PORT = 9876
SOCKET_PORT = 9877


@eval_q = []

http_server = HTTPServer.new(
                             :Port => HTTP_PORT,
                             :Logger => Log.new(nil, BasicLog::WARN),
                             :AccessLog => []
                             )

http_server.mount_proc("/push"){ |req, res|
  if req.body
    params = CGI.parse(req.body)
    if params["src"]
      src = params["src"][0]
      @eval_q.push(src)
      puts "push"
    end
  end
}

trap("INT"){
  http_server.shutdown 
}


socket_server = TCPServer.open(SOCKET_PORT)

def handle_socket_client(client)

  Thread.start do # one thread per client

    port = client.peeraddr[1]
    name = client.peeraddr[2]
    addr = client.peeraddr[3]

    puts "Socket client connected: #{name}:#{port}"

    begin
      loop do
        if @eval_q.length > 0
          client.write(@eval_q.pop)
          client.write("\0")
          puts "pop"
        end
        sleep 0.1
      end
    rescue RuntimeError
      puts "Client #{name}:#{port} disconnected"
    ensure
      client.close # close socket on error
    end
    puts "Done with #{name}:#{port}"
  end

end


Thread.start do 
  loop do
    begin
      client = socket_server.accept_nonblock
      handle_socket_client(client)
    rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
      IO.select([socket_server])
      retry
    end
  end
end



http_server.start

