require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'
require_relative './model.rb'

enable :sessions

module UserType
    ADMIN = 0
    DEFAULT = 1
end

configure do
    set :static_cache_control, [:no_store, :max_age => 0] #uppdatera css, statiska dokument
end

before do 
    cache_control :no_store, :max_age => 0 #för routes
    @user_id = session[:id]
    @logged_in = session[:login] 
    @username = session[:username]
    @db = Database.new 
end 

get('/login') do 
    slim(:"users/login")
end 

post('/login') do 
    username = params[:username]
    password = params[:password]
    user_id = @db.get_user_id_with_username(username)
    result = @db.get_user_with_id(user_id)
    if result == nil
        sleep(5)    
        notice = "Wrong password or username!"
        return slim(:"error", locals: {notice: notice})
    end 
    if BCrypt::Password.new(result["password"]) == password
        session[:id] = Integer(result["id"])
        session[:username] = result["username"]
        session[:login] = true 
        redirect('/')
    else 
        sleep(5)
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
    username = @db.get_user_with_id(id)['username']
    slim(:"users/profile", locals: {username: username, id: id, user_id: @user_id})
end 

post('/register') do 
    username = params[:username]
    if username.length < 3 
        notice = "Username is too short, needs to contain at least 3 characters" 
        return slim(:"error", locals: {notice: notice})
    end 
    password = params[:password]
    password_confirm = params[:password_confirm]
    user_type = params[:user_type]
    user_id = @db.get_user_id_with_username(username)
    if user_id
        notice = "Username is already in use, try a new one!" 
        slim(:"error", locals: {notice: notice})
    elsif password == password_confirm
        password_digest = BCrypt::Password.create(password)
        @db.add_user(username, password_digest, user_type)
        redirect("/")
    else 
        notice = "Password does not match!" 
        slim(:"error", locals: {notice: notice})
    end 
end 

get('/') do 
    result = @db.get_posts()
    chosen_categories = []
    categories = @db.get_categories()
    slim(:"posts/index", locals: {posts: result, logged_in: @logged_in, user_id: @user_id, chosen_categories: chosen_categories, categories: categories})
end 

get('/sort') do 
    categories = @db.get_categories()
    chosen_categories = params[:categories]
    result = []
    posts_id = []
    if chosen_categories != nil
        chosen_categories.each do |category|
            category_id = @db.get_category_id_with_name(category)
            post_id = @db.get_posts_id_with_category_id(category_id)
            if post_id != nil
                posts_id += post_id
            end 
        end  
        posts_id.uniq!
        posts_id.each do |hash|
            result << @db.get_post_with_id(hash["post_id"])
        end
    end 
    slim(:"posts/index", locals: {posts: result, logged_in: @logged_in, user_id: @user_id, chosen_categories: chosen_categories, categories: categories})
end 

get('/users/:id/posts') do 
    id = Integer(params[:id])
    result = @db.get_posts_with_user_id(id).reverse
    if id != @user_id  
        username = @db.get_user_with_id(id)["username"]
    end 
    slim(:"users/posts", locals: {posts: result, username: username, user_id: @user_id, id: id})
end 

get('/users/:id/comments') do 
    id = Integer(params[:id])
    result = @db.get_comments_with_user_id(id)
    if !@logged_in
        user_type = UserType::DEFAULT
    else 
        user_type = @db.get_user_with_id(@user_id)["user_type"]
    end 
    slim(:"users/comments", locals: {comments: result, id: id, user_id: @user_id, user_type: user_type})
end 

get('/posts/new') do 
    categories = @db.get_categories()
    slim(:"posts/new", locals: {id: @user_id, categories: categories})
end 

post('/posts') do #new
    content = params[:content]
    header = params[:header]
    categories = params[:categories]
    if @logged_in
        @db.add_post(header, content, @user_id, categories)
        redirect('/')
    else 
        notice = "You have no powaa here hacker!"
        slim(:"error", locals: {notice: notice})
    end 
end 

