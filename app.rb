require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'
require_relative './model.rb'
# require 'byebug'


enable :sessions

configure do
    # set :show_exceptions, false
    set :static_cache_control, [:no_store, :max_age => 0] #uppdatera css, statiska dokument
end
def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true 
    return db
end 

before do 
    @db = connect_to_db('db/project.db')
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
    result = @db.execute("SELECT * FROM posts ORDER BY id DESC") 
    chosen_categories = []
    #gör nedan till en funktion!
    categories = @db.execute("SELECT name FROM categories")
    categories.map! do |hash|
        hash["name"]
    end 
    slim(:"posts/index", locals: {posts: result, logged_in: @logged_in, user_id: @user_id, chosen_categories: chosen_categories, categories: categories})
end 

get('/sort') do 
    categories = @db.execute("SELECT name FROM categories")
    categories.map! do |hash|
        hash["name"]
    end 
    chosen_categories = params[:categories]
    categories_id = []
    result = []
    posts_id = []
    if chosen_categories != nil
        chosen_categories.each do |category|
            category_id = @db.execute("SELECT id FROM categories WHERE name = ?", category).first["id"]
            categories_id << category_id
            post_id = @db.execute("SELECT post_id FROM posts_categories WHERE category_id = ?", category_id)
            if post_id != nil
                posts_id += post_id
            end 
        end  
        posts_id.uniq!
        posts_id.each do |hash|
            result << @db.execute("SELECT * FROM posts WHERE id = ?", hash["post_id"]).first
        end
    end 
    slim(:"posts/index", locals: {posts: result, logged_in: @logged_in, user_id: @user_id, chosen_categories: chosen_categories, categories: categories})
end 

get('/posts/:id/user_posts') do 
    id = Integer(params[:id])
    result = @db.execute("SELECT * FROM posts WHERE user_id = ? ORDER BY id DESC", id)
    if id != @user_id  
        name = @db.execute("SELECT * FROM users WHERE id = ?", id).first
        username = name["username"]
    end 
    slim(:"posts/user_posts", locals: {posts: result, username: username, user_id: @user_id, id: id})
end 

get('/posts/:id/user_comments') do 
    id = Integer(params[:id])
    result = @db.execute("SELECT * FROM comments WHERE user_id = ? ORDER BY id DESC", id)
    slim(:"posts/user_comments", locals: {comments: result, id: id, user_id: @user_id})
end 

get('/posts/new') do 
    slim(:"posts/new", locals: {id: @user_id})
end 

post('/posts') do 
    content = params[:content]
    header = params[:header]
    categories = params[:categories]
    @db.execute("INSERT INTO posts (header, content, user_id) VALUES (?,?,?)", header, content, @user_id)
    post_id = @db.execute("SELECT last_insert_rowid()").first["last_insert_rowid()"]
    if categories != nil
        categories.each do |category|
            category_id = @db.execute("SELECT id FROM categories WHERE name = ?", category).first["id"]
            @db.execute("INSERT INTO posts_categories (post_id, category_id) VALUES (?,?)", post_id, category_id)
        end 
    end 
    redirect('/')
end 

post('/posts/:id/delete') do 
    id = params[:id]
    @db.execute("DELETE FROM posts WHERE id = ?", id)
    @db.execute("DELETE FROM posts_categories WHERE post_id = ?", id)
    @db.execute("DELETE FROM saved_posts WHERE post_id = ?", id)
    redirect('/')
end 

get('/posts/:id/edit') do 
    id = params[:id]
    categories = @db.execute("SELECT name FROM categories")
    categories.map! do |hash|
        hash["name"]
    end 
    result = @db.execute("SELECT * FROM posts WHERE id = ?", id).first
    slim(:"posts/edit", locals: {result: result, categories: categories})
end 

post('/posts/:id/update') do 
    id = Integer(params[:id])
    p "this is id #{id}"
    header = params[:header]
    content = params[:content]
    categories = params[:categories]
    @db.execute("UPDATE posts SET header=?, content=? WHERE id= ?", header, content, id)
    p id
    @db.execute("DELETE FROM posts_categories WHERE post_id = ?", id)
    if categories != nil
        p categories
        categories.each do |category|
            category_id = @db.execute("SELECT * FROM categories WHERE name = ?", category).first
            p "this is category#{category_id}"
            cat_id = category_id["id"]
            p cat_id
            @db.execute("INSERT INTO posts_categories (post_id, category_id) VALUES (?,?)", id, cat_id)
        end 
    end 
    redirect('/')
end 

get('/posts/:id') do 
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
    comments = @db.execute("SELECT * FROM comments WHERE post_id = ? ORDER BY id DESC", id) 
    categories_id = @db.execute("SELECT category_id FROM posts_categories WHERE post_id = ?", id)
    categories_id.map! do |hash|
        hash["category_id"]
    end 
    categories = []
    categories_id.each do |category_id|
        categories << @db.execute("SELECT name FROM categories WHERE id = ?", category_id).first #låt det vara allt i kategory så att det är en länk 
    end 
    p "this is categories#{categories}"
    #@db.execute("SELECT id FROM posts INNER JOIN categories ON posts.id = categories.id")
    slim(:"posts/show", locals: {result: result, user_id: @user_id, post_user_id: post_user_id, user_type: user_type, logged_in: @logged_in, username: username, comments: comments, my_username: @username, categories: categories})
end 

post('/posts/:id/save') do
    id = Integer(params[:id]) 
    frecuency = @db.execute("SELECT id FROM saved_posts WHERE post_id = ? AND user_id = ?", id, @user_id)
    if frecuency.length == 0 
        @db.execute("INSERT INTO saved_posts (post_id, user_id) VALUES (?,?)", id, @user_id)
    end 
    redirect("/posts/#{id}")
end 

get('/posts/:id/user_saved_posts') do
    id = Integer(params[:id])
    posts_id = @db.execute("SELECT post_id FROM saved_posts WHERE user_id = ?", id)
    posts_id.map! do |hash|
        hash["post_id"]
    end 
    posts = []
    posts_id.each do |post_id|
        posts << @db.execute("SELECT * FROM posts WHERE id = ?", post_id)
    end 
    posts.flatten!

    if id != @user_id  
        name = @db.execute("SELECT * FROM users WHERE id = ?", id).first
        username = name["username"]
    end 
    slim(:"posts/user_saved_posts", locals: {posts: posts, username: username, user_id: @user_id, id: id})
end 

post('/saved_posts/:user_id/delete/:id') do
    id = Integer(params[:id]) 
    user_id = Integer(params[:user_id])
    @db.execute("DELETE FROM saved_posts WHERE post_id = ? AND user_id = ?", id, user_id)
    redirect("/posts/#{user_id}/user_saved_posts")
end 

post('/posts/:post_id/comments/new') do 
    post_id = params[:post_id]
    content = params[:content]
    @db.execute("INSERT INTO comments (content, user_id, post_id, username) VALUES (?,?,?,?)", content, @user_id, post_id, @username)
    redirect("/posts/#{post_id}")
end 

post('/posts/:id/comment/delete') do 
    id = params[:id] 
    @db.execute("DELETE FROM comments WHERE id = ?", id)
    redirect("/posts/#{@user_id}/user_comments")
end 

#vän
#inner join
#ska kunna se vilka som sparat denna post 

#fråga hur filerna ska ligga - typ comments och saved posts 