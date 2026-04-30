class EnablePgvector < ActiveRecord::Migration[8.0]
  def change
    enable_extension "vector"
    enable_extension "pg_trgm"
  end
end
