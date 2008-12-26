#!/usr/bin/ruby
require 'webrick'
require 'net/http'
require 'fileutils'
require 'cgi'
require 'socket'
include WEBrick


PUSH_HTTP_PORT = 9876
POP_SOCKET_PORT = 9877
POLICY_SOCKET_PORT = 843
@eval_q = []


http_server = HTTPServer.new(:Port => PUSH_HTTP_PORT,
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
trap("INT"){
  http_server.shutdown 
}



def handle_socket_client(client)
  Thread.start do
    port = client.peeraddr[1]
    name = client.peeraddr[2]
    addr = client.peeraddr[3]
    puts "Flash client connected: #{name}:#{port}"
    begin
      loop do
        sleep 0.1
        if client.closed?
          raise RuntimeError.new
        end
        if @eval_q.length > 0
          src = @eval_q.pop
          to_write = src + "\0"
          written = 0
          while written < to_write.length
            piece = to_write[written..(to_write.length - written)]
            written += client.write(piece)
          end
          puts "POP #{name}:#{port}: #{src[0..20]}......"
        end
      end
    rescue Exception => e
      puts "Flash client #{name}:#{port} disconnected: #{e}"
    ensure
      puts "Ensuring close of #{name}:#{port}."
      client.close # close socket on error
    end
    puts "Done with #{name}:#{port}."
  end
end

socket_server = TCPServer.open(POP_SOCKET_PORT)
puts "Listening to tcp socket connections on port #{POP_SOCKET_PORT}."
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

#
#policy_xml = "<cross-domain-policy><site-control permitted-cross-domain-policies=\"master-only\"/><allow-access-from domain=\"*\" to-ports="#{POP_SOCKET_PORT}"/></cross-domain-policy>"
#policy_server = TCPServer.open(POLICY_SOCKET_PORT)
#puts "Listening to policy connections on port #{POLICY_SOCKET_PORT}."
#Thread.start do 
#  loop do
#    begin
#      client = policy_server.accept_nonblock
#      client.write(policy_xml)
#      puts "Wrote policy xml to client."
#      client.close
#    rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
#      IO.select([socket_server])
#      retry
#    end
#  end
#end
#

puts "Listening to http connections on port #{PUSH_HTTP_PORT}."
http_server.start


