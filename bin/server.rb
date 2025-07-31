# frozen_string_literal: true

require 'webrick'

root = File.expand_path './public'
server = WEBrick::HTTPServer.new(Port: 3000, DocumentRoot: root)

server.mount_proc '/' do |req, res|
  res['Set-Cookie'] = 'session_id=abc123; Path=/; Max-Age=3600; Secure; HttpOnly'

  WEBrick::HTTPServlet::FileHandler.new(server, root).do_GET(req, res)
end

# Permite parar o servidor com Ctrl+C no terminal
trap('INT') { server.shutdown }

puts 'Server listening on http://localhost:3000'
server.start
