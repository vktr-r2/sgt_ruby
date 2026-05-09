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

  TOKEN_TTL = 2.weeks

  # Clears any existing token and generates a fresh one. Always call this on
  # login so a stale DB token never silences plain_token.
  def rotate_authentication_token!
    update_columns(authentication_token: nil, token_expires_at: nil) if authentication_token.present?
    ensure_authentication_token!
  end

  # Generates a plain token, stores its SHA-256 hash in the DB, sets a 2-week
  # expiry, and exposes the plain token via #plain_token for the duration of
  # this object's lifetime. No-op if a valid unexpired token is already stored.
  def ensure_authentication_token!
    return if authentication_token.present? && token_expires_at&.future?

    loop do
      plain = Devise.friendly_token
      hashed = Digest::SHA256.hexdigest(plain)
      next if User.where.not(id: id).exists?(authentication_token: hashed)

      update_columns(authentication_token: hashed, token_expires_at: TOKEN_TTL.from_now)
      @plain_token = plain
      break
    end
  end

  # Looks up a user by hashing the incoming bearer token, checking expiry.
  # Returns nil for blank, unknown, or expired tokens.
  def self.find_by_token(token)
    return nil if token.blank?

    user = find_by(authentication_token: Digest::SHA256.hexdigest(token))
    return nil if user.nil?
    return nil if user.token_expires_at.nil? || user.token_expires_at.past?

    user
  end

  private

  def set_admin_status
    self.admin = ADMIN_EMAILS.include?(email)
  end
end
