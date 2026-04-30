module ApplicationHelper
  # Renders basic markdown to safe HTML — covers bold, italic, and line breaks.
  def chat_markdown(text)
    return "" if text.blank?
    html = ERB::Util.html_escape(text.to_s)
    html = html.gsub(/\*\*(.+?)\*\*/m, '<strong>\1</strong>')
    html = html.gsub(/\*(.+?)\*/m,     '<em>\1</em>')
    html = html.gsub(/\n\n+/, '</p><p>')
    html = html.gsub(/\n/, '<br>')
    "<p>#{html}</p>".html_safe
  end
end
