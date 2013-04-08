COUNT = Transform /^\d+$/ do |str|
  str.to_i
end

DATE = Transform /^(20\d{2})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) (\+\d+)?$/ do |year, month, day, hour, minute, second, tz|
  Time.new(year.to_i, month.to_i, day.to_i, hour.to_i, minute.to_i, second.to_i, tz)
end
