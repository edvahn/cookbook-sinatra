require "sinatra"
require "sinatra/reloader" if development?
require "pry-byebug"
require "better_errors"
configure :development do
  use BetterErrors::Middleware
  BetterErrors.application_root = File.expand_path('..', __FILE__)
end

get '/' do
  class Router
  def initialize(controller)
    @controller = controller
    @running    = true
  end

  def run
    puts "Welcome to the Cookbook!"
    puts "           --           "

    while @running
      display_tasks
      action = gets.chomp.to_i
      print `clear`
      route_action(action)
    end
  end

  private

  def route_action(action)
    case action
    when 1 then @controller.list
    when 2 then @controller.create
    when 3 then @controller.destroy
    when 4 then @controller.marmiton
    when 5 then @controller.mark_recipe_as_done
    when 6 then stop
    else
      puts "Please press 1, 2, 3, 4, 5 or 6"
    end
  end

  def stop
    @running = false
  end

  def display_tasks
    puts ""
    puts "What do you want to do next?"
    puts "1 - List all recipes"
    puts "2 - Create a new recipe"
    puts "3 - Destroy a recipe"
    puts "4 - Import recipes from Marmiton"
    puts "5 - Mark recipe as done"
    puts "6 - Stop and exit the program"
  end
end

require_relative "recipe"
require_relative "view"
require 'open-uri'
require 'nokogiri'


class Controller
  def initialize(cookbook)
    @cookbook = cookbook
    @view = View.new
  end

  def list
    recipes = @cookbook.all
    @view.display_recipes(recipes)
  end

  def create
    name = @view.ask_user_for_name
    description = @view.ask_user_for_description
    recipe = Recipe.new(name: name, description: description)
    @cookbook.add_recipe(recipe)
  end

  def destroy
    index = @view.ask_user_for_index
    @cookbook.remove_recipe(index)
  end

  def marmiton
    # Ask a user for a keyword to search
    keyword = @view.ask_for_keyword
    @view.ask_index_difficulty
    # Make an HTTP request to the recipe's website with our keyword
    # Parse the HTML document to extract the first 5 recipes suggested and store them in an Array
    recipes_marmiton = parsing(keyword)
    # Display them in an indexed list
    @view.print_recipe_from_marmiton(recipes_marmiton, keyword)
    # Ask the user which recipe they want to import (ask for an index)
    marmiton_index = @view.ask_index_to_import
    # Add it to the Cookbook
    @cookbook.import_recipe_marmiton(recipes_marmiton, marmiton_index)
    title = recipes_marmiton[marmiton_index][:title]
    @view.display_importing_marmiton_recipe(title)
  end

  def mark_recipe_as_done
    list
    mark_index = @view.ask_index_to_mark
    recipe = @cookbook.all[mark_index]
    recipe.mark_as_done
    list
    @cookbook.save_csv
  end

  def parsing(keyword)
    recipes_marmiton = []
    url = "http://www.marmiton.org/recettes/recherche.aspx?type=all&aqt=#{keyword}"
    html_file = open(url).read
    html_doc = Nokogiri::HTML(html_file)
    html_doc.search(".recipe-card").first(5).each do |element|
      title = element.search(".recipe-card__title").text.strip
      description = element.search(".recipe-card__description").text.strip
      prep_time = element.search(".recipe-card__duration__value").text.strip
      recipes_marmiton << { title: title, description: description, prep_time: prep_time }
    end
    return recipes_marmiton
  end
end

end
