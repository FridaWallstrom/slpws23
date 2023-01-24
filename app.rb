require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'

enable :sessions

before do 
    @db = SQLite3::Database.new('db/project.db')
    #@user_id = session[:id]
end 

#get('/login') do 
#    slim(:"users/login")
#end 

#get('/') do
#    slim(:frontpage)
#end 

get('/posts') do 
    @db.results_as_hash = true 
    result = @db.execute("SELECT * FROM posts")
    slim(:"posts/index", locals: {posts: result})
end 

get('/posts/new') do 
    slim(:"posts/new")
end 

post('/posts/new') do 
    content = params[:content]
    @db.execute("INSERT INTO posts (content) VALUES (?)", content)
    redirect('/posts')
end 

post('/posts/:id/delete') do 
    id = params[:id]
    @db.execute("DELETE FROM posts WHERE id = ?", id)
    redirect('/posts')
end 

post('/posts/:id/update') do 
    id = params[:id]
    content = params[:content]
    @db.execute("UPDATE posts SET content=? WHERE id= ?", content, id)
    redirect('/posts')
end 

get('/posts/:id/edit') do 
    @db.results_as_hash = true 
    id = params[:id]
    result = @db.execute("SELECT * FROM posts WHERE id = ?", id).first
    slim(:"posts/edit", locals: {result: result})
end 

