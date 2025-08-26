require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  describe "authentication token functionality" do
    describe "automatic token generation" do
      it "generates an authentication token on save if none exists" do
        user = build(:user, authentication_token: nil)
        expect(user.authentication_token).to be_nil
        
        user.save!
        expect(user.authentication_token).to be_present
        expect(user.authentication_token.length).to eq(20)
      end

      it "does not change existing authentication token on save" do
        user = create(:user, authentication_token: "existing_token_123")
        original_token = user.authentication_token
        
        user.update!(name: "Updated Name")
        expect(user.authentication_token).to eq(original_token)
      end
    end

    describe "#ensure_authentication_token!" do
      it "generates an authentication token if none exists" do
        user = create(:user)
        user.update_column(:authentication_token, nil) # Bypass callbacks
        
        expect { user.ensure_authentication_token! }
          .to change { user.reload.authentication_token }.from(nil)
        expect(user.authentication_token).to be_present
        expect(user.authentication_token.length).to eq(20)
      end

      it "does not change existing authentication token" do
        user = create(:user)
        original_token = user.authentication_token
        
        expect { user.ensure_authentication_token! }
          .not_to change { user.authentication_token }
        expect(user.authentication_token).to eq(original_token)
      end

      it "generates unique tokens for different users" do
        user1 = create(:user)
        user2 = create(:user)
        
        user1.update_column(:authentication_token, nil)
        user2.update_column(:authentication_token, nil)
        
        user1.ensure_authentication_token!
        user2.ensure_authentication_token!
        
        expect(user1.authentication_token).not_to eq(user2.authentication_token)
      end
    end

    describe "authentication_token uniqueness" do
      it "ensures authentication tokens are unique" do
        existing_user = create(:user)
        new_user = build(:user)
        new_user.authentication_token = existing_user.authentication_token
        
        expect(new_user).not_to be_valid
        expect(new_user.errors[:authentication_token]).to include("has already been taken")
      end

      it "allows nil authentication tokens" do
        user1 = build(:user, authentication_token: nil)
        user2 = build(:user, authentication_token: nil)
        
        expect(user1).to be_valid
        expect(user2).to be_valid
      end
    end
  end

  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
  end
end