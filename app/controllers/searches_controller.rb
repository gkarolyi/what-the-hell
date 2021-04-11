#require_relative "../services/tmdb.rb"
#require_relative "../services/movie_recommendation"

class SearchesController < ApplicationController
  skip_before_action :authenticate_user!

  def home
    # set instance vars from params
    set_instance_vars
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
      # if search contains a photo, attach an empty result to it and redirect
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
    # create a new result and attach it to this search
    # don't think we'll actually need this here at all
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
