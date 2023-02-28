require 'sqlite3'
class Database
    def initialize
        @db = SQLite3::Database.new('db/project.db')
        @db.results_as_hash = true 
    end

    def categories_in_db()
        categories = @db.execute("SELECT name FROM categories")
        categories.map! do |hash|
            hash["name"]
        end 
        return categories 
    end 
    
    #def get_users()
        #lägg eventuellt till så att admin kan se alla användare 
    #end 
    
    def get_user_with_id(id)
        @db.execute("SELECT * FROM users WHERE id = ?", id).first
    end 
    
    def get_user_id_from_username(username)
        @db.execute("SELECT id FROM users WHERE username = ?", username).first["id"]
    end 
    
    def add_users(username, password_digest, user_type)
        @db.execute("INSERT INTO users (username, password, user_type) VALUES (?,?,?)", username, password_digest, user_type)
    end 
    
    def get_comments_with_user_id(user_id)
        @db.execute("SELECT * FROM comments WHERE user_id = ?", user_id)
    end 

    def get_comments_with_post_id(post_id)
        @db.execute("SELECT * FROM comments WHERE post_id = ?", post_id)
    end 
    
    def get_posts()
        @db.execute("SELECT * FROM posts")
    end 
    
    def get_posts_with_post_id(post_id)
        @db.execute("SELECT * FROM posts WHERE id = ?", post_id)
    end 

    def get_posts_with_user_id(user_id)
        @db.execute("SELECT * FROM posts WHERE user_id = ?", user_id)
    end 

    def add_post(header, content, user_id)
        @db.execute("INSERT INTO posts (header, content, user_id) VALUES (?,?,?)", header, content, user_id)
    end 

    def add_category(post_id, category_id)
        @db.execute("INSERT INTO posts_categories (post_id, category_id) VALUES (?,?)", post_id, category_id)
    end 

    def delete_post(post_id)
        @db.execute("DELETE FROM posts WHERE id = ?", id)
        @db.execute("DELETE FROM posts_categories WHERE post_id = ?", id)
        @db.execute("DELETE FROM saved_posts WHERE post_id = ?", id)
    end 
    
    #def get_user_saved_posts(user_id)
    #
    #end 
    #
    #def get_saved_post_users(post_id)
    #
    #end 
    
    def get_category_name_with_category_id(category_id)
        @db.execute("SELECT name FROM categories WHERE id = ?", category_id).first
    end

    def get_category_id_with_name(name)
        @db.execute("SELECT id FROM categories WHERE name = ?", name).first["id"]
    end 

    def get_category_id_with_post_id(post_id)
        @db.execute("SELECT category_id FROM posts_categories WHERE post_id = ?", post_id)
    end 

    def get_post_id_from_post_category_with_category_id(category_id)
        @db.execute("SELECT post_id FROM posts_categories WHERE category_id = ?", category_id)
    end 

    def last_insert_row_id()
        @db.execute("SELECT last_insert_rowid()").first["last_insert_rowid()"]
    end 

    def update_post(header, content, id)
        @db.execute("UPDATE posts SET header = ?, content = ? WHERE id = ?", header, content, id)
        @db.execute("DELETE FROM posts_categories WHERE post_id = ?", id)
    end 

    def get_id_from_saved_posts_with_post_id_and_user_id(post_id, user_id)
        @db.execute("SELECT id FROM saved_posts WHERE post_id = ? AND user_id = ?", post_id, user_id)
    end 

    def add_saved_post(post_id, user_id)
        @db.execute("INSERT INTO saved_posts (post_id, user_id) VALUES (?,?)", post_id, user_id)
    end 

    def get_post_id_from_saved_posts_with_user_id(user_id)
        @db.execute("SELECT post_id FROM saved_posts WHERE user_id = ?", user_id)
    end 

    def delete_saved_post(id, user_id)
        @db.execute("DELETE FROM saved_posts WHERE post_id = ? AND user_id = ?", id, user_id)
    end 

    def add_comment(content, user_id, post_id, username)
        @db.execute("INSERT INTO comments (content, user_id, post_id, username) VALUES (?,?,?,?)", content, user_id, post_id, username)
    end 

    def delete_comment(id)
        @db.execute("DELETE FROM comments WHERE id = ?", id)
    end 
end

