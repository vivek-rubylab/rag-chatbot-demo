class Chat < ApplicationRecord
  acts_as_chat

  belongs_to :user
  has_many :messages, dependent: :destroy
end
