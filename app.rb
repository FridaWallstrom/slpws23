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
#borde göra till klasser??? 

before do 
    #@db = connect_to_db('db/project.db')
    cache_control :no_store, :max_age => 0 #för routes
    @user_id = session[:id]
    @logged_in = session[:login] 
    @username = session[:username]
end 

get('/login') do 
    slim(:"users/login")
end 

#kolla hur ofta testar lösenord, efter 3 gånger (cooldown!!!)
post('/login') do 
    username = params[:username]
    password = params[:password]
    #fixa nedan!!! 
    #times = []
    #time = Time.now.to_i
    #times << time
    #if (times[1] - times[0]) <= 100
    #    notice = "Too many tries/too quick!"
    #    slim(:"error", locals: {notice: notice})
    #end 
    #result = @db.execute("SELECT * FROM users WHERE username = ?", username).first
    result = select_requirement("*", "users", ["username"], [username]).first
    if result == nil
        notice = "Wrong password or username!"
        slim(:"error", locals: {notice: notice})
    end 
    if BCrypt::Password.new(result["password"]) == password
        session[:id] = Integer(result["id"])
        session[:username] = result["username"]
        session[:login] = true 
        redirect('/')
    else 
        notice = "Wrong password or username!"
        slim(:"error", locals: {notice: notice})    
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
    #result = @db.execute("SELECT * FROM users WHERE id = ?", id).first
    username = select_requirement("*", "users", ["id"], [id]).first["username"]
    slim(:"users/profile", locals: {username: username, id: id, user_id: @user_id})
end 

post('/register') do 
    username = params[:username]
    p username.length
    if username.length < 3 #funkar ej???
        notice = "Username is too short, needs to contain at least 3 characters" 
        slim(:"error", locals: {notice: notice})
    end 
    password = params[:password]
    password_confirm = params[:password_confirm]
    user_type = params[:user_type]
    #funktion
    #result = @db.execute("SELECT * FROM users WHERE username = ?", username).first
    result = select_requirement("*", "users", ["username"], [username]).first
    if result
        notice = "Username is already in use, try a new one!" 
        slim(:"error", locals: {notice: notice})
    elsif password == password_confirm
        password_digest = BCrypt::Password.create(password)
        #@db.execute("INSERT INTO users (username, password, user_type) VALUES (?,?,?)", username, password_digest, user_type)
        insert_into("users", ["username", "password", "user_type"], [username, password_digest, user_type])
        redirect("/")
    else 
        notice = "Password does not match!" 
        slim(:"error", locals: {notice: notice})
    end 
end 

get('/') do 
    #result = @db.execute("SELECT * FROM posts ORDER BY id DESC") 
    result = select_descending("*", "posts", "id")
    chosen_categories = []
    categories = categories_in_db()
    slim(:"posts/index", locals: {posts: result, logged_in: @logged_in, user_id: @user_id, chosen_categories: chosen_categories, categories: categories})
end 

get('/sort') do 
    categories = categories_in_db()
    chosen_categories = params[:categories]
    categories_id = []
    result = []
    posts_id = []
    if chosen_categories != nil
        chosen_categories.each do |category|
            #category_id = @db.execute("SELECT id FROM categories WHERE name = ?", category).first["id"]
            category_id = select_requirement("id", "categories", ["name"], [category]).first["id"]
            categories_id << category_id
            #post_id = @db.execute("SELECT post_id FROM posts_categories WHERE category_id = ?", category_id)
            post_id = select_requirement("post_id", "posts_categories", ["category_id"], [category_id])
            if post_id != nil
                posts_id += post_id
            end 
        end  
        posts_id.uniq!
        posts_id.each do |hash|
            #result << @db.execute("SELECT * FROM posts WHERE id = ?", hash["post_id"]).first
            result << select_requirement("*", "posts", ["id"], [hash["post_id"]]).first
        end
    end 
    slim(:"posts/index", locals: {posts: result, logged_in: @logged_in, user_id: @user_id, chosen_categories: chosen_categories, categories: categories})
end 

