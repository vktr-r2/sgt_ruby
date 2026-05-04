require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  describe "authentication token functionality" do
    describe "token generation on save" do
      it "does NOT auto-generate a token on save" do
        user = build(:user, authentication_token: nil)
        user.save!
        expect(user.authentication_token).to be_nil
      end
    end

    describe "#ensure_authentication_token!" do
      it "stores a SHA-256 hash (64 chars) in the DB" do
        user = create(:user)
        user.ensure_authentication_token!
        expect(user.authentication_token).to be_present
        expect(user.authentication_token.length).to eq(64)
      end

      it "exposes the plain 20-char token via #plain_token" do
        user = create(:user)
        user.ensure_authentication_token!
        expect(user.plain_token).to be_present
        expect(user.plain_token.length).to eq(20)
      end

      it "stored hash equals SHA-256 of the plain token" do
        user = create(:user)
        user.ensure_authentication_token!
        expect(user.authentication_token).to eq(Digest::SHA256.hexdigest(user.plain_token))
      end

      it "is a no-op when a token hash is already stored" do
        user = create(:user)
        user.ensure_authentication_token!
        original_hash = user.authentication_token

        user.ensure_authentication_token!
        expect(user.authentication_token).to eq(original_hash)
      end

      it "generates unique hashes for different users" do
        user1 = create(:user)
        user2 = create(:user)

        user1.ensure_authentication_token!
        user2.ensure_authentication_token!

        expect(user1.authentication_token).not_to eq(user2.authentication_token)
      end
    end

    describe "#rotate_authentication_token!" do
      it "generates a token when none exists" do
        user = create(:user)
        user.rotate_authentication_token!
        expect(user.plain_token).to be_present
        expect(user.plain_token.length).to eq(20)
      end

      it "replaces an existing token with a new one" do
        user = create(:user)
        user.ensure_authentication_token!
        original_hash = user.authentication_token

        user.rotate_authentication_token!

        expect(user.plain_token).to be_present
        user.reload
        expect(user.authentication_token).not_to eq(original_hash)
        expect(user.authentication_token).to eq(Digest::SHA256.hexdigest(user.plain_token))
      end

      it "always sets plain_token even on a freshly loaded instance" do
        user = create(:user)
        user.ensure_authentication_token!

        # Fresh DB load: @plain_token ivar is not set
        fresh = User.find(user.id)
        expect(fresh.plain_token).to be_nil

        fresh.rotate_authentication_token!
        expect(fresh.plain_token).to be_present
      end
    end

    describe ".find_by_token" do
      it "finds a user by their plain token" do
        user = create(:user)
        user.ensure_authentication_token!

        found = User.find_by_token(user.plain_token)
        expect(found).to eq(user)
      end

      it "returns nil for an invalid token" do
        expect(User.find_by_token("bogus_token")).to be_nil
      end

      it "returns nil for a blank token" do
        expect(User.find_by_token(nil)).to be_nil
        expect(User.find_by_token("")).to be_nil
      end
    end

    describe "authentication_token uniqueness" do
      it "ensures stored token hashes are unique" do
        existing_user = create(:user)
        existing_user.ensure_authentication_token!

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
