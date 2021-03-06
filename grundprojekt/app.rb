require 'sinatra'
require 'slim'

enable :sessions

username = "John Smith"
loginstatus = false

before do
  session["password"] = "abc123"
  session["user"] = username
  session["logged_in"] = loginstatus
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

get('/errors/wrongpw') do
  slim(:'errors/wrongpw')
end

get('/errors/not_loggedin') do
  slim(:'errors/not_loggedin')
end


post('/login') do
  if params["username"] == session["user"] && params["password"] == session["password"]
    loginstatus = true
    redirect('/users')
  else
    loginstatus = false
    redirect('/errors/wrongpw')
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
    post = [params["ny_title"], params["ny_content"], params["author"]]
    if session["notes"] == nil
      session["notes"] = []
      session["notes"] << post
    else
      session["notes"] << post
    end
    redirect('/notes')
  else
    redirect('/errors/not_loggedin')
  end
end

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

post('/notes/destroy') do
  if session['logged_in'] == true
    session["notes"] = nil
    redirect('/notes')
  else
    redirect('/errors/not_loggedin')
  end
end

#Visa alla notes
get('/notes') do
  slim(:"notes/show")
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
