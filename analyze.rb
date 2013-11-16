require_relative './analyzer/analyzer.rb'

puts "type q to quit"

while true do
  puts 'Question id to analyze: '
  id = gets.chomp
  break if id == 'q'

  question = Question[id.to_i]

  if question.nil?
    puts "Question not found"
  else
    puts "partial values: #{question.partial_values}"
  end
end