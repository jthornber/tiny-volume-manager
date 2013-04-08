class VolumeId
  def initialize
    @id = random_hex_digits(16)
  end

  def to_s
    @id
  end

  private
  def random_hex_digits(n)
    r = String.new

    1.upto(n) do
      r += new_char
    end

    r
  end

  DIGITS = %w(0 1 2 3 4 5 6 7 8 9 a b c d e f)

  def new_char
    DIGITS[rand(15)]
  end
end
