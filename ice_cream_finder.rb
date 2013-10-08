require 'json'
require 'rest-client'
require 'addressable/uri'
require 'nokogiri'


# get user location
# get desired radius (in miles; we'll convert to meters)

def directions_to_ice_cream
  puts "Please enter your full address."
  user_address = gets.chomp
  puts "How far in miles are you willing to go?"
  radius = gets.chomp.to_f * 1609.34

  user_location = coordinates(user_address)
  places = ice_cream_places(user_location, radius)
  display_places(places)
  puts "Please enter the number of the place you would like to go"
  place = gets.chomp.to_i-1
  end_address = places[places.keys[place]]
  puts directions(user_location, end_address)
end

def display_places(places)
  places.keys.each_with_index { |place, index| puts "#{index+1}. #{place}" }
end

# use Geocoding API to turn the user location into a latitude/longitude

def coordinates(user_address)
  geocoding_url = Addressable::URI.new(
     :scheme => "https",
     :host => "maps.googleapis.com",
     :path => "maps/api/geocode/json",
     :query_values => {:address => user_address,
                       :sensor => false}
   ).to_s

  response = JSON.parse(RestClient.get(geocoding_url))
  location = response["results"][0]["geometry"]["location"]
  location_string = "#{location["lat"]},#{location["lng"]}"
end

# use the Places API to get all ice cream places within radius of location

def ice_cream_places(location, radius)
  places_url = Addressable::URI.new(
    :scheme => "https",
    :host => "maps.googleapis.com",
    :path => "maps/api/place/nearbysearch/json",
    :query_values => {:key => "AIzaSyC3od3aEKzgeEb8H3_6b29HX3qHXWIB248",
                      :location => location,
                      :radius => radius,
                      :sensor => false,
                      :keyword => "ice cream"}
   ).to_s

  response = JSON.parse(RestClient.get(places_url))["results"]
  all_locations = {}
  response.each do |place|
    name = place["name"]
    location = place["geometry"]["location"]
    location_string = "#{location["lat"]},#{location["lng"]}"
    all_locations[name] = location_string
  end
  all_locations
end

# use the Directions API to get directions for each ice cream place

def directions(user_address, end_address)
  directions_url = Addressable::URI.new(
     :scheme => "https",
     :host => "maps.googleapis.com",
     :path => "maps/api/directions/json",
     :query_values => {:origin => user_address,
                       :destination => end_address,
                       :sensor => false}
   ).to_s

   legs = JSON.parse(RestClient.get(directions_url))["routes"][0]["legs"]

   directions = legs[0]["start_address"] + "\n"
   steps = legs[0]["steps"]
   steps.each do |step|
     directions += "#{Nokogiri::HTML(step["html_instructions"]).text} " +
                   "[#{step["distance"]["text"]}]\n"
   end
   directions += legs[0]["end_address"]
end

directions_to_ice_cream