class User < ApplicationRecord
  attr_accessor :skip_password_validation
  # attr_accessor :expo_push_token


  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable
  has_many :sent_messages, class_name: 'Message', foreign_key: 'sender_id', dependent: :destroy
  has_many :received_messages, class_name: 'Message', foreign_key: 'recipient_id', dependent: :destroy
  has_one :runner_profile, dependent: :destroy
  has_many :notifications, dependent: :destroy


    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :email, presence: true,
                      uniqueness: true,
                      format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, presence: true, unless: :skip_password_validation
    validates :age, presence: true
    validates :bio, presence: true
    validates :profile_image, presence: true
    validates :authentication_token, presence: true, uniqueness: true

    before_create :generate_authentication_token
    before_validation :ensure_authentication_token, on: :create

    def ensure_authentication_token
        if authentication_token.blank?
            self.authentication_token = generate_authentication_token
            save(validate: false)
        end
        authentication_token
    end

    def destroy_messages
        Message.where('sender_id = ? OR recipient_id = ?', id, id).destroy_all
    end


    private

    def generate_authentication_token
        loop do
            token = SecureRandom.hex(20)
            break token unless User.where(authentication_token: token).exists?
        end
    end
end
