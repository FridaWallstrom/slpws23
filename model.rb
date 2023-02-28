require_relative './app.rb'
require 'sqlite3'

def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true 
    return db
end 

before do 
    @db = connect_to_db('db/project.db')
end 

def categories_in_db()
    categories = @db.execute("SELECT name FROM categories")
    categories.map! do |hash|
        hash["name"]
    end 
    return categories 
end 

def select(wanted_column, db_table)
    @db.execute("SELECT " + wanted_column + " FROM " + db_table)
end 

def select_requirement(wanted_column, db_table, db_column, variable)
    if variable.length == 1
        @db.execute("SELECT " + wanted_column + " FROM " + db_table + " WHERE " + db_column[0] + " = ?", variable[0])
    elsif variable.length == 2 #funkar ej? 
        @db.execute("SELECT " + wanted_column + " FROM " + db_table + " WHERE " + db_column[0] + " = ? AND " + db_column[1] + " = ?", variable[0], variable[1])
    end 
end 

def select_descending(wanted_column, db_table, descending_variable)
    @db.execute("SELECT " + wanted_column + " FROM " + db_table + " ORDER BY " + descending_variable + " DESC")
end 

def select_one_requirement_descending(wanted_column, db_table, db_column, descending_variable, variable)
    @db.execute("SELECT " + wanted_column + " FROM " + db_table + " WHERE " + db_column + " = ? ORDER BY " + descending_variable + " DESC", variable)
end 

def delete(db_table, db_column, variable)
    if variable.length == 1
        @db.execute("DELETE FROM " + db_table + " WHERE " + db_column[0] + " = ?", variable[0])
    elsif variable.length == 2
        @db.execute("DELETE FROM " + db_table + " WHERE " + db_column[0] + " = ? AND " + db_column[1] + " = ?", variable[0], variable[1])
    end 
end 

def insert_into(db_table, db_columns, variables)
    if variables.length == 2
        @db.execute("INSERT INTO " + db_table + " (" + db_columns[0] + ", " + db_columns[1] + ") VALUES (?,?)", variables[0], variables[1])
    elsif variables.length == 3
        @db.execute("INSERT INTO " + db_table + " (" + db_columns[0] + ", " + db_columns[1] + ", " + db_columns[2] + ") VALUES (?,?,?)", variables[0], variables[1], variables[2])
    elsif variables.length == 4 
        @db.execute("INSERT INTO " + db_table + " (" + db_columns[0] + ", " + db_columns[1] + ", " + db_columns[2] + ", " + db_columns[3] + ") VALUES (?,?,?,?)", variables[0], variables[1], variables[2], variables[3])
    end 
end 

def last_insert_rowid()
    @db.execute("SELECT last_insert_rowid()")
end 

def update_two_columns(db_table, db_columns, depending_column, variables)
    @db.execute("UPDATE " + db_table + " SET " + db_columns[0] + " = ?, " + db_columns[1] + " = ? WHERE " + depending_column + "= ?", variables[0], variables[1], variables[2])
end 

def inner_join()

end 
