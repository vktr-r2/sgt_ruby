module BusinessLogic
  class UserService
    def get_user_ids
      User.pluck(:id)
    end
  end
end
