require_relative "../services/tmdb.rb"

class SearchesController < ApplicationController
  skip_before_action :authenticate_user!

  def home
    user_params[:photo] ? photo_upload_handler : set_instance_vars
  end

  def create
    query = params[:queries].present? ? "#{params[:queries]}&#{params[:search][:query]}" : params[:search][:query]
    @search = Search.new(query: query)
    @search.user = current_user if user_signed_in?
    if @search.save
      redirect_to root_path(construct_query)
    else
      render :home
    end
  end

  def get_actors
    # just left here for test prposes, not really used
    tmdb = Tmdb.new(ENV["TMDB_KEY"])
    @result = tmdb.get_actors(params[:movie_id])
    render json: result
  end

  private

  def photo_upload_handler
    # for now, pretend any submitted image is Julia Roberts and
    # redirect to the result page for that search
    @search = Search.new(query: "Julia Roberts")
    @search.save ? (redirect_to result_path(@search.result)) : (redirect_to root_path)
  end

  def construct_query
    if params[:search][:photo]
      search_params
    else
      previous_queries = params[:queries].present? ? "#{params[:queries]}&" : ""
      { search: { queries: previous_queries + params[:search][:query] } }
    end
  end

  def user_params
    params.except(:controller, :action)
  end

  def set_instance_vars
    user_params.empty? ? no_params : set_vars_from_params
    @search = Search.new
  end

  def no_params
    @query = []
    @results = []
  end

  def set_vars_from_params
    # @query [ "123", "1231", "123" ] is an array that stores the ids we need to use to call the api
    @query = user_params[:search][:queries].strip.split("&")
    # @results = search_results(params[:search][:queries])
    # redirect_to result_path(Result.last) if @query.count > 1
    tmdb = Tmdb.new(ENV["TMDB_KEY"])
    cast = tmdb.get_actors(@query.last.to_i)
    movies = tmdb.get_movie_details(@query)
    @results = { cast: cast, movies: movies }
  end

  def full_query
    user_params
      .as_json
      .map { |key, _value| params[key] }
      .join("&")
  end

  def search_results(query)
    search = Search.find_by(query: query) || Search.create(query: query)
    JSON.parse(search.result.json)
  end

  def search_params
    params.require(:search).permit(:query, :photo)
  end
end
