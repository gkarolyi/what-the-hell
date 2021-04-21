class MovieRecommendationJob < ApplicationJob
  queue_as :default

  def perform(movie, query)
    recommendations = MovieRecommendation.call(movie)
    return if recommendations["ERROR"]

    BroadcastJob.perform_now(
      { channel: "MovieRecommendation",
        query: query,
        partial: "shared/cards/movie_reco",
        locals:
        { recommendations: Tmdb.recommendation_details(recommendations),
          base_movie: movie } }
    )
  end
end
