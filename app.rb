require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require_relative './model.rb'
include Model 

enable :sessions

NO_ACCESS_NOTICE = "You have no powaa here, hacker!"

module UserType
    ADMIN = 0
    DEFAULT = 1
end

configure do
    set :static_cache_control, [:no_store, :max_age => 0] #uppdatera css, statiska dokument
end

before do 
    cache_control :no_store, :max_age => 0 
    @user_id = session[:id]
    @logged_in = session[:login] 
    @username = session[:username]
    @db = Database.new 
end 

# Checks if a user authorized 
#
# @param [Integer] user_type, The type of the user
# @param [Integer] current_user_id, The id of the user
# @param [Integer] needed_user_id, The id needed for permission 
#
def check_user(user_type, current_user_id, needed_user_id)
    if @logged_in
        if user_type == UserType::ADMIN
            return true 
        end 
        if needed_user_id == current_user_id
            return true 
        end
    end
    raise UnauthorizedAccess.new(NO_ACCESS_NOTICE)   
end 

# Displays the error page
#
error UnauthorizedAccess do 
    status 403
    slim(:"error", locals: {notice: env['sinatra.error'].message})
end 

# Displays login form
#
get('/login') do 
    slim(:"users/login")
end 

# Attempts login and updates the session 
#
# @param [String] username, The username 
# @param [String] password, The password 
#
# @see Model#try_login
post('/login') do 
    username = params[:username]
    password = params[:password]
    result = @db.try_login(username, password)
    session[:id] = Integer(result["id"])
    session[:username] = result["username"]
    session[:login] = true 
    redirect('/')  
end 

# Attempts logout and updates the session
#
post('/logout') do
    session[:login] = false 
    session[:id] = nil
    redirect('/')
end 

# Displays a register form
#
get('/register') do 
    slim(:"users/register")
end 

# Displays the profile of a user 
#
# @param [Integer] :id, The id of the user 
#
# @see Model#get_user_with_id
get('/user/:id/profile') do 
    id = Integer(params[:id])
    username = @db.get_user_with_id(id)['username']
    slim(:"users/profile", locals: {username: username, id: id, user_id: @user_id})
end 

# Attempts register if username is long enough and not already taken, and the password matches the confirmed password, and updates the session
#
# @param [String] username, The username 
# @param [String] password, The password 
# @param [String] password_confirm, The repeated password
#
# @see Model#add_user
post('/register') do 
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    user_type = UserType::DEFAULT
    if password != password_confirm
        notice = "Password does not match!" 
        raise UnauthorizedAccess.new(notice)
    end 
    @db.add_user(username, password, user_type)
    redirect("/")
end 

# Displays landing page 
#
# @see Model#get_posts
# @see Model#get_categories
get('/') do 
    result = @db.get_posts()
    chosen_categories = []
    categories = @db.get_categories()
    slim(:"posts/index", locals: {posts: result, logged_in: @logged_in, user_id: @user_id, chosen_categories: chosen_categories, categories: categories})
end 

# Displays posts based on sorting parameters
#
# @param [String] chosen_categories, The searched for categories
#
# @see Model#get_categories
# @see Model#get_category_id_with_name
# @see Model#get_posts_id_with_category_id
# @see Model#get_post_with_id
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

# Displays the posts of a user
#
# @param [Integer] :id, The ID of the user 
#
# @see Model#get_posts_with_user_id
# @see Model#get_user_with_id
get('/users/:id/posts') do 
    id = Integer(params[:id])
    result = @db.get_posts_with_user_id(id).reverse
    if id != @user_id  
        username = @db.get_user_with_id(id)["username"]
    end 
    slim(:"users/posts", locals: {posts: result, username: username, user_id: @user_id, id: id})
end 

# Displays the comments of a user 
#
# @param [Integer] :id, The ID of the user 
#
# @see Model#get_comments_with_user_id
# @see Model#get_user_with_id
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

# Displays a post form
#
# @see Model#get_categories
get('/posts/new') do 
    categories = @db.get_categories()
    slim(:"posts/new", locals: {id: @user_id, categories: categories})
end 

# Creates a new post if user is logged in and redirects to '/' 
#
# @param [String] content, The content of the post 
# @param [String] header, The header of the post  
# @param [Array] categories, The categories of the post 
#
# @see Model#add_post
post('/posts') do
    content = params[:content]
    header = params[:header]
    categories = params[:categories]
    if @logged_in
        @db.add_post(header, content, @user_id, categories)
        redirect('/')
    else 
        raise UnauthorizedAccess.new(NO_ACCESS_NOTICE)
    end 
end 

