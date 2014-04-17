require 'sinatra'
require_relative '../analyzer/analyzer'

get '/' do
  @users = User.all
  erb :users
end

get '/users/:id' do |id|
  @user = User[id]
  @questions = @user.questions
  erb :questions
end

get '/questions/:id' do |id|
  @question = Question[id]
  erb :question
end

# update action
post '/questions/:id' do |id|
  @question = Question[id]
  @question.increasing = params[:increasing] == "on"
  @question.notes      = params[:notes]
  @question.save
  redirect "/questions/#{id}"
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def format_date(date)
    date.strftime('%A, %b %d %Y')
  end

  def format_time(time)
    if time
      time.strftime('%I:%M:%S %p')
    else
      "N/A"
    end
  end
end