post('/posts/:id/delete') do 
    id = Integer(params[:id])
    user_type = @db.get_user_with_id(@user_id)["user_type"]
    if user_type == UserType::DEFAULT
        if @db.get_post_with_id(id)["user_id"] != @user_id
            notice = "You have no powaa here hacker!"
            return slim(:"error", locals: {notice: notice})
        end 
    end 
    @db.delete_post(id)
    redirect('/')
end 

get('/posts/:id/edit') do 
    id = Integer(params[:id])
    categories = @db.get_categories()
    result = @db.get_post_with_id(id)
    slim(:"posts/edit", locals: {result: result, categories: categories})
end 

post('/posts/:id/update') do 
    id = Integer(params[:id])
    header = params[:header]
    content = params[:content]
    categories = params[:categories]
    user_type = @db.get_user_with_id(@user_id)["user_type"]
    if user_type == UserType::DEFAULT
        if @db.get_post_with_id(id)["user_id"] != @user_id
            notice = "You have no powaa here hacker!"
            return slim(:"error", locals: {notice: notice})
        end 
    end 
    @db.update_post(header, content, id, categories)
    redirect('/')
end 

get('/posts/:id') do #show 
    id = Integer(params[:id])
    if !@logged_in
        user_type = UserType::DEFAULT
    else 
        user_type = @db.get_user_with_id(@user_id)["user_type"]
    end 
    result = @db.get_post_with_id(id)
    post_user_id = result["user_id"]
    username = @db.get_user_with_id(post_user_id)["username"]
    comments = @db.get_comments_with_post_id(id)
    categories_id = @db.get_category_id_with_post_id(id)
    categories = []
    categories_id.each do |category_id|
        categories << @db.get_category_name_with_category_id(category_id["category_id"])
    end 

    saved_post_users = @db.get_saved_post_users_with_post_id(id)
    slim(:"posts/show", locals: {result: result, user_id: @user_id, post_user_id: post_user_id, user_type: user_type, logged_in: @logged_in, username: username, comments: comments, my_username: @username, categories: categories, saved_post_users: saved_post_users})
end 

post('/posts/:id/save') do
    id = Integer(params[:id]) 
    if @logged_in
        if !@db.post_saved_by_user?(id, @user_id)
            @db.add_saved_post(id, @user_id)
        end 
    end 
    redirect("/posts/#{id}")
end 

get('/users/:id/saved_posts') do
    id = Integer(params[:id])
    posts_id = @db.get_saved_posts_with_user_id(id)
    posts = []
    posts_id.each do |post_id|
        posts << @db.get_post_with_id(post_id["post_id"])
    end 
    if id != @user_id  
        username = @db.get_user_with_id(id)["username"]
    end 
    slim(:"users/saved_posts", locals: {posts: posts, username: username, user_id: @user_id, id: id})
end 

post('/users/:user_id/saved_posts/:id/delete') do
    id = Integer(params[:id]) 
    user_id = Integer(params[:user_id])
    if @logged_in
        if @user_id == user_id
            @db.delete_saved_post(id, user_id)
            redirect("/users/#{user_id}/saved_posts")
        end 
    else 
        notice = "You have no powaa here hacker!"
        slim(:"error", locals: {notice: notice})
    end 
end 

post('/posts/:post_id/comments') do 
    post_id = params[:post_id]
    content = params[:content]
    if @logged_in 
        @db.add_comment(content, @user_id, post_id, @username)
    end 
    redirect("/posts/#{post_id}")
end 

post('/posts/:post_id/comment/:id/delete') do 
    id = Integer(params[:id])
    user_type = @db.get_user_with_id(@user_id)["user_type"]
    user_id = @db.get_comment_with_id(id)["user_id"]
    if user_type == UserType::DEFAULT
        if @db.get_comment_with_id(id)["user_id"] != @user_id
            notice = "You have no powaa here hacker!"
            return slim(:"error", locals: {notice: notice})
        end 
    end 
    @db.delete_comment(id)
    redirect("/users/#{user_id}/comments")
end 
