class Task < ApplicationRecord
  validates :title, presence: true
  belongs_to :user, optional: true

  enum status: {
    pending: 0,
    in_progress: 1,
    completed: 2
  }
end
