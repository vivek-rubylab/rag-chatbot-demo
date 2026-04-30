class AiResponseJob < ApplicationJob
  queue_as :default

  def perform(chat_id, user_message_id)
    chat         = Chat.find(chat_id)
    user_message = chat.messages.find(user_message_id)
    stream_id    = "streaming-#{chat.id}"
    text_id      = "#{stream_id}-text"

    # Replace thinking dots with a stable streaming bubble shell (created once)
    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{chat.id}",
      target: "chat-thinking",
      html:   streaming_bubble(stream_id, text_id)
    )

    # Each delta is APPENDED as a new fading span — existing text is never touched
    assistant_message = ChatResponder.new(chat, user_message).call do |delta|
      Turbo::StreamsChannel.broadcast_append_to(
        "chat_#{chat.id}",
        target: text_id,
        html:   delta_span(delta)
      )
    end

    # Swap the whole streaming bubble for the final markdown-rendered partial
    if assistant_message
      html = ApplicationController.render(
        partial: "chats/message",
        locals:  { message: assistant_message }
      )
      Turbo::StreamsChannel.broadcast_replace_to(
        "chat_#{chat.id}",
        target: stream_id,
        html:   html
      )
    else
      Turbo::StreamsChannel.broadcast_remove_to("chat_#{chat.id}", target: stream_id)
    end

  rescue => e
    Rails.logger.error "[AiResponseJob] FAILED: #{e.class} — #{e.message}\n#{e.backtrace.first(10).join("\n")}"
    Turbo::StreamsChannel.broadcast_remove_to("chat_#{chat_id}", target: "chat-thinking")
    Turbo::StreamsChannel.broadcast_remove_to("chat_#{chat_id}", target: "streaming-#{chat_id}")
    raise
  end

  private

  # The outer bubble shell — created once, never replaced during streaming.
  def streaming_bubble(dom_id, text_id)
    <<~HTML
      <div id="#{dom_id}" class="msg msg--assistant">
        <div class="msg-avatar msg-avatar--bot">🤖</div>
        <div class="msg-body">
          <div class="msg-bubble msg-bubble--streaming">
            <span id="#{text_id}" class="stream-text"></span>
          </div>
          <div class="msg-time">…</div>
        </div>
      </div>
    HTML
  end

  # Each delta chunk becomes a span that fades in — newlines become breaks.
  def delta_span(text)
    safe = ERB::Util.html_escape(text).gsub("\n", "<br>")
    %(<span class="stream-token">#{safe}</span>)
  end
end
