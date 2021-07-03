class User < ApplicationRecord
  has_many :posts
  has_many :comments, foreign_key: "commenter_id"

  def recent_n_posts(n)
    Post.where(id: self.id).order(updated_at: :desc).limit(n)
  end
end
