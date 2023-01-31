require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'

enable :sessions

configure do
    # set :show_exceptions, false
    set :static_cache_control, [:no_store, :max_age => 0] #css, statiska dokument
end

before do 
    @db = SQLite3::Database.new('db/project.db')
    cache_control :no_store, :max_age => 0 #för routes
    @user_id = 0
    #@logged_in = true 
end 

get('/login') do 
    slim(:"users/login")
end 

get('/register') do 
    slim(:"users/register")
end 

post('/register') do 
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    user_type = params[:user_type]
    @db.results_as_hash = true 
    result = @db.execute("SELECT * FROM users WHERE username = ?",username).first
    if result 
        slim(:"error")
    elsif password == password_confirm
        password_digest = BCrypt::Password.create(password)
        @db.execute("INSERT INTO users (username, password, user_type) VALUES (?,?,?)", username, password_digest, user_type)
        redirect("/")
    else 
        slim(:"error")
    end 
end 

get('/') do 
    @db.results_as_hash = true 
    result = @db.execute("SELECT * FROM posts ORDER BY id DESC")
    p "this is posts#{result}"
    slim(:"posts/index", locals: {posts: result})
end 

get('/user_post') do 
    @db.results_as_hash = true 
    result = @db.execute("SELECT * FROM posts WHERE user_id = ? ORDER BY id DESC", @user_id)
    p "this is posts#{result}"
    slim(:"posts/user_post", locals: {posts: result})
end 

get('/posts/new') do 
    slim(:"posts/new", locals: {id: @user_id})
end 

post('/posts/new') do 
    content = params[:content]
    header = params[:header]
    p "This is the user's id: #{@user_id}"
    @db.execute("INSERT INTO posts (header, content, user_id) VALUES (?,?,?)", header, content, @user_id)
    redirect('/')
end 

post('/posts/:id/delete') do 
    id = params[:id]
    @db.execute("DELETE FROM posts WHERE id = ?", id)
    redirect('/')
end 

###

get('/saved_post') do 
    @db.results_as_hash = true 
    result = @db.execute("SELECT posts.id, users.id FROM posts INNER JOIN users ON posts.id = users.id")
    #blir detta ett nytt table som jag kan ta ifrån? 
    slim(:"posts/saved_post", locals: {posts: result})
end 

post('/posts/:id/save') do
    id = params[:id]
    result = @db.execute("SELECT posts.id, users.id FROM posts INNER JOIN users ON posts.id = users.id WHERE id = ?", @user_id)
    @db.execute("")
end 

post('/posts/category') do 
#varje post ska ha en kategori, ska kunna sortera efter kategori 
end 

post('/posts/:id/comment') do 
#kopplad till user 
end 

###

post('/posts/:id/update') do 
    id = params[:id]
    header = params[:header]
    content = params[:content]
    @db.execute("UPDATE posts SET header=?, content=? WHERE id= ?", header, content, id)
    redirect('/')
end 

get('/posts/:id/edit') do 
    @db.results_as_hash = true 
    id = params[:id]
    result = @db.execute("SELECT * FROM posts WHERE id = ?", id).first
    slim(:"posts/edit", locals: {result: result})
end 

get('/posts/:id/show') do 
    @db.results_as_hash = true 
    id = params[:id]
    result = @db.execute("SELECT * FROM posts WHERE id = ?", id).first
    slim(:"posts/show", locals: {result: result})
end 

