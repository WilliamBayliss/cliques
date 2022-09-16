class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates_format_of :username, with: /^[a-zA-Z0-9_\.]*$/, :multiline => true

  has_many :posts
  has_many :comments

  has_many :memberships, -> { where accepted: true }
  has_many :membership_requests, -> { where accepted: false }, class_name: "Membership"
  has_many :cliques, through: :memberships, as: :member

  has_many :adminships
  has_many :adminship_requests, -> { where accepted: false }, class_name: "Adminship"
  has_many :admin_cliques, through: :adminships, as: :administrator, source: "clique"

  acts_as_voter
  
  attr_writer :login

  def login
    @login || self.username || self.email
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    elsif conditions.has_key?(:username) || conditions.has_key?(:email)
      conditions[:email].downcase! if conditions[:email]
      where(conditions.to_h).first
    end
  end

  def update_reputation
    reputation = 0
    self.posts.each do |post|
      reputation += post.cached_votes_score
    end
    self.reputation = reputation
    self.save
  end
  private
end
