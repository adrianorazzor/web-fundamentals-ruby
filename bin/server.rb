# frozen_string_literal: true

require 'webrick'
require 'sqlite3'
require 'json'
require 'bcrypt'
require 'securerandom'

SESSIONS = {}

DB = SQLite3::Database.new 'database.db'
DB.results_as_hash = true
DB.execute <<~SQL
    CREATE TABLE IF NOT EXISTS visits (
      id INTEGER PRIMARY KEY,
      path TEXT,
      created_at DATETIME
  );
SQL

DB.execute <<~SQL
  CREATE TABLE IF NOT EXISTS users (
      username TEXT PRIMARY KEY,
      password_digest TEXT,
      role TEXT
  )
SQL

admin_pass_digest = BCrypt::Password.create('adminpass', {})
DB.execute('INSERT OR IGNORE INTO USERS (username, password_digest, role) VALUES (?, ?, ?)',
           ['admin', admin_pass_digest, 'admin'])

root = File.expand_path './public'
server = WEBrick::HTTPServer.new(Port: 3000, DocumentRoot: root)

server.mount_proc '/' do |req, res|
  res['Set-Cookie'] = 'session_id=abc123; Path=/; Max-Age=3600; Secure; HttpOnly'

  WEBrick::HTTPServlet::FileHandler.new(server, root).do_GET(req, res)
end

server.mount_proc '/login' do |req, res|
  if req.request_method == 'POST'
    body = JSON.parse(req.body)
    user = DB.execute('SELECT * FROM users WHERE username = ?', body['username']).first

    if user && BCrypt::Password.new(user['password_digest']) == body['password']
      session_id = SecureRandom.uuid
      SESSIONS[session_id] = { username: user['username'], role: user['role'] }

      cookie = WEBrick::Cookie.new('session_id', session_id)
      cookie.path = '/'
      res.cookies << cookie
      res.status = 200
      res.body = { message: 'Login bem-sucedido' }.to_json
    else
      res.status = 401
      res.body = { message: 'Usuario ou senha invalidos' }.to_json
    end
  else
    res.set_redirect(WEBrick::HTTPStatus::Found, '/login.html')
  end
end

server.mount_proc '/admin' do |req, res|
  session_id_cookie = req.cookies.find { |c| c.name == 'session_id' }
  session = SESSIONS[session_id_cookie&.value]

  if session && session[:role] == 'admin'
    res.status = 200
    res.body = "Bem vindo a area de admin, #{session[:username]}"
  else
    res.status = 403
    res.body = 'Acesso negado.'
  end
end

server.mount_proc '/track' do |req, res|
  if req.request_method == 'POST'
    body = JSON.parse(req.body)
    path = body['path']

    begin
      DB.transaction
      DB.execute('INSERT INTO visits (path, created_at) VALUES (?, ?)', [path, Time.now.to_s])
      DB.commit
      res.status = 201
      res.body = { message: "Visit tracked for path: #{path}" }.to_json
    rescue SQLite3::Exception => e
      DB.rollback
      res.status = 500
      res.body = { error: "Database transaction failed: #{e.message}" }.to_json
    end

  elsif req.request_method == 'GET'
    visits = DB.execute('SELECT path, created_at FROM visits ORDER BY created_at DESC LIMIT 10')
    res.status = 200
    res.body = visits.to_json
  end
end

# Permite parar o servidor com Ctrl+C no terminal
trap('INT') { server.shutdown }

puts 'Server listening on http://localhost:3000'
server.start
