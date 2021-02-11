require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do
  slim(:register)
end

get('/showlogin') do
  slim(:login)
end

post('/login') do
  username = params[:username]
  password = params[:password]
  db = SQLite3::Database.new('db/intresseklubben.db')
  db.results_as_hash = true
  usernames = db.execute("SELECT username FROM users")

  p usernames #remove 

  if usernames.include?({"username" => username}) == true
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    pwdigest = result["pwdigest"]
    id = result["id"]
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      redirect ('/todos')
    else
      redirect('/wronginfo')
    end
  else
    redirect('/wronginfo')
  end
end

#Ful felhantering. Inserta istället felmeddelande på samma sida.
get('/wronginfo') do
  slim(:wronginfo)
end

post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if password == password_confirm
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/intresseklubben.db')
    db.execute("INSERT INTO users (username,pwdigest) VALUES (?, ?)",username,password_digest)
    redirect('/')
  else
    "Lösenorden matchar inte!"
  end
end

get('/index') do
  db = SQLite3::Database.new("db/intresseklubben.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM albums")
  p result
  slim(:"forum/index",locals:{forum:result})
end