class ClearPlainAuthenticationTokens < ActiveRecord::Migration[8.0]
  def up
    # Invalidate all existing plain-text tokens. Users will receive a fresh
    # hashed token on their next login.
    User.update_all(authentication_token: nil)
  end

  def down
    # Irreversible — plain tokens cannot be recovered
  end
end
