class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat

  # POST /chats/:chat_id/messages
  def create
    content = message_params[:content].to_s.strip

    if content.blank?
      return render_error("Message cannot be blank.")
    end

    if content.length > 1000
      return render_error("Message cannot exceed 1,000 characters.")
    end

    @message = @chat.messages.create!(role: "user", content: content)
    AiResponseJob.perform_later(@chat.id, @message.id)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @chat }
    end
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end

  def render_error(text)
    @error = text
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("chat-error",
                 partial: "chats/error", locals: { error: @error }),
               status: :unprocessable_entity
      end
      format.html { redirect_to @chat, alert: text }
    end
  end
end
