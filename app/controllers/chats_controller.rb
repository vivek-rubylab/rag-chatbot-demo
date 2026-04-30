class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: %i[show]

  # GET / — list chats or redirect straight into the most recent one
  def index
    @chats = current_user.chats.order(created_at: :desc)
  end

  # POST /chats
  def create
    @chat = current_user.chats.create!(
      model_id: ENV.fetch("LLM_MODEL", ChatResponder::DEFAULT_MODEL)
    )
    redirect_to @chat
  end

  # GET /chats/:id
  def show
    @messages = @chat.messages.where(role: %w[user assistant]).order(:created_at)
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end
end
