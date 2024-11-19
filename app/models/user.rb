class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable
  has_many :sent_messages, class_name: 'Message', foreign_key: 'sender_id', dependent: :destroy
  has_many :received_messages, class_name: 'Message', foreign_key: 'recipient_id', dependent: :destroy

    validates :name, presence: true
    validates :email, presence: true, uniqueness: true
    validates :password, presence: true
    validates :age, presence: true
    validates :level, presence: true
    validates :bio, presence: true
    validates :image, presence: true
    validates :authentication_token, presence: true, uniqueness: true

    before_create :generate_authentication_token
    before_validation :ensure_authentication_token, on: :create

    def ensure_authentication_token
        self.authentication_token ||= generate_authentication_token
    end

    def destroy_messages
        Message.where('sender_id = ? OR recipient_id = ?', id, id).destroy_all
    end


    private

    def generate_authentication_token
        puts "In generate_authentication_token"
        loop do
            token = SecureRandom.hex(20)
            break token unless User.where(authentication_token: token).exists?
        end
    end
end
