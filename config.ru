require 'rack'
require 'rack/cors'
require_relative 'bin/api/books_controller'

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: %i[get post put delete options]
  end
end

app = Rack::Builder.new do
  map '/api/books' do
    run BooksController.new
  end
end

run app
