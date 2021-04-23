require "open-uri"

class FaceRecognition
  @api_url = "https://wthactorsname-tdevy3cs7a-ew.a.run.app/find_actor_by_pic"

  def self.call(result_id)
    result = Result.find(result_id)
    response = URI.parse("#{@api_url}?url=#{cl_url(result.photo_key)}").read
    name = JSON.parse(response.string)["actor"]
    Tmdb.search_actor_name(name)
  end

  private

  def cl_url(key)
    Cloudinary::Utils.cloudinary_url(key)
  end
end
