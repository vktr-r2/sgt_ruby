module BusinessLogic
  class TiebreakerService
    # Compares two user data hashes using the agreed tie-break rules.
    # Returns: -1 if user_a wins, 1 if user_b wins, 0 if completely tied.
    #
    # Expected keys in each data hash:
    #   golfer_totals:  [Integer, ...] sorted ascending (best/lowest first), up to 8 elements
    #   drafted_winner: Boolean — did this user draft the tournament winner?
    def self.compare(user_a_data, user_b_data)
      new(user_a_data, user_b_data).compare
    end

    def initialize(user_a_data, user_b_data)
      @a = user_a_data
      @b = user_b_data
    end

    def compare
      # Rule a: best individual golfer total
      result = compare_golfer_at_index(0)
      return result unless result == 0

      # Rule b: did one user pick the tournament winner?
      result = compare_winner_picked
      return result unless result == 0

      # Rules c-e: 2nd, 3rd, 4th best golfer totals
      (1..3).each do |i|
        result = compare_golfer_at_index(i)
        return result unless result == 0
      end

      # Rule f: complete tie
      0
    end

    private

    def compare_golfer_at_index(i)
      a_total = @a[:golfer_totals][i] || Float::INFINITY
      b_total = @b[:golfer_totals][i] || Float::INFINITY
      a_total <=> b_total
    end

    def compare_winner_picked
      a_picked = @a[:drafted_winner] ? 1 : 0
      b_picked = @b[:drafted_winner] ? 1 : 0
      b_picked <=> a_picked
    end
  end
end
