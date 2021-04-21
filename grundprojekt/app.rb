require 'sinatra'
require 'slim'

enable :sessions

username = "John Smith"

before do
  session["password"] = "abc123"
  session["user"] = username
end

#Startsida
get('/') do
  slim(:index)
end

get('/users') do
  slim(:'users/index')
end

get('/login') do
  slim(:login)
end

get ('/error') do
  slim(:error)
end

post("/login") do
  if params["username"] == session["user"] && params["password"] == session["password"]
    session["logged_in"] = true
    redirect('/users')
  else
    session["logged_in"] = false
    redirect('/error')
  end

end

#Visa formulär som lägger till en note
get('/notes/new') do
  slim(:"notes/new")
end

#Skapa note
post('/notes/create') do
    post = [params["ny_title"], params["ny_content"], params["author"]]
  if session["notes"] == nil
    session["notes"] = []
    session["notes"] << post
  else
    session["notes"] << post
  end

  redirect('/notes')
end

post('/notes/delete') do
  id = params["id"].to_i
  session["notes"].delete_at(id)
  p id
  redirect('/notes')
end

post('/notes/destroy') do
  session["notes"] = nil
  redirect('/notes')
end

#Visa alla notes
get('/notes') do
  slim(:"notes/show")
end

#Visa formulär som byter användarnamn
get('/users/edit') do
  p session["user"]
  slim(:"users/edit")
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
  
  #p session["user"]
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

  #p session["user"]
  redirect('/users/edit')
end