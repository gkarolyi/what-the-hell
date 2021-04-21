class CastMatcherJob < ApplicationJob
  queue_as :default

  def perform(query)
    sleep 0.5
    @query = query
    actor_ids = Tmdb.matching_cast(@query)
    if @query.count > 1 && actor_ids.one?
      # if we have 2 movie inputs and one matching actor
      broadcast_final(Result.create(json: actor_ids.first))
    elsif query.count > 1 && actor_ids.count > 1
      # if we have 2 movie inputs and several matching actors
      broadcast_subtitle(common_actors: true)
      actor_ids.map { |actor_id| Result.create(json: Tmdb.actor_details(actor_id)) }
               .each { |actor| broadcast(actor) }
    else
      # if there is only 1 movie input or no matching actors display preresults page
      if @query.one?
        broadcast_subtitle({ common_actors: 'single-movie' }, common_actors: 'single-movie')
      else
        broadcast_subtitle({ common_actors: true }, common_actors: false)
      end
      Tmdb.top_actors(query.last.to_i).each { |actor| broadcast(actor) }
    end
  end

  private

  def broadcast_subtitle(attr_hash, common_actors: true)
    BroadcastJob.perform_now(
      { channel: "CastMatcher",
        query: @query,
        partial: "shared/text/cast_subtitle",
        attr: attr_hash,
        locals: { subtitle: true, common_actors: common_actors } }
    )
  end

  def broadcast_final(actor)
    BroadcastJob.perform_now(
      { channel: "CastMatcher",
        query: @query,
        response: { result: true, actor: actor } }
    )
  end

  def broadcast(actor)
    BroadcastJob.perform_now(
      { channel: "CastMatcher",
        query: @query,
        partial: "shared/cards/actor_card",
        locals: { actor: actor } }
    )
  end
end
