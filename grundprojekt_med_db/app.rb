require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

username = "John Smith"
loginstatus = false

before do
  session["password"] = "abc123"
  session["user"] = username
  session["logged_in"] = loginstatus
end

#Hämtar databas
def getdb()
  return SQLite3::Database.new('db/gp.db')
end

#Hämtar databas i hashformat
def getdbhash()
  db = getdb()
  db.results_as_hash = true
  return db
end

#Startsida
get('/') do
  slim(:index)
end

get('/dokumentation') do
  slim(:dokumentation)
end

get('/users') do
  slim(:'users/index')
end

get('/login') do
  slim(:login)
end

# post('/login') do
#   if params["username"] == session["user"] && params["password"] == session["password"]
#     loginstatus = true
#     redirect('/users')
#   else
#     loginstatus = false
#     redirect('/errors/wrongpw')
#   end
# end

post('/login') do
  username = params[:username]
  password = params[:password]
  db = SQLite3::Database.new('db/gp.db')
  db.results_as_hash = true
  usernames = db.execute("SELECT username FROM users")
  p usernames
  if usernames.include?({"username" => username}) == true
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    pwdigest = result["pwdigest"]
    id = result["id"]
    session['userinfo'] = result
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      redirect ('/users')
    else
      redirect('/errors/wrongpw')
    end
  else
    redirect('/errors/wrongpw')
  end
end

get('/users/new') do
  slim(:login)
end

post('/users/create') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if password == password_confirm
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/gp.db')
    db.execute("INSERT INTO users (username,pwdigest) VALUES (?, ?)",username,password_digest)
    redirect('/login')
  else
    "Passwords do not match"
  end
end

get('/errors/wrongpw') do
  slim(:'errors/wrongpw')
end

get('/errors/not_loggedin') do
  slim(:'errors/not_loggedin')
end

#Visa alla notes
# get('/notes') do
#   slim(:"notes/show")
# end

get('/notes') do
  id = session[:id].to_i
  db = SQLite3::Database.new('db/gp.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM notes WHERE user_id = ?", id)
  p "Alla notes från result #{result}"
  slim(:"notes/show", locals:{notes:result})
end

#Visa formulär som lägger till en note
get('/notes/new') do
  if session["logged_in"] == true
    slim(:"notes/new")
  else
    redirect('/errors/not_loggedin')
  end
end

#Skapa note
# post('/notes/create') do
#   if session["logged_in"] == true
#     post = [params["ny_title"], params["ny_content"], params["author"]]
#     if session["notes"] == nil
#       session["notes"] = []
#       session["notes"] << post
#     else
#       session["notes"] << post
#     end
#     redirect('/notes')
#   else
#     redirect('/errors/not_loggedin')
#   end
# end

post('/notes/create') do
  post = [params["ny_title"], params["ny_content"], params["author"]]
  user_id = session[:id].to_i
  db = SQLite3::Database.new('db/gp.db')
  db.execute("INSERT INTO notes (post, user_id) VALUES (?, ?)",post, user_id)
  redirect('/notes/show')
end

#Ta bort en note
post('/notes/delete') do
  if session['logged_in'] == true
    id = params["id"].to_i
    session["notes"].delete_at(id)
    p id
    redirect('/notes')
  else
    redirect('/errors/not_loggedin')
  end
end

#Ta bort alla notes
post('/notes/destroy') do
  if session['logged_in'] == true
    session["notes"] = nil
    redirect('/notes')
  else
    redirect('/errors/not_loggedin')
  end
end

#Visa formulär som byter användarnamn
get('/users/edit') do
  if session['logged_in'] == true
    slim(:"users/edit")
  else
    redirect('/errors/not_loggedin')
  end
end

#Uppdaterar användarnamn
post('/users/update/:param') do
  if params["param"] == "name"
    username = params["nytt_namn"]
  elsif params["param"] == "age"
    session["age"] = params["ny_age"]
  elsif params["param"] == "bio"
    session["bio"] = params["ny_bio"]
  end
  session["userinfo"] = [username, session["age"], session["bio"]]
  redirect('/users/edit')
end

post('/users/delete/:param') do
  username = session["user"]
  if params["param"] == "age"
    session["age"] = nil
  elsif params["param"] == "bio"
    session["bio"] = nil
  end
  session["userinfo"] = [username, session["age"], session["bio"]]
  redirect('/users/edit')
end
