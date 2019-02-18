class GamesController < ApplicationController
  require 'open-uri'

  def new
    @start_time = Time.now
    @letters = generate_grid(10)
  end

  def score
    @end_time = Time.now
    @letters = JSON.parse(params[:letters_given])
    @start_time = Time.new(params[:start_time])
    @result = run_game(params[:guessed_value], @letters, @start_time, @end_time)
    @guess = params[:guessed_value]
    @time = (@result[:time] / 1000).round
    @message = @result[:message]
  end

  private

  def generate_grid(grid_size)
    Array.new(grid_size) { ('A'..'Z').to_a.sample }
  end

  def included?(guess, grid)
    guess.chars.all? { |letter| guess.count(letter) <= grid.count(letter) }
  end

  def compute_score(attempt, time_taken)
    time_taken > 60.0 ? 0 : attempt.size * (1.0 - time_taken / 60.0)
  end

  def run_game(attempt, grid, start_time, end_time)
    result = { time: end_time - start_time }

    score_and_message = score_and_message(attempt, grid, result[:time])
    result[:score] = score_and_message.first
    result[:message] = score_and_message.last

    result
  end

  def score_and_message(attempt, grid, time)
    if included?(attempt.upcase, grid)
      if english_word?(attempt)
        score = compute_score(attempt, time)
        [score, 'well done']
      else
        [0, "#{attempt} is not an english word"]
      end
    else
      [0, 'not in the grid']
    end
  end

  def english_word?(word)
    response = open("https://wagon-dictionary.herokuapp.com/#{word}")
    json = JSON.parse(response.read)
    @result = json['found']
  end
end
