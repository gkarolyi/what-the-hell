require "open-uri"
require "benchmark"

class Tmdb
  class << self
    def top_actors(movie_id, top_n = 4)
      movie_cast(movie_id).sort { |b, a| a["popularity"] - b["popularity"] }
                          .first(top_n)
                          .map { |actor| Result.create(json: actor.to_json) }
    end

    def movie_details(movie_id)
      response = URI.parse(movie_url(movie_id)).read
      details = JSON.parse(response)
      important_details(details)
    end

    def each_movie_details(array_of_movie_ids)
      array_of_movie_ids.map do |id|
        Thread.new do
          movie_details(id)
        end
      end.map(&:value)
    end

    def matching_cast(movie_ids)
      movie_ids.last(2)
               .map do |id|
                 movie_cast(id.to_i).map { |actor| actor["id"] }
               end
               .reduce(&:&)
    end

    def actor_details(actor_id)
      url = "https://api.themoviedb.org/3/person/#{actor_id}?#{api_params}"
      begin
        URI.parse(url).read
      rescue OpenURI::HTTPError
        actor_not_found
      end
    end

    def movie_cast(movie_id)
      url = "https://api.themoviedb.org/3/movie/#{movie_id}/credits?#{api_params}"
      response = URI.parse(url).read
      cast = JSON.parse(response)["cast"]
      cast.select { |c| c["known_for_department"] == "Acting" }
    end

    def search_actor_name(query)
      url = "https://api.themoviedb.org/3/search/person?#{api_params}&query=#{query}&page=1"
      actor_id = JSON.parse(URI.parse(url).read)['results'][0]['id']
      actor_details(actor_id)
    end

    def recommendation_details(recommendations)
      recommendations.first(3).map do |rec|
        Thread.new do
          response = URI.parse(movie_search_url(rec[1])).read
          details = JSON.parse(response)['results'].first
          important_details(details)
        end
      end.map(&:value)
    end

    private

    def key
      ENV['TMDB_KEY']
    end

    def api_params
      "api_key=#{key}&language=en-US&include_adult=false"
    end

    def movie_url(movie_id)
      "https://api.themoviedb.org/3/movie/#{movie_id.to_i}?#{api_params}"
    end

    def movie_search_url(query)
      "https://api.themoviedb.org/3/search/movie?#{api_params}&query=#{query}"
    end

    def important_details(hash)
      {
        title: hash["title"],
        img_path: hash["poster_path"],
        description: hash["overview"],
        year: hash["release_date"]
      }
    end

    def actor_not_found
      { name: "NOT FOUND" }.to_json
    end
  end
end
