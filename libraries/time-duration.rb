module RelativeTime
  VALS = { "m" => (60), "h" => (60 * 60), "d" => (60 * 60 * 24) }
  def self.parse( str )
    return 0 if str.downcase == "forever"
    time = 0
    str.scan(/(\d+)(\w)/).each do |amount, measure|
      time += amount.to_i * VALS[measure]
    end
    return time
  end
end