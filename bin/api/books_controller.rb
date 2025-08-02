require 'json'
require 'sqlite3'

DB = SQLite3::Database.new 'database.db'
DB.execute 'CREATE TABLE IF NOT EXISTS books (id INTEGER PRIMARY KEY, title TEXT, author TEXT);'

class BooksController
  def call(env)
    req = Rack::Request.new(env)
    case req.path_info
    when ''
      handle_index_and_create(req)
    when %r{/\d+}
      id = req.path_info.split('/').last.to_i
      handle_show_update_delete(req, id)
    else
      [404, {}, ['Rota nao encontrada']]

    end
  end
end

def handle_index_and_create(req)
  case req.request_method
  when 'GET'
    books = DB.execute('SELECT * FROM books')
    [200, { 'Content-Type' => 'application/json' }, [books.to_json]]
  else
    data = JSON.parse(req.body.read)
    DB.execute('INSERT INTO books (title, author) VALUES (?, ?)', [data['title'], data['author']])
    [201, { 'Content-Type' => 'application/json' }, [{ message: 'Livro criado' }.to_json]]
  end
end

def handle_show_update_delete(req, id)
  case req.request_method
  when 'GET'
    book = DB.execute('SELECT * FROM books WHERE id = ?', id).first
    [200, { 'Content-Type' => 'application/json' }, book.to_json]
  when 'PUT'
    data = JSON.parse(req.body.read)
    DB.execute('UPDATE books SET title = ?, author = ? WHERE id = ?', [data['title'], data['author'], id])
  when 'DELETE'
    DB.execute('DELETE FROM books HWERE id = ?', id)
    [204, {}, []]
  else
    [405, {}, ['Method Not Supported']]
  end
end
