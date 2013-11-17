require 'sequel'
require 'yaml'
require 'json'
require 'set'
require_relative './bundle'

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

  def number
    DB[:instructions].where(id: instruction_id).get(:number)
  end

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

  def menu_items
    interactions.menu_items
  end

  def answers
    interactions.answers
  end

  def partial_values
    values = []
    active_goods = Set.new
    search_set = Set.new
    interactions.each do |interaction|
      if interaction.menu_item?
        search_set.add(interaction.bundle)
      elsif interaction.combo?
        active_goods = Set.new # reset active goods
        values.push(Bundle::Combo.new(self, interaction, search_set))
      elsif interaction.good?
        if interaction.selected?
          active_goods.add(interaction.good_number)
        else
          active_goods.delete(interaction.good_number)
        end
        values.push(Bundle::Goods.new(self, interaction, active_goods, search_set))
      else
        raise "Programming error: question_stat #{answer.id} is neither combo or good"
      end
    end
    values
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

  def menu_item?
    type == 'Menu'
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

  # if interaction is a menu_item, find the bundle this interaction represents 
  def bundle
    content.split('bundle ').last.split(",").map(&:to_i).to_s
  end

  private

  # if this interaction is an answer, type will be either
  # 'Combo' or 'Good'
  def type
    content.split(' ', 2).first
  end
end
