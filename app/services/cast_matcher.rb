class CastMatcher
  class << self
    def call(query)
      return Tmdb.top_actors(query.last.to_i) if query.one?

      actor_ids = Tmdb.matching_cast(query)
      return actor_details(actor_ids.first).value if query.count > 1 && actor_ids.one?

      return Tmdb.top_actors(query.last.to_i) if actor_ids.empty?

      actor_ids.map do |actor_id|
        actor_details(actor_id)
      end.map(&:value)
    end

    private

    def actor_details(actor_id)
      Thread.new { Tmdb.actor_details(actor_id) }
    end
  end
end
