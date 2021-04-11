class MovieInfoJob < ApplicationJob
  queue_as :default

  def perform(query)
    sleep 0.5
    movies = Tmdb.get_movie_details(query)
    movies.each do |movie|
      BroadcastJob.perform_now(
        { channel: "MovieInfo",
          query: query,
          partial: "shared/cards/movie_card",
          locals: { movie: movie } }
      )
      MovieRecommendationJob.perform_now(movie, query) if movie == movies.last
    end
  end
end
