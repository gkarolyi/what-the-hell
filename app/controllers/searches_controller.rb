require_relative "../services/tmdb.rb"

class SearchesController < ApplicationController
  skip_before_action :authenticate_user!

  def home
    # use the photo handler method if there is an image in the params
    # otherwise set instance vars from params
    user_params[:photo] ? photo_upload_handler : set_instance_vars
  end

  def create
    # if there are previous queries in params, prepend them to the newly added query
    # otherwise use just the newly added query
    query = params[:queries].present? ? "#{params[:queries]}&#{params[:search][:query]}" : params[:search][:query]
    # create a search with the query built above
    @search = Search.new(query: query, photo: params[:search][:photo])
    # set user if logged in
    @search.user = current_user if user_signed_in?
    if @search.save && params[:search][:photo]
      @result = Result.create
      @search.update(result: @result)
      redirect_to result_path(@search.result)
    elsif @search.save
      # if the search saved successfully, come back to the same page and add the complete query to params
      redirect_to root_path(construct_query)
    else
      render :home
    end
  end

  private

  def photo_upload_handler
    # for now, pretend any submitted image is Julia Roberts and
    # redirect to the result page for that search
    # actually we'll want to send the API request here
    raise
    @result = Result.create(json: "photo_upload")
    @search.result = @result
    if @search.save
      redirect_to result_path(@search.result)
    else
      redirect_to root_path
    end
  end

  def construct_query
    if params[:search][:photo]
      # add a text representation of the uploaded image to params and return the params object
      search_params
    else
      # if no photo was uploaded, build a string of previous queries from the params
      previous_queries = params[:queries].present? ? "#{params[:queries]}&" : ""
      # return a params-like Hash structured like the simpleform params using the previous and latest query
      { search: { queries: previous_queries + params[:search][:query] } }
    end
  end

  def user_params
    # any params not added by default, ie. any queries
    params.except(:controller, :action)
  end

  def set_instance_vars
    # leave instance variables empty if there are no queries in params
    # otherwise, set instance vars from queries in params
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
    if @query.count > 1 && (actor_ids = Tmdb.matching_cast(@query))
      if actor_ids.count == 1
        # if we have 2 movie inputs and one matching actor
        redirect_to result_path(Result.create(json: actor_ids.first))
      elsif actor_ids.count > 1
        # if we have 2 movie inputs and several matching actors they
        # will be displayed on the preresults page
        cast = []
        actor_ids.each do |actor_id|
          cast << Result.create(json: Tmdb.get_actor_details(actor_id))
        end
        movies = Tmdb.get_movie_details(@query)
        @results = { cast: cast, movies: movies }
        @common_actors = true
      else
        cast = Tmdb.get_actors(@query.last.to_i)
        movies = Tmdb.get_movie_details(@query)
        @results = { cast: cast, movies: movies }
        @common_actors = false
      end
    else
      # if there is only 1 movie input or no matching actors display preresults page
      cast = Tmdb.get_actors(@query.last.to_i)
      movies = Tmdb.get_movie_details(@query)
      @results = { cast: cast, movies: movies }
    end
    # @results = search_results(params[:search][:queries])
  end

  def search_results(query)
    # create a new search using the passed query
    search = Search.create(query: query)
    # return a Hash parsed from the response json
    JSON.parse(search.result.json)
  end

  def search_params
    # permit the passed query and photo from simpleform
    params.require(:search).permit(:query, :photo)
  end
end
