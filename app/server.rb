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

helpers do
  def format_date(date)
    date.strftime('%A, %b %d %Y')
  end

  def format_time(time)
    time.strftime('%I:%M:%S %p')
  end
end