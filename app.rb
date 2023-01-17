require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'

enable :sessions

before do 
    @db = SQLite3::Database.new('db/project.db')
end 

get('/') do
    slim(:frontpage)
end 

get('/login') do 
    slim(:"users/login")
end 

