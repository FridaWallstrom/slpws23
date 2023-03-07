require 'sqlite3'
class Database
    def initialize
        @db = SQLite3::Database.new('db/project.db')
        @db.results_as_hash = true 
        @db.execute("PRAGMA foreign_keys = ON")
    end

    def get_categories()
        categories = @db.execute("SELECT name FROM categories")
        categories.map! do |hash|
            hash["name"]
        end 
        return categories 
    end 

    def add_category(post_id, category_id)
        @db.execute("INSERT INTO posts_categories (post_id, category_id) VALUES (?,?)", post_id, category_id)
    end 

    def get_category_name_with_category_id(category_id)
        @db.execute("SELECT name FROM categories WHERE id = ?", category_id).first
    end

    def get_category_id_with_name(name)
        @db.execute("SELECT id FROM categories WHERE name = ?", name).first["id"]
    end 

    def get_category_id_with_post_id(post_id)
        @db.execute("SELECT category_id FROM posts_categories WHERE post_id = ?", post_id)
    end 
    
    def get_user_with_id(id)
        @db.execute("SELECT * FROM users WHERE id = ?", id).first
    end 
    
    def get_user_id_with_username(username)
        result = @db.execute("SELECT id FROM users WHERE username = ?", username).first
        if result 
            result["id"]
        else 
            nil
        end 
    end 
    
    def add_user(username, password_digest, user_type)
        @db.execute("INSERT INTO users (username, password, user_type) VALUES (?,?,?)", username, password_digest, user_type)
    end 
    
    def get_posts()
        @db.execute("SELECT * FROM posts ORDER BY id DESC")
    end 
    
    def get_post_with_id(post_id)
        @db.execute("SELECT * FROM posts WHERE id = ?", post_id).first
    end 

    def get_posts_with_user_id(user_id)
        @db.execute("SELECT * FROM posts WHERE user_id = ?", user_id)
    end 

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

    def delete_post(post_id)
        @db.execute("DELETE FROM posts WHERE id = ?", post_id)
    end 

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

    def get_posts_id_with_category_id(category_id)
        @db.execute("SELECT post_id FROM posts_categories WHERE category_id = ?", category_id)
    end 

    def post_saved_by_user?(post_id, user_id)
        @db.execute("SELECT id FROM saved_posts WHERE post_id = ? AND user_id = ?", post_id, user_id).length > 0 
    end 

    def add_saved_post(post_id, user_id)
        @db.execute("INSERT INTO saved_posts (post_id, user_id) VALUES (?,?)", post_id, user_id)
    end 

    def get_saved_posts_with_user_id(user_id)
        @db.execute("SELECT post_id FROM saved_posts WHERE user_id = ?", user_id)
    end 

    def delete_saved_post(id, user_id)
        @db.execute("DELETE FROM saved_posts WHERE post_id = ? AND user_id = ?", id, user_id)
    end 

    def get_comments_with_user_id(user_id)
        @db.execute("SELECT * FROM comments WHERE user_id = ? ORDER BY id DESC", user_id)
    end 

    def get_comments_with_post_id(post_id)
        @db.execute("SELECT * FROM comments WHERE post_id = ? ORDER BY id DESC", post_id)
    end 

    def get_comment_with_id(id)
        @db.execute("SELECT * FROM comments WHERE id = ?", id).first
    end 

    def add_comment(content, user_id, post_id, username)
        @db.execute("INSERT INTO comments (content, user_id, post_id, username) VALUES (?,?,?,?)", content, user_id, post_id, username)
    end 

    def delete_comment(id)
        @db.execute("DELETE FROM comments WHERE id = ?", id)
    end 

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