get('/posts/:id/user_posts') do 
    id = Integer(params[:id])
    #result = @db.execute("SELECT * FROM posts WHERE user_id = ? ORDER BY id DESC", id)
    result = select_one_requirement_descending("*", "posts", "user_id", "id", id)
    if id != @user_id  
        #username = @db.execute("SELECT * FROM users WHERE id = ?", id).first["username"]
        username = select_requirement("*", "users", ["id"], [id]).first["username"]
    end 
    slim(:"posts/user_posts", locals: {posts: result, username: username, user_id: @user_id, id: id})
end 

get('/posts/:id/user_comments') do 
    id = Integer(params[:id])
    #result = @db.execute("SELECT * FROM comments WHERE user_id = ? ORDER BY id DESC", id)
    result = select_one_requirement_descending("*", "comments", "user_id", "id", id)
    slim(:"posts/user_comments", locals: {comments: result, id: id, user_id: @user_id})
end 

get('/posts/new') do 
    slim(:"posts/new", locals: {id: @user_id})
end 

post('/posts') do #new
    content = params[:content]
    header = params[:header]
    categories = params[:categories]
    #@db.execute("INSERT INTO posts (header, content, user_id) VALUES (?,?,?)", header, content, @user_id)
    insert_into("posts", ["header", "content", "user_id"], [header, content, @user_id])
    #post_id = @db.execute("SELECT last_insert_rowid()").first["last_insert_rowid()"]
    post_id = last_insert_rowid.first["last_insert_rowid()"]
    if categories != nil
        categories.each do |category|
            #category_id = @db.execute("SELECT id FROM categories WHERE name = ?", category).first["id"]
            category_id = select_requirement("id", "categories", ["name"], [category]).first["id"]
            #@db.execute("INSERT INTO posts_categories (post_id, category_id) VALUES (?,?)", post_id, category_id)
            insert_into("posts_categories", ["post_id", "category_id"], [post_id, category_id])
        end 
    end 
    redirect('/')
end 

post('/posts/:id/delete') do 
    id = params[:id]
    #@db.execute("DELETE FROM posts WHERE id = ?", id)
    delete("posts", ["id"], [id])
    #@db.execute("DELETE FROM posts_categories WHERE post_id = ?", id)
    delete("posts_categories", ["post_id"], [id])
    #@db.execute("DELETE FROM saved_posts WHERE post_id = ?", id)
    delete("saved_posts", ["post_id"], [id])
    redirect('/')
end 

get('/posts/:id/edit') do 
    id = params[:id]
    categories = categories_in_db()
    #result = @db.execute("SELECT * FROM posts WHERE id = ?", id).first
    result = select_requirement("*", "posts", ["id"], [id]).first
    slim(:"posts/edit", locals: {result: result, categories: categories})
end 

post('/posts/:id/update') do 
    id = Integer(params[:id])
    header = params[:header]
    content = params[:content]
    categories = params[:categories]
    #@db.execute("UPDATE posts SET header=?, content=? WHERE id= ?", header, content, id)
    update_two_columns("posts", ["header", "content"], "id", [header, content, id])
    #@db.execute("DELETE FROM posts_categories WHERE post_id = ?", id)
    delete("posts_categories", ["post_id"], [id])
    if categories != nil
        categories.each do |category|
            #category_id = @db.execute("SELECT * FROM categories WHERE name = ?", category).first["id"]
            category_id = select_requirement("*", "categories", ["name"], [category]).first["id"]
            #@db.execute("INSERT INTO posts_categories (post_id, category_id) VALUES (?,?)", id, category_id)
            insert_into("posts_categories", ["post_id", "category_id"], [id, category_id])
        end 
    end 
    redirect('/')
end 

