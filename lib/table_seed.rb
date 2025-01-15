class TableSeed
  def self.seed
    new.seed
  end

  def seed
    raise NotImplementedError, "You must implement the `seed` method"
  end
end
