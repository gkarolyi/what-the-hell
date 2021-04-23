class MovieInfo
  def self.call(query)
    Tmdb.each_movie_details(query)
  end
end
