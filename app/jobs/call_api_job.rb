class CallApiJob < ApplicationJob
  queue_as :default

  def perform(search_id)
    search = Search.find(search_id)
    result_json = Tmdb.actor_details('1204')
    search.update(result: Result.create(json: result_json))
  end
end
