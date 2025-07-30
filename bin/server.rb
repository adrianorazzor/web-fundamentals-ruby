# frozen_string_literal: true

require 'webrick'

# Cria um servidor HTTP simples na porta 3000

server = WEBrick::HTTPServer.new(Port: 3000)

# Define uma resposta para a rota raiz "/"
server.mount_proc '/' do |_req, res|
  res.status = 200
  res['Content-Type'] = 'text/plain'
  res.body = 'Hello, World!'
end

# Permite parar o servidor com Ctrl+C no terminal
trap('INT') { server.shutdown }

puts 'Servidor rodando em http://localhost:3000'
server.start
