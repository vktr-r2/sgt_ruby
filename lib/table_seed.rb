class TableSeed
  def self.seed
    new.seed_with_handling
  end

  def seed_with_handling
    begin
      seed
    rescue StandardError => e
      puts "Error while seeding #{self.class.name}: #{e.message}"
    end
  end

  # Child classes will override this method
  def seed
    raise NotImplementedError, "You must implement the `seed` method in #{self.class.name}"
  end
end
