# frozen_string_literal: true
require "mcp"
require "net/http"
require "json"
require "uri"
require "base64"

name    "poke-api"
version "0.1.0"

API_BASE = "https://pokeapi.co/api/v2"
# Maximum Pokemon ID (as of April 2025)
MAX_POKEMON_ID = 1025

def fetch_json(path)
  uri = URI("#{API_BASE}/#{path}")
  begin
    response = Net::HTTP.get_response(uri)

    unless response.is_a?(Net::HTTPSuccess)
      return { error: "Pokemon not found: #{path}", status: response.code } if response.code == "404"
      return { error: "API request failed: #{response.code} #{response.message}", status: response.code }
    end

    JSON.parse(response.body, symbolize_names: true)

  rescue JSON::ParserError => e
    { error: "Failed to parse API response: #{e.message}" }
  rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
         Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, Errno::ECONNREFUSED => e
    { error: "Network error communicating with PokeAPI: #{e.class} - #{e.message}" }
  rescue StandardError => e
    { error: "An unexpected error occurred: #{e.class} - #{e.message}" }
  end
end

def format_pokemon_data(data)
  return data[:error] if data[:error] # Return error if exists

  types_str = data[:types].map { |t| t.dig(:type, :name) }.join(", ")
  sprite_url = data.dig(:sprites, :front_default)

  # 画像データの取得とBase64エンコード
  image_markdown = ""
  if sprite_url
    begin
      uri = URI(sprite_url)
      image_data = Net::HTTP.get(uri)
      base64_data = Base64.strict_encode64(image_data)
      image_markdown = "\n![#{data[:name]}](data:image/png;base64,#{base64_data})"
    rescue => e
      image_markdown = "\nImage Error: #{e.message}"
    end
  end

  <<~POKEMON
    ID: #{data[:id]}
    Name: #{data[:name].capitalize}
    Height: #{data[:height]}
    Weight: #{data[:weight]}
    Types: #{types_str}#{image_markdown}
  POKEMON
end

# --- Resource Templates ---
# ------------------------------------------------------------------
# Resource Template: Individual Pokemon Information
# ------------------------------------------------------------------
resource_template "pokemon://{name_or_id}" do
  name        "Pokémon basic information"
  description "Basic data (id, name, height, weight, types) for a given Pokémon"
  # mime_type "text/plain" # (default)

  call do |args|
    # args is a hash like { name_or_id: "value" }
    name_or_id = args[:name_or_id]
    data = fetch_json("pokemon/#{name_or_id}")
    format_pokemon_data(data) # Returns formatted string
  end
end

# --- Resources ---
# ------------------------------------------------------------------
# Resource: Random Pokemon Information
# ------------------------------------------------------------------
resource "pokemon://random" do
  name        "Random Pokémon"
  description "Return basic information about a random Pokémon"
  # mime_type "text/plain" # (default)

  call do
    random_id = rand(1..MAX_POKEMON_ID)
    data = fetch_json("pokemon/#{random_id}")
    format_pokemon_data(data) # Returns formatted string
  end
end

# --- Tools ---
# ------------------------------------------------------------------
# Tool: pokemon_info
# ------------------------------------------------------------------
tool "pokemon_info" do
  description "Retrieve basic information (id, name, height, weight, types) of a Pokémon."

  argument :name_or_id, String,
           required:    true,
           description: "Pokémon name or ID"

  call do |args|
    # Call helper directly
    data = fetch_json("pokemon/#{args[:name_or_id]}")
    format_pokemon_data(data) # Returns formatted string
  end
end

# ------------------------------------------------------------------
# Tool: pokemon_sprite
# ------------------------------------------------------------------
tool "pokemon_sprite" do
  description "Get the front-default sprite image URL of a Pokémon, potentially formatted for display."

  argument :name_or_id, String,
           required:    true,
           description: "Pokémon name or ID"

  call do |args|
    data = fetch_json("pokemon/#{args[:name_or_id]}")

    return { error: "Pokemon data not found: #{data[:error]}" }.to_json if data[:error]

    sprite_url = data.dig(:sprites, :front_default)

    unless sprite_url
      return { error: "Sprite not available for #{args[:name_or_id]}" }.to_json
    end

    begin
      # 画像データを取得
      uri = URI(sprite_url)
      image_data = Net::HTTP.get(uri)

      # Base64エンコード
      base64_data = Base64.strict_encode64(image_data)

      # Markdown形式で画像を表示するためのデータを返す
      {
        name: data[:name],
        id: data[:id],
        url: sprite_url,
        base64_data: base64_data,
        content_type: "image/png",
        markdown: "![#{data[:name]}](data:image/png;base64,#{base64_data})"
      }.to_json
    rescue => e
      { error: "Failed to encode sprite: #{e.message}" }.to_json
    end
  end
end

# ------------------------------------------------------------------
# Tool: pokemon_sprite_url
# ------------------------------------------------------------------
tool "pokemon_sprite_url" do
  description "Get only the raw URL of a Pokémon sprite without encoding."

  argument :name_or_id, String,
           required:    true,
           description: "Pokémon name or ID"

  call do |args|
    data = fetch_json("pokemon/#{args[:name_or_id]}")

    return "Error fetching Pokemon data: #{data[:error]}" if data[:error]

    sprite_url = data.dig(:sprites, :front_default)

    if sprite_url
      sprite_url
    else
      "Sprite not available for #{args[:name_or_id]}"
    end
  end
end
