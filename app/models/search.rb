class Search < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :result, optional: true
  has_one_attached :photo
  before_create :julia_roberts
  # after_commit :async_update

  private

  def julia_roberts
    return unless query == "Julia Roberts"

    # creates a result for the current search with JR's details fetched from TMDB
    result_json = Tmdb.actor_details('1204')
    self.result = Result.create(json: result_json)
  end

  def async_update
    CallApiJob.perform_later(id)
  end
end
