require 'sequel'
require 'yaml'
require 'json'

# === ugly database setup start ===
database_config_file = File.expand_path('../../database.yml', __FILE__)
unless File.exist? database_config_file
  raise "Please create a valid database.yml file at location: #{database_config_file}"
end

db_config = YAML.load(File.open database_config_file)
DB = Sequel.postgres(db_config['name'], host: 'localhost', user: db_config['user'], password: db_config['password'])
# === ugly database setup end ===

class User < Sequel::Model
  def questions
    Question.where(user_id: id).order(Sequel.asc(:updated_at))
  end
end

class Question < Sequel::Model

  def interactions
    Interaction.where(question_id: id).order(Sequel.asc(:created_at))
  end

  def values
    JSON.parse(self[:values])
  end

  def goods
    values.keys.map(&:to_i)
  end

  def effects
    JSON.parse(self[:effects])
  end

  def answers
    interactions.answers
  end

  def partial_values
    values = []
    active_goods = {}
    answers.each do |answer|
      if answer.combo?
        active_goods = {} # reset active goods
        values.push(combo_value)
      elsif answer.good?
        active_goods[answer.good_number] = answer.selected?
        values.push(bundle_value active_goods)
      else
        raise "Programming error: question_stat #{answer.id} is neither combo or good"
      end
    end
    values
  end

  private

  def combo_value
    values.values.reduce(1, :+) + effects[goods.to_s]
  end

  def bundle_value(active_goods)
    chosen_bundle = chosen_bundle(active_goods)
    (effects[chosen_bundle.to_s] || 0) + chosen_bundle.map{ |good| values[good.to_s] }.reduce(0, :+)
  end

  def chosen_bundle(active_goods)
    bundle = []
    active_goods.each do |k,v|
      bundle.push(k.to_i) if v
    end
    bundle.sort
  end
end

class Interaction < Sequel::Model(:question_stats)
  dataset_module do
    # Menu item was shown: bundle 1,2
    def menu_items
      where(like 'Menu%')
    end

    def answers
      where(like('Good%') | like('Combo%'))
    end

    def combos
      where like('Combo%')
    end

    def goods
      where like('Good%')
    end

    private

    def like(string)
      Sequel.like(:content, string)
    end
  end

  def combo?
    type == 'Combo'
  end

  def good?
    type == 'Good'
  end

  # if content ends in true, then it was selected
  def selected?
    content.rpartition(' ').last == 'true'
  end

  def good_number
    return nil unless good?
    content.split(' ', 3)[1].to_i
  end

  private

  # if this interaction is an answer, type will be either
  # 'Combo' or 'Good'
  def type
    content.split(' ', 2).first
  end
end

# puts Interaction.count
# puts Interaction.menu_items.count
# puts Interaction.goods.count
# puts Interaction.goods.first.content
# puts Interaction.combos.count
# puts Interaction.combos.first.content
# puts Interaction.menu_items.count + Interaction.goods.count + Interaction.combos.count
# puts Interaction.goods.count + Interaction.combos.count
# puts Interaction.answers.count

# puts '==='
# puts Interaction.selected_goods.count + Interaction.deselected_goods.count
# puts "vs #{Interaction.goods.count}"
# puts Interaction.selected_combos.count + Interaction.deselected_combos.count
# puts "vs #{Interaction.combos.count}"


# puts 'quesitons'
# puts Question.count
# puts "interactions: #{User.last.questions.last.interactions.count}"
# puts "menu items: #{User.last.questions.last.menu_items.count}"
# puts "answers: #{User.last.questions.last.answers.count}"
# puts "combos: #{User.last.questions.last.combos.count}"
# puts "goods: #{User.last.questions.last.goods.count}"


# select count(*) from question_stats where question_id = 222 and (content like 'Good%' or content like 'Combo%')
