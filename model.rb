
#ska det bara vara sql, eller kan det vara ruby kod också 

#    result = @db.execute("SELECT * FROM users WHERE username = ?", username).first

#ska den vara här eller i app
def categories_in_db()
    categories = @db.execute("SELECT name FROM categories")
    categories.map! do |hash|
        hash["name"]
    end 
    return categories 
end 