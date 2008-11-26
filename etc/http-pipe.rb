require 'webrick'
require 'net/http'
require 'fileutils'
require 'cgi'
include WEBrick

# Start a simple http server that listens to 'push' and 'pop' requests.
#  'push' adds a string to the eval queue
#  'pop' pops a string from the eval queue
# 
# This server is designed for use with the function las3r-eval-last-sexp
# in las3r-mode.el


@port = 9876
@eval_q = []

s = HTTPServer.new(
                   :Port => @port,
                   :Logger => Log.new(nil, BasicLog::WARN),
                   :AccessLog => []
                   )

s.mount_proc("/push"){ |req, res|
  params = CGI.parse(req.body)
  if params["src"]
    src = params["src"][0]
    @eval_q.push(src);
  end
  res['Content-Type'] = "text/plain"
}

s.mount_proc("/pop"){ |req, res|
  next_src = @eval_q.pop
  if next_src
    puts "."
    res.body = next_src
    res['Content-Type'] = "text/plain"
  else
    res.status = 404
  end
}


trap("INT"){
  s.shutdown 
}

s.start
