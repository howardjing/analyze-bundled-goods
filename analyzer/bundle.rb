module Bundle

  def to_json(*args)
    { bundle: bundle, value: value, time: created_at, in_search_set: in_search_set }.to_json(*args)
  end

  class Combo
    include Bundle
    attr_reader :created_at, :in_search_set

    def initialize(question, interaction_combo, search_set)
      @question = question
      @created_at = interaction_combo.created_at
      @is_selected = interaction_combo.selected?      
      @in_search_set = search_set.include?(@question.goods.to_s)
    end

    def value
      @value ||= @is_selected ? combo_selected_value : 0
    end

    def bundle
      "Combo#{@question.goods}"
    end

    private

    def combo_selected_value
      @question.values.values.reduce(1, :+) + @question.effects[@question.goods.to_s]
    end
  end

  class Goods
    include Bundle
    attr_reader :created_at, :in_search_set

    def initialize(question, interaction_good, active_goods, search_set)
      @question  = question
      @created_at = interaction_good.created_at
      @active_goods = active_goods.clone
      # if chosen_bundle has <= length 1, there are no bundle effects, is trivially in search set
      @in_search_set = chosen_bundle.length <= 1 ? true : search_set.include?(chosen_bundle.to_s)
    end

    def value
      @value ||= (@question.effects[chosen_bundle.to_s] || 0) + chosen_bundle.map{ |good| @question.values[good.to_s] }.reduce(0, :+)
    end

    def bundle
      "Goods#{chosen_bundle}"
    end

    private 

    def chosen_bundle
      @chosen_bundle ||= @active_goods.map { |good| good.to_i }.sort
    end
  end
end