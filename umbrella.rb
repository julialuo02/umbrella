require "http"
require "json"
require "dotenv/load"

# Constants
LINE_WIDTH = 40
PRECIP_PROB_THRESHOLD = 0.10 # 10% precipitation threshold

# Prints a formatted header
def print_header
  puts "=" * LINE_WIDTH
  puts "Will you need an umbrella today?".center(LINE_WIDTH)
  puts "=" * LINE_WIDTH
  puts
end

# Gets the latitude and longitude for a location using the Google Maps API
def get_coordinates(user_location, gmaps_key)
  gmaps_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{user_location}&key=#{gmaps_key}"
  raw_gmaps_data = HTTP.get(gmaps_url)
  parsed_gmaps_data = JSON.parse(raw_gmaps_data)
  results_array = parsed_gmaps_data.fetch("results", [])

  if results_array.empty?
    puts "Could not find the location: #{user_location}. Please try again."
    exit
  end

  first_result_hash = results_array[0]
  location_hash = first_result_hash.dig("geometry", "location")
  [location_hash["lat"], location_hash["lng"]]
end

# Fetches weather data for given coordinates using the Pirate Weather API
def get_weather_data(latitude, longitude, pirate_weather_key)
  pirate_weather_url = "https://api.pirateweather.net/forecast/#{pirate_weather_key}/#{latitude},#{longitude}"
  raw_weather_data = HTTP.get(pirate_weather_url)
  JSON.parse(raw_weather_data)
end

# Checks precipitation probability for the next 12 hours and prints warnings
def check_precipitation(hourly_data_array)
  next_twelve_hours = hourly_data_array[1..12]
  any_precipitation = false

  next_twelve_hours.each_with_index do |hour_hash, index|
    precip_prob = hour_hash.fetch("precipProbability", 0)

    if precip_prob > PRECIP_PROB_THRESHOLD
      any_precipitation = true
      precip_time = Time.at(hour_hash["time"])
      hours_from_now = ((precip_time - Time.now) / 3600).round

      puts "In #{hours_from_now} hours, there is a #{(precip_prob * 100).round}% chance of precipitation."
    end
  end

  if any_precipitation
    puts "You might want to take an umbrella!"
  else
    puts "You probably won't need an umbrella."
  end
end

# Main Program
print_header

# Prompt user for location
print "Where are you? "
user_location = gets.chomp

# Load API keys
gmaps_key = ENV.fetch("GMAPS_KEY")
pirate_weather_key = ENV.fetch("PIRATE_WEATHER_KEY")

# Get coordinates
puts "Checking the weather at #{user_location}..."
latitude, longitude = get_coordinates(user_location, gmaps_key)
puts "Your coordinates are #{latitude}, #{longitude}."

# Get weather data
weather_data = get_weather_data(latitude, longitude, pirate_weather_key)

# Display current weather
current_temp = weather_data.dig("currently", "temperature")
puts "It is currently #{current_temp}°F."

# Display next-hour summary if available
next_hour_summary = weather_data.dig("minutely", "summary")
puts "Next hour: #{next_hour_summary}" if next_hour_summary

# Check precipitation for the next 12 hours
hourly_data_array = weather_data.dig("hourly", "data")
check_precipitation(hourly_data_array) if hourly_data_array
