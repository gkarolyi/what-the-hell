require "open-uri"

class MovieRecommendation
  def self.call(movie)
    movie_url = "https://actorrecognition-tdevy3cs7a-ew.a.run.app/movie_recommender?movie=#{movie[:title]}"

    movie_response = URI.parse(movie_url).read
    JSON.parse(movie_response)
  end
end
