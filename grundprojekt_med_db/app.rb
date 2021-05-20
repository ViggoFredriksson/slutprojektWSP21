require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

salt = "returntomonkey"
id=""
username = ""
loginstatus = false

before do
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

#Hittar användarnamnet som tillhör ett användar-id i databasen
def checkusername(id)
  result = getdbhash().execute("SELECT username FROM users WHERE id=?", id)
  return result[0]["username"]
end

#Hämtar all användardata kopplad till ett användarnamn i databasen
def finduserinfo(username)
  return getdbhash().execute("SELECT * FROM users WHERE username = ?", username).first
end

#Hämtar alla användarnamn i databasen
def findallusernames()
  return getdbhash().execute("SELECT username FROM users")
end

#Startsida
get('/') do
  slim(:index)
end

#Dokumentationssida
get('/dokumentation') do
  slim(:dokumentation)
end

#Visar loginsida
get('/login') do
  slim(:login)
end

#Fixelifixar login från formulär
post('/login') do
  username = params[:username]
  password = params[:password]
  db = getdbhash
  usernames = findallusernames
  p usernames
  if usernames.include?({"username" => username}) == true
    result = finduserinfo(username)
    pwdigest = result["pwdigest"]
    id = result["id"]
    session['userinfo'] = result
    if BCrypt::Password.new(pwdigest) == password + salt
      session[:id] = id
      loginstatus = true
      redirect ('/users')
    else
      redirect('/errors/wrongpw')
    end
  else
    redirect('/errors/wrongpw')
  end
end

#Visar users/index, som är sidans "landing page"
get('/users') do
  if session["logged_in"] == true
    slim(:"users/index")
  else
    redirect('/errors/not_loggedin')
  end
end

#Visar users/new, där man registrerar nya konton
get('/users/new') do
  slim(:'users/new')
end

#Fixelifixar kontoregistrering via formulär 
post('/users/create') do
  db = getdbhash
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  usernames = findallusernames
  if username == "" || password == ""
    redirect('/errors/password_empty')
  end
  if !usernames.include?({"username" => username})  
    if password == password_confirm
      password = password + salt
      password_digest = BCrypt::Password.create(password)
      db = SQLite3::Database.new('db/gp.db')
      db.execute("INSERT INTO users (username,pwdigest) VALUES (?, ?)",username,password_digest)
      redirect('/login')
    else
      "Passwords do not match"
    end
  else
    redirect('/errors/user_not_unique')
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
  if session['logged_in'] == true
    db = getdb
    if params["param"] == "name"
      username = params["nytt_namn"]
      db.execute("UPDATE users SET username=? WHERE id=?", username,id)
    elsif params["param"] == "age"
      ny_age = params["ny_age"]
      db.execute("UPDATE users SET age=? WHERE id=?", ny_age,id)
    elsif params["param"] == "bio"
      ny_bio = params["ny_bio"]
      db.execute("UPDATE users SET bio=? WHERE id=?", ny_bio,id)
    end
    session["userinfo"] = finduserinfo(username)
    redirect('/users/edit')
  else
    redirect('/errors/not_loggedin')
  end
end

#Tar bort användarinfo
post('/users/delete/:param') do
  if session['logged_in'] == true
    db = getdb
    username = session["user"]
    if params["param"] == "age"
      no_age = nil
      db.execute("UPDATE users SET age=? WHERE id=?", no_age,id)
    elsif params["param"] == "bio"
      no_bio = nil
      db.execute("UPDATE users SET bio=? WHERE id=?", no_bio,id)
    end
    session["userinfo"] = finduserinfo(username)
    redirect('/users/edit')
  else
    redirect('/errors/not_loggedin')
  end
end

#Hit kommer du om du skriver in fel lösen eller användarnamn
get('/errors/wrongpw') do
  slim(:'errors/wrongpw')
end

#Denna sida visas om du failar en loginstatus-check
get('/errors/not_loggedin') do
  slim(:'errors/not_loggedin')
end

#Denna sida visas om någon försöker registrera ett konto med ett användarnamn som är upptaget
get('/errors/user_not_unique') do
  slim(:'errors/user_not_unique')
end

#Visas om någon försöker registrera ett konto utan att skriva in lösenord eller användarnamn
get('/errors/password_empty') do
  slim(:'errors/password_empty')
end

#Visas om någon försöker skapa en note utan att skriva in något
get('/errors/note_empty') do
  slim(:'errors/note_empty')
end

#Visa alla notes
get('/notes') do
  if session["logged_in"] == true
    id = session[:id].to_i
    db = getdbhash
    result = db.execute("SELECT * FROM notes WHERE user_id = ?", id)
    p "Alla notes från result #{result}"
    slim(:"notes/show", :locals=>{result:result})
  else
    redirect('/errors/not_loggedin')
  end
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
post('/notes/create') do
  if session["logged_in"] == true
    db = getdb
    user_id = session[:id].to_i
    title = params["title"]
    content = params["content"]
    p title
    p content
    if title != "" || content != ""
      db.execute("INSERT INTO notes (title,content, user_id) VALUES (?,?,?)",title, content,user_id)
      redirect('/notes')
    else
      redirect('/error/note_empty')
    end
  else
    redirect('/errors/not_loggedin')
  end
end

#Ta bort en note
post('/notes/:id/delete') do
  if session['logged_in'] == true
    db = getdb
    id = params["id"]
    db.execute("DELETE FROM notes WHERE id=?", id)
    redirect('/notes')
  else
    redirect('/errors/not_loggedin')
  end
end

#Ta bort alla notes
post('/notes/destroy') do
  if session['logged_in'] == true
    db = getdb
    id = session["id"]
    db.execute("DELETE FROM notes WHERE user_id=?", id)
    redirect('/notes')
  else
    redirect('/errors/not_loggedin')
  end
end