get('/posts/:id') do #show 
    id = params[:id]
    if !@logged_in
        user_type = 1
    else 
        #user_type = @db.execute("SELECT * FROM users WHERE id = ?", @user_id).first["user_type"]
        user_type = select_requirement("*", "users", ["id"], [@user_id]).first["user_type"]
    end 
    #result = @db.execute("SELECT * FROM posts WHERE id = ?", id).first
    result = select_requirement("*", "posts", ["id"], [id]).first
    post_user_id = result["user_id"]
    #username = @db.execute("SELECT * FROM users WHERE id = ?", post_user_id).first["username"]
    username = select_requirement("*", "users", ["id"], [post_user_id]).first["username"]
    #comments = @db.execute("SELECT * FROM comments WHERE post_id = ? ORDER BY id DESC", id) 
    comments = select_one_requirement_descending("*", "comments", "post_id", "id", id)
    #categories_id = @db.execute("SELECT category_id FROM posts_categories WHERE post_id = ?", id)
    categories_id = select_requirement("category_id", "posts_categories", ["post_id"], [id])
    categories_id.map! do |hash|
        hash["category_id"]
    end 
    categories = []
    categories_id.each do |category_id|
        #categories << @db.execute("SELECT name FROM categories WHERE id = ?", category_id).first
        categories << select_requirement("name", "categories", ["id"], [category_id]).first
    end 
    #people who saved the post: 
    #här behövs innerjoin
    saved_post_users_id = @db.execute("SELECT user_id FROM saved_posts WHERE post_id = ?", id)
    saved_post_users_id.map! do |hash|
        hash["user_id"]
    end 
    #@db.execute("SELECT id FROM posts INNER JOIN categories ON posts.id = categories.id")
    # x = @db.execute("SELECT id FROM posts INNER JOIN categories ON posts.id = categories.id")
    # @db.execute("INSERT INTO posts_categories (post, category) VALUES (?,?)", x["post"], x["category"])
    slim(:"posts/show", locals: {result: result, user_id: @user_id, post_user_id: post_user_id, user_type: user_type, logged_in: @logged_in, username: username, comments: comments, my_username: @username, categories: categories})
end 

post('/posts/:id/save') do
    id = Integer(params[:id]) 
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #frecuency = @db.execute("SELECT id FROM saved_posts WHERE post_id = ? AND user_id = ?", id, @user_id)
    frecuency = select_requirement("id", "saved_posts", ["post_id", "user_id"], [id, @user_id])
    if frecuency.length == 0 
        #@db.execute("INSERT INTO saved_posts (post_id, user_id) VALUES (?,?)", id, @user_id)
        insert_into("saved_posts", ["post_id", "user_id"], [id, @user_id])
    end 
    redirect("/posts/#{id}")
end 

get('/posts/:id/user_saved_posts') do
    id = Integer(params[:id])
    #posts_id = @db.execute("SELECT post_id FROM saved_posts WHERE user_id = ?", id)
    posts_id = select_requirement("post_id", "saved_posts", ["user_id"], [id])
    posts_id.map! do |hash|
        hash["post_id"]
    end 
    posts = []
    posts_id.each do |post_id|
        #posts << @db.execute("SELECT * FROM posts WHERE id = ?", post_id)
        posts << select_requirement("*", "posts", ["id"], [post_id])
    end 
    posts.flatten!

    if id != @user_id  
        #username = @db.execute("SELECT * FROM users WHERE id = ?", id).first["username"]
        username = select_requirement("*", "users", ["id"], [id]).first["username"]
    end 
    slim(:"posts/user_saved_posts", locals: {posts: posts, username: username, user_id: @user_id, id: id})
end 

post('/saved_posts/:user_id/delete/:id') do
    id = Integer(params[:id]) 
    user_id = Integer(params[:user_id])
    #@db.execute("DELETE FROM saved_posts WHERE post_id = ? AND user_id = ?", id, user_id)
    delete("saved_posts", ["post_id", "user_id"], [id, user_id])
    redirect("/posts/#{user_id}/user_saved_posts")
end 

post('/posts/:post_id/comments/new') do 
    post_id = params[:post_id]
    content = params[:content]
    #@db.execute("INSERT INTO comments (content, user_id, post_id, username) VALUES (?,?,?,?)", content, @user_id, post_id, @username)
    insert_into("comments", ["content", "user_id", "post_id", "username"], [content, @user_id, post_id, @username])
    redirect("/posts/#{post_id}")
end 

post('/posts/:id/comment/delete') do 
    id = params[:id] 
    #@db.execute("DELETE FROM comments WHERE id = ?", id)
    delete("comments", ["id"], [id])
    redirect("/posts/#{@user_id}/user_comments")
end 
