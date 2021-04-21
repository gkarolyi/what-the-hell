class ActorDetailsJob < ApplicationJob
  queue_as :default

  def perform(result)
    actor_id = result.json.is_a?(Integer) ? result.json : result.details["id"]
    json_response = Tmdb.actor_details(actor_id)
    result.update(json: json_response)
  end
end
 