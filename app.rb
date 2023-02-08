require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'

enable :sessions

configure do
    # set :show_exceptions, false
    set :static_cache_control, [:no_store, :max_age => 0] #uppdatera css, statiska dokument
end

before do 
    @db = SQLite3::Database.new('db/project.db')
    cache_control :no_store, :max_age => 0 #för routes
    @user_id = session[:id]
    @logged_in = session[:login] 
    @username = session[:username]
end 

get('/login') do 
    slim(:"users/login")
end 

#finns någon bugg i login/register, fixa! result => nil
post('/login') do 
    username = params[:username]
    password = params[:password]
    p username 
    p password 
    @db.results_as_hash = true 
    result = @db.execute("SELECT * FROM users WHERE username = ?", username).first
    if result == nil
        slim(:"error")
    end 
    p result 
    p BCrypt::Password.new(result["password"])
    if BCrypt::Password.new(result["password"]) == password
        session[:id] = Integer(result["id"])
        session[:username] = result["username"]
        session[:login] = true 
        redirect('/')
    else 
        slim(:"error")
    end 
end 

post('/logout') do
    session[:login] = false 
    session[:id] = nil
    redirect('/')
end 

get('/register') do 
    slim(:"users/register")
end 

get('/user/:id/profile') do 
    @db.results_as_hash = true
    id = Integer(params[:id])
    result = @db.execute("SELECT * FROM users WHERE id = ?", id).first
    username = result["username"]
    slim(:"users/profile", locals: {username: username, id: id, user_id: @user_id})
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
    slim(:"posts/index", locals: {posts: result, logged_in: @logged_in, user_id: @user_id})
end 

get('/posts/:id/user_post') do 
    @db.results_as_hash = true 
    id = Integer(params[:id])
    result = @db.execute("SELECT * FROM posts WHERE user_id = ? ORDER BY id DESC", id)
    if id != @user_id  
        name = @db.execute("SELECT * FROM users WHERE id = ?", id).first
        username = name["username"]
    end 
    slim(:"posts/user_post", locals: {posts: result, username: username, user_id: @user_id, id: id})
end 

get('/posts/:id/user_comments') do 
    @db.results_as_hash = true 
    id = Integer(params[:id])
    result = @db.execute("SELECT * FROM comments WHERE user_id = ? ORDER BY id DESC", id)
    slim(:"posts/user_comments", locals: {comments: result, id: id, user_id: @user_id})
end 

get('/posts/new') do 
    slim(:"posts/new", locals: {id: @user_id})
end 

post('/posts/new') do 
    content = params[:content]
    header = params[:header]
    @db.execute("INSERT INTO posts (header, content, user_id) VALUES (?,?,?)", header, content, @user_id)
    redirect('/')
end 

post('/posts/:id/delete') do 
    id = params[:id]
    @db.execute("DELETE FROM posts WHERE id = ?", id)
    redirect('/')
end 

###

#get('/posts/:id/save') do 
#    @db.results_as_hash = true 
#    id = Integer(params(:id))
    #id = postens id 
    #insert into saved posts user id och post id 
#    result = @db.execute("SELECT posts.id, users.id FROM posts INNER JOIN users ON posts.id = users.id")
#    slim(:"posts/save", locals: {posts: result})
#end 
#
#post('/posts/:id/save') do
#    id = params[:id]
# insert into post.id 
#    result = @db.execute("SELECT posts.id, users.id FROM posts INNER JOIN users ON posts.id = users.id WHERE id = ?", @user_id)
#    @db.execute("")
#end 

#post('/posts/category') do 
##varje post ska ha en kategori, ska kunna sortera efter kategori 
#end 

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
    ut = @db.execute("SELECT * FROM users WHERE id = ?", @user_id).first
    if !@logged_in
        user_type = 1
    else 
        user_type = Integer(ut["user_type"])
    end 
    result = @db.execute("SELECT * FROM posts WHERE id = ?", id).first
    post_user_id = Integer(result["user_id"])
    name = @db.execute("SELECT * FROM users WHERE id = ?", post_user_id).first
    username = name["username"]
    post_id = @db.execute("SELECT * FROM posts WHERE user_id = ?", post_user_id).first
    comments = @db.execute("SELECT * FROM comments WHERE post_id = ? ORDER BY id DESC", id) 
    slim(:"posts/show", locals: {result: result, user_id: @user_id, post_user_id: post_user_id, user_type: user_type, logged_in: @logged_in, username: username, comments: comments, my_username: @username})
end 

post('/posts/:post_id/comments/new') do 
    post_id = params[:post_id]
    content = params[:content]
    @db.execute("INSERT INTO comments (content, user_id, post_id, username) VALUES (?,?,?,?)", content, @user_id, post_id, @username)
    redirect("/posts/#{post_id}/show")
end 

post('/posts/:id/comment/delete') do 
    id = params[:id] 
    @db.execute("DELETE FROM comments WHERE id = ?", id)
    redirect("/posts/#{@user_id}/user_comments")
end 

#lägg till så man kan se vem som postat 
#kategori, vän, spara posts, 
#ändra, ta bort kommentar 
#skicka meddelanden till vänner 
#chatt 