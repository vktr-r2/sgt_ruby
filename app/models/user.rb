class User < ApplicationRecord
  ADMIN_EMAILS = [ "vik.ristic@gmail.com" ]

  before_create :set_admin_status
  before_save :ensure_authentication_token

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true
  validates :authentication_token, uniqueness: true, allow_nil: true
  
  def ensure_authentication_token!
    self.authentication_token = generate_authentication_token if authentication_token.blank?
    save!
  end

  private
  
  def ensure_authentication_token
    self.authentication_token = generate_authentication_token if authentication_token.blank?
  end
  
  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end
  
  def set_admin_status
    self.admin = ADMIN_EMAILS.include?(email)
  end
end
