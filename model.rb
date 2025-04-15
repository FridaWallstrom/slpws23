require 'sqlite3'
require 'bcrypt'

class UnauthorizedAccess < StandardError
end 

module Model 
    class Database
        def initialize
            @db = SQLite3::Database.new('db/project.db')
            @db.results_as_hash = true 
            @db.execute("PRAGMA foreign_keys = ON")
        end

        # Attempts login 
        #
        # @param [String] username The name of the user
        # @param [String] password The password of the user   
        #
        # @see Model#get_user_id_with_username
        # @see Model#get_user_with_id
        #
        # @return [Hash]
        #   * :id [Integer] The id of the category
        #   * :user_type [Integer] The user type of the user 
        #   * :username [String] The name of the user 
        #   * :password [String] The (hashed and salted) password of the user 
        # @return nil if not found
        def try_login(username, password)
            user_id = get_user_id_with_username(username)
            result = get_user_with_id(user_id)
            if result == nil
                sleep(5)    
                notice = "Wrong password or username!"
                raise UnauthorizedAccess.new(notice)
            end 
            if BCrypt::Password.new(result["password"]) != password
                sleep(5)
                notice = "Wrong password or username!"
                raise UnauthorizedAccess.new(notice)
            end  
            return result 
        end 

        # Gets the names of all categories 
        #
        # @return [Array] containing the names of all categories 
        def get_categories()
            categories = @db.execute("SELECT name FROM categories")
            return categories.map do |hash|
                hash["name"]
            end 
        end 

        # Inserts a new row in the posts_categories table 
        #
        # @param [Integer] post_id The id of the post 
        # @param [Integer] category_id The id of the category
        #
        def add_category(post_id, category_id)
            @db.execute("INSERT INTO posts_categories (post_id, category_id) VALUES (?,?)", post_id, category_id)
        end 

        # Gets the name of a category with it's id 
        #
        # @param [Integer] category_id The id of the category 
        #
        # @return [Hash]
        #   * :name [String] The name of the category
        # @return nil if not found
        def get_category_name_with_category_id(category_id)
            @db.execute("SELECT name FROM categories WHERE id = ?", category_id).first
        end

        # Gets the id of a category with it's name
        #
        # @param [String] name The name of the category 
        #
        # @return [Integer] The id of the category
        # @return nil if not found
        def get_category_id_with_name(name)
            @db.execute("SELECT id FROM categories WHERE name = ?", name).first["id"]
        end 

        # Gets the id of a category of a post with the post's id 
        #
        # @param [Integer] post_id The id of the post 
        #
        # @return [Hash]
        #   * :category_id [Integer] The id of the category
        def get_category_id_with_post_id(post_id)
            @db.execute("SELECT category_id FROM posts_categories WHERE post_id = ?", post_id)
        end 
        
        # Gets a user with it's id 
        #
        # @param [Integer] id The id of the user 
        #
        # @return [Hash]
        #   * :id [Integer] The id of the category
        #   * :user_type [Integer] The user type of the user 
        #   * :username [String] The name of the user 
        #   * :password [String] The (hashed and salted) password of the user 
        # @return nil if not found
        def get_user_with_id(id)
            @db.execute("SELECT * FROM users WHERE id = ?", id).first
        end 
        
        # Attempts to get the id of a user with it's username
        #
        # @param [String] username The name of the user 
        #
        # @return [Hash] returns an integer 
        #   * :id [Integer] The id of the user 
        # @return nil if not found
        def get_user_id_with_username(username)
            result = @db.execute("SELECT id FROM users WHERE username = ?", username).first
            if result 
                result["id"]
            else 
                nil
            end 
        end 
        
        # Adds a new user 
        #
        # @param [String] username The name of the user 
        # @param [Integer] user_type The user type of the user 
        #
        # @see Model#get_user_id_with_username
        def add_user(username, password, user_type)
            if username.length < 3 
                notice = "Username is too short, needs to contain at least 3 characters" 
                raise UnauthorizedAccess.new(notice)
            end 
            user_id = get_user_id_with_username(username)
            if user_id
                notice = "Username is already in use, try a new one!" 
                raise UnauthorizedAccess.new(notice)
            end 
            password_digest = BCrypt::Password.create(password)
            @db.execute("INSERT INTO users (username, password, user_type) VALUES (?,?,?)", username, password_digest, user_type)
        end 
        
        # Gets all the posts
        #
        # @return [Hash]
        #   * :id [Integer] The id of the post
        #   * :header [String] The header of the post 
        #   * :content [String] The content of the post 
        #   * :user_id [Integer] The id of the creater of the post 
        def get_posts()
            @db.execute("SELECT * FROM posts ORDER BY id DESC")
        end 
        
        # Gets a post with a certain id 
        #
        # @param [Integer] post_id The id of the post 
        #
        # @return [Hash]
        #   * :id [Integer] The id of the post
        #   * :header [String] The header of the post 
        #   * :content [String] The content of the post 
        #   * :user_id [Integer] The id of the creator of the post 
        # @return nil if not found
        def get_post_with_id(post_id)
            @db.execute("SELECT * FROM posts WHERE id = ?", post_id).first
        end 

        # Gets the posts that are created by a user 
        #
        # @param [Integer] user_id The id of the post's creator 
        #
        # @return [Hash]
        #   * :id [Integer] The id of the post
        #   * :header [String] The header of the post 
        #   * :content [String] The content of the post 
        #   * :user_id [Integer] The id of the creator of the post 
        def get_posts_with_user_id(user_id)
            @db.execute("SELECT * FROM posts WHERE user_id = ?", user_id)
        end 

        # Adds a new post 
        #
        # @param [String] header The header of the post 
        # @param [String] content The content of the post 
        # @param [Integer] user_id The id of the user 
        # @param [Array] categories The categories of the post 
        #
        # @see Model#get_category_id_with_name
        # @see Model#add_category
        def add_post(header, content, user_id, categories)
            @db.execute("INSERT INTO posts (header, content, user_id) VALUES (?,?,?)", header, content, user_id)
            post_id = @db.execute("SELECT last_insert_rowid()").first["last_insert_rowid()"]
            if categories != nil
                categories.each do |category|
                    category_id = get_category_id_with_name(category)
                    add_category(post_id, category_id)
                end 
            end 
        end 

        # Deletes a post with a certain id 
        #
        # @param [Integer] post_id The id of the post 
        #
        def delete_post(post_id)
            @db.execute("DELETE FROM posts WHERE id = ?", post_id)
        end 

        # Updates a post 
        #
        # @param [String] header The header of the post 
        # @param [String] conetne The content of the post 
        # @param [Integer] user_id The id of the user 
        # @param [Array] categories The categories of the post 
        #
        # @see Model#get_category_id_with_name
        # @see Model#add_category
        def update_post(header, content, id, categories)
            @db.execute("UPDATE posts SET header = ?, content = ? WHERE id = ?", header, content, id)
            @db.execute("DELETE FROM posts_categories WHERE post_id = ?", id)
            if categories != nil
                categories.each do |category|
                    category_id = get_category_id_with_name(category)
                    add_category(id, category_id)
                end 
            end 
        end 

        # Gets the ids of the posts with a certain category id 
        #
        # @param [Integer] category_id The id of the category 
        #
        # @return [Hash]
        #   * :post_id [Integer] The id of the post
        def get_posts_id_with_category_id(category_id)
            @db.execute("SELECT post_id FROM posts_categories WHERE category_id = ?", category_id)
        end 

        # Sees if post already has been saved by a user 
        #
        # @param [Integer] post_id The id of the post 
        # @param [Integer] user_id The id of the user 
        #
        # @return [Boolean] that is true if the user already has saved the post, and false if not
        def post_saved_by_user?(post_id, user_id)
            @db.execute("SELECT id FROM saved_posts WHERE post_id = ? AND user_id = ?", post_id, user_id).length > 0 
        end 

        # Saves a post 
        #
        # @param [Integer] post_id The id of the post 
        # @param [Integer] user_id The id of the user 
        #
        def add_saved_post(post_id, user_id)
            @db.execute("INSERT INTO saved_posts (post_id, user_id) VALUES (?,?)", post_id, user_id)
        end 

        # Gets the saved posts of a user 
        #
        # @param [Integer] user_id The id of the user 
        #
        # @return [Hash]
        #   * :post_id [Integer] The id of the post
        def get_saved_posts_with_user_id(user_id)
            @db.execute("SELECT post_id FROM saved_posts WHERE user_id = ?", user_id)
        end 

        # Deletes the saved posts from a user 
        #
        # @param [Integer] id The id of the post 
        # @param [Integer] user_id The id of the user 
        #
        def delete_saved_post(id, user_id)
            @db.execute("DELETE FROM saved_posts WHERE post_id = ? AND user_id = ?", id, user_id)
        end 

        # Gets the comments of a user 
        #
        # @param [Integer] user_id The id of the user 
        #
        # @return [Hash]
        #   * :id [Integer] The id of the comment
        #   * :content [String] The content of the comment 
        #   * :user_id [Integer] The id of the user 
        #   * :post_id [Integer] The id of the post
        #   * :username [String] The name of the user
        def get_comments_with_user_id(user_id)
            @db.execute("SELECT * FROM comments WHERE user_id = ? ORDER BY id DESC", user_id)
        end 

        # Gets the comments of a post 
        #
        # @param [Integer] post_id The id of the post 
        #
        # @return [Hash]
        #   * :id [Integer] The id of the comment
        #   * :content [String] The content of the comment 
        #   * :user_id [Integer] The id of the user 
        #   * :post_id [Integer] The id of the post
        #   * :username [String] The name of the user
        def get_comments_with_post_id(post_id)
            @db.execute("SELECT * FROM comments WHERE post_id = ? ORDER BY id DESC", post_id)
        end 
        
        # Gets a comment with a certain id 
        #
        # @param [Integer] id The id of the comment 
        #
        # @return [Hash]
        #   * :id [Integer] The id of the comment
        #   * :content [String] The content of the comment 
        #   * :user_id [Integer] The id of the user 
        #   * :post_id [Integer] The id of the post
        #   * :username [String] The name of the user
        # @return nil if not found
        def get_comment_with_id(id)
            @db.execute("SELECT * FROM comments WHERE id = ?", id).first
        end 

        # Adds a new comment 
        #
        # @param [String] content The content of the post 
        # @param [Integer] user_id The id of the user 
        # @param [Integer] post_id The id of the post 
        # @param [String] username The name of the user 
        #
        def add_comment(content, user_id, post_id, username)
            @db.execute("INSERT INTO comments (content, user_id, post_id, username) VALUES (?,?,?,?)", content, user_id, post_id, username)
        end 

        # Deletes a comment with a certain id 
        #
        # @param [Integer] id The id of the comment
        # 
        def delete_comment(id)
            @db.execute("DELETE FROM comments WHERE id = ?", id)
        end 

        # Gets the users that have saved a certain post 
        #
        # @param [Integer] post_id The id of the post
        #
        # @return [Hash]
        #   * :id [Integer] The id of the saved post (not the post itself)
        #   * :user_type [Integer] The user type of the user 
        #   * :username [String] The name of the user 
        #   * :password [String] The (hashed and salted) password of the user
        #   * :post_id [Integer] The id of the post
        #   * :user_id [Integer] The id of the user
        def get_saved_post_users_with_post_id(post_id)
            result = @db.execute("SELECT * FROM users INNER JOIN saved_posts ON users.id = saved_posts.user_id") 
            users = []
            result.each do |value|
                if value["post_id"] == post_id
                    users << value
                end 
            end 
            return users 
        end 
    end
end 
