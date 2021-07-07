class Page < ActiveRecord::Base
  belongs_to :organization


  scope :ordered, -> { order('position asc') }
  scope :published, -> { where(published: true).ordered }
  scope :show_in_menu, -> { where(show_in_menu: true).published }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: { scope: :organization_id }
  validates :body, presence: true

  before_save do
    self.slug = self.slug.parameterize
  end

  def to_param
    self.slug.to_s
  end

  def to_s
    self.title.to_s
  end
end