# Deletes an existing post if user is admin or it is their own post and redirects to '/'
#
# @param[Integer] :id, The ID of the post 
#
# @see Model#get_user_with_id
# @see Model#get_post_with_id
# @see Model#delete_post
# @see App#check_user
post('/posts/:id/delete') do 
    id = Integer(params[:id])
    user_type = @db.get_user_with_id(@user_id)["user_type"]
    check_user(user_type, @user_id, @db.get_post_with_id(id)["user_id"])
    @db.delete_post(id)
    redirect('/')
end 

# Displays a post form
#
# @param [Integer] :id, The ID of the post 
#
# @see Model#get_categories
# @see Model#get_post_with_id
get('/posts/:id/edit') do 
    id = Integer(params[:id])
    categories = @db.get_categories()
    result = @db.get_post_with_id(id)
    slim(:"posts/edit", locals: {result: result, categories: categories})
end 

# Updates an existing post if user is admin or it is their own post and redirects to '/'
#
# @param [Integer] :id, The ID of the post 
# @param [String] header, The new header of the post 
# @param [String] content, The new content of the post 
# @param [Array] categories, The new categories of the post 
#
# @see Model#get_user_with_id
# @see Model#get_post_with_id
# @see Model#update_post
# @see App#check_user
post('/posts/:id/update') do 
    id = Integer(params[:id])
    header = params[:header]
    content = params[:content]
    categories = params[:categories]
    user_type = @db.get_user_with_id(@user_id)["user_type"]
    check_user(user_type, @user_id, @db.get_post_with_id(id)["user_id"])
    @db.update_post(header, content, id, categories)
    redirect('/')
end 

# Displays a single post (who posted it, it's comments, the people who saved it, and editing page if it's their own post)
#
# @param [Integer] :id, The ID of the post
#
# @see Model#get_user_with_id
# @see Model#get_post_with_id
# @see Model#get_comments_with_post_id
# @see Model#get_category_id_with_post_id
# @see Model#get_category_name_with_category_id
# @see Model#get_saved_post_users_with_post_id
get('/posts/:id') do 
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

# Saves the post if user is logged in and hasn't already saved it, and redirects to '/posts/:id'
#
# @param [Integer] :id, The ID of the post 
#
# @see Model#post_saved_by_user
# @see Model#add_saved_post
post('/posts/:id/save') do
    id = Integer(params[:id]) 
    if @logged_in
        if !@db.post_saved_by_user?(id, @user_id)
            @db.add_saved_post(id, @user_id)
        end 
    end 
    redirect("/posts/#{id}")
end 

# Displays the saved posts of a user
#
# @param [Integer] :id, The ID of the user 
#
# @see Model#get_saved_posts_with_user_id
# @see Model#get_post_with_id
# @see Model#get_user_with_id
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

# Deletes an existing saved post if it is their own and redirects to '/users/:id/saved_posts'
#
# @param[Integer] :id, The ID of the post 
# @param[Integer] :user_id, The ID of the user 
#
# @see Model#delete_saved_post
post('/users/:user_id/saved_posts/:id/delete') do
    id = Integer(params[:id]) 
    user_id = Integer(params[:user_id])
    if @logged_in
        if @user_id == user_id
            @db.delete_saved_post(id, user_id)
            redirect("/users/#{user_id}/saved_posts")
        end 
    else 
        raise UnauthorizedAccess.new(NO_ACCESS_NOTICE)
    end 
end 

# Creates a new comment if user is logged in and redirects to '/posts/id'
#
# @param [Integer] :post_id, The ID of the post 
# @param [String] content, The content of the comment  
#
# @see Model#add_comment
post('/posts/:post_id/comments') do 
    post_id = Integer(params[:post_id])
    content = params[:content]
    if @logged_in 
        @db.add_comment(content, @user_id, post_id, @username)
    end 
    redirect("/posts/#{post_id}")
end 

# Deletes an existing comment if user is admin or it is their own comment and redirects to '/users/:id/comments'
#
# @param[Integer] :id, The ID of the comment 
# @param[Integer] :post_id, The ID of the post 
#
# @see Model#get_user_with_id
# @see Model#get_comment_with_id
# @see Model#get_comment_with_id
# @see Model#delete_comment
# @see App#check_user
post('/posts/:post_id/comment/:id/delete') do 
    id = Integer(params[:id])
    user_type = @db.get_user_with_id(@user_id)["user_type"]
    user_id = @db.get_comment_with_id(id)["user_id"]
    check_user(user_type, @user_id, @db.get_comment_with_id(id)["user_id"])
    @db.delete_comment(id)
    redirect("/users/#{user_id}/comments")
end 
