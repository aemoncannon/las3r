#!/usr/bin/ruby
require 'webrick'
require 'net/http'
require 'fileutils'
require 'cgi'
require 'socket'
include WEBrick


HTTP_PORT = 9876
SOCKET_PORT = 9877
@eval_q = []


http_server = HTTPServer.new(:Port => HTTP_PORT,
                             :Logger => Log.new(nil, BasicLog::WARN),
                             :AccessLog => [])

http_server.mount_proc("/push"){ |req, res|
  if req.body
    params = CGI.parse(req.body)
    if params["src"]
      src = params["src"][0]
      @eval_q.push(src)
      puts "PUSH: #{src[0..20]}......"
    end
  end
}


def handle_socket_client(client)
  Thread.start do
    port = client.peeraddr[1]
    name = client.peeraddr[2]
    addr = client.peeraddr[3]
    puts "Flash client connected: #{name}:#{port}"
    begin
      loop do
        if client.closed?
          raise RuntimeError.new()
        end
        if @eval_q.length > 0
          src = @eval_q.pop
          client.write(src)
          client.write("\0")
          puts "POP #{name}:#{port}: #{src[0..20]}......"
        end
        sleep 0.1
      end
    rescue RuntimeError
      puts "Flash client #{name}:#{port} disconnected."
    ensure
      puts "Ensuring close of #{name}:#{port}."
      client.close # close socket on error
    end
    puts "Done with #{name}:#{port}."
  end
end

socket_server = TCPServer.open(SOCKET_PORT)
puts "Listening to tcp socket connections on port #{SOCKET_PORT}."
Thread.start do 
  client = nil
  loop do
    begin
      new_client = socket_server.accept_nonblock
      if new_client
        if client
          puts "Only one flash client at a time, disconnecting existing client."
          client.close
        end
        @eval_q = []
        client = new_client
        handle_socket_client(client)
      end
    rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
      IO.select([socket_server])
      retry
    end
  end
end


trap("INT"){
  http_server.shutdown 
}

puts "Listening to http connections on port #{HTTP_PORT}."
http_server.start


