require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def completed_class(list)
    'complete' if list[:todos].all? { |todo| todo[:completed] == 'true' } && !list[:todos].empty?
  end

  def count_completed(list)
    list[:todos].count { |todo| todo[:completed] == 'true' }
  end

  def sort_todos(id)
    list = session[:lists][id.to_i]
    list[:todos].sort_by! do |todo|
      if todo[:completed] == 'true'
        1
      else
        -1
      end
    end
    list[:todos].size.times do |i|
      yield list[:todos][i], i
    end
  end

  def sort_lists
    @lists = session[:lists]
    @lists.sort_by! do |list|
      p list
      if list[:todos].all? { |todo| todo[:completed] != 'true' }
        -1
      else
        1
      end
    end
    @lists.size.times do |i|
      yield @lists[i], i
    end
  end
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

get '/lists' do
  @lists = session[:lists]
  erb :lists
end

get '/lists/new' do
  erb :new_list
end

get '/lists/:id/edit' do |id|
  id = id.to_i
  @list = session[:lists][id]
  erb :edit_list
end

post '/lists/:id/delete' do |id|
  session[:lists].delete_at(id.to_i)
  session[:success] = 'List successfully deleted.'
  redirect '/lists'
end

get '/lists/:id' do |id|
  id = id.to_i
  @list = session[:lists][id]
  erb :list
end

def error_for_list_name(name)
  if !(1..100).cover? name.size
    'List name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'List name must be unique.'
  end
end

def error_for_todo_name(name)
  unless (1..100).cover? name.size
    'Todo name must be between 1 and 100 characters.'
  end
end

post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

post '/lists/:id' do |id|
  id = id.to_i
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists][id][:name] = list_name
    session[:success] = 'The list has been updated.'
    redirect "/lists/#{id}"
  end
end

post '/lists/:id/completed' do |id|
  @list = session[:lists][id.to_i]
  @list[:todos].each { |todo| todo[:completed] = 'true' }
  session[:success] = 'All todos completed.'
  redirect "/lists/#{id}"
end

post '/lists/:id/todos' do |id|
  @list = session[:lists][id.to_i]
  todo = params[:todo].strip
  error = error_for_todo_name(todo)
  if error
    session[:error] = error
  else
    session[:success] = 'Todo created successfully'
    @list[:todos] << { name: todo, completed: 'false' }
  end
  redirect "/lists/#{id}"
end

post '/lists/:list_id/todos/:todo_id/delete' do |list_id, todo_id|
  @list = session[:lists][list_id.to_i]
  @list[:todos].delete_at(todo_id.to_i)
  session[:success] = 'Todo removed.'
  redirect "/lists/#{list_id}"
end

post '/lists/:list_id/todos/:todo_id/toggle' do |list_id, todo_id|
  @list = session[:lists][list_id.to_i]
  @list[:todos][todo_id.to_i][:completed] = params[:completed]
  session[:success] = 'Todo updated successfully.'
  redirect "/lists/#{list_id}"
end
