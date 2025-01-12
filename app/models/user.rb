class User < ApplicationRecord
  ADMIN_EMAILS = [ "vik.ristic@gmail.com" ]

  before_create :set_admin_status

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true

  private
  def set_admin_status
    self.admin = ADMIN_EMAILS.include?(email)
  end
end
