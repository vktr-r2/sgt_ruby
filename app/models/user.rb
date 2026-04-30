class User < ApplicationRecord
  ADMIN_EMAILS = [ "vik.ristic@gmail.com" ]

  before_create :set_admin_status

  # Include default devise modules. Others available are:
  # :confirmable, :timeoutable, :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :trackable

  # Associations
  has_many :match_picks, dependent: :destroy
  has_many :match_results, dependent: :destroy

  validates :name, presence: true
  validates :authentication_token, uniqueness: true, allow_nil: true

  # Plain token is held in memory only — never persisted. Available immediately
  # after ensure_authentication_token! is called; nil on any subsequent reload.
  attr_reader :plain_token

  # Generates a plain token, stores its SHA-256 hash in the DB, and exposes
  # the plain token via #plain_token for the duration of this object's lifetime.
  # No-op if a token hash is already stored.
  def ensure_authentication_token!
    return if authentication_token.present?

    loop do
      plain = Devise.friendly_token
      hashed = Digest::SHA256.hexdigest(plain)
      next if User.where.not(id: id).exists?(authentication_token: hashed)

      update_column(:authentication_token, hashed)
      @plain_token = plain
      break
    end
  end

  # Looks up a user by hashing the incoming bearer token and comparing to stored hash.
  def self.find_by_token(token)
    return nil if token.blank?

    find_by(authentication_token: Digest::SHA256.hexdigest(token))
  end

  private

  def set_admin_status
    self.admin = ADMIN_EMAILS.include?(email)
  end
end
