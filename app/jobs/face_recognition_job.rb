require "open-uri"

class FaceRecognitionJob < ApplicationJob
  queue_as :default

  def perform(api_url, id)
    result = Result.find(id)
    puts "#{api_url}?url=#{cl_url(result.photo_key)}"
    response = URI.open("#{api_url}?url=#{cl_url(result.photo_key)}")
    name = JSON.parse(response.string)["actor"]
    result.update(
      json: Tmdb.search_actor_name(name)
    )
    response = ApplicationController.renderer.render_to_string(
      partial: "shared/views/final_result",
      locals: { result: result },
    )
    ActionCable.server.broadcast("FaceRecognition_result_#{result.id}", { response: response })
  end

  private

  def cl_url(key)
    Cloudinary::Utils.cloudinary_url(key)
  end
end
