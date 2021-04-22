require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do
  slim(:register)
end

get('/dokumentation') do
  slim(:dokumentation)
end

get('/showlogin') do
  slim(:login)
end

post('/login') do
  username = params[:username]
  password = params[:password]
  db = SQLite3::Database.new('db/bs.db')
  db.results_as_hash = true
  usernames = db.execute("SELECT username FROM users")
  # felhantering av inloggning
  if usernames.include?({"username" => username}) == true
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    pwdigest = result["pwdigest"]
    id = result["id"]
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      redirect ('/posts')
    else
      redirect('/wronginfo') #Visa felmeddelande istället
    end
  else
    redirect('/wronginfo') #Visa felmeddelande istället
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

  if usernames.include?({"username" => username}) == true
    puts "User already exists!"
  end

  if password == password_confirm
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/bs.db')
    db.execute("INSERT INTO users (username,pwdigest) VALUES (?, ?)",username,password_digest)
    redirect('/showlogin')
  else
    "Passwords do not match"
  end
end

get('/posts') do
  db = SQLite3::Database.new("db/bs.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM posts")
  p result
  slim(:"posts/index",locals:{forum:result})
end