require "open-uri"

class MovieRecommendation
  def self.call(movie)
    movie_url = "https://actorrecognition-tdevy3cs7a-ew.a.run.app/movie_recommender?movie=#{movie[:title]}"

    response = URI.parse(movie_url).read
    recommendations = JSON.parse(response)
    return if recommendations["ERROR"]

    Tmdb.recommendation_details(recommendations.values)
  end
end
