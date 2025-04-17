# PokeAPI MCP Server

This project is an MCP server built with [mcp_rb](https://github.com/funwarioisii/mcp-rb) for retrieving Pokémon information. It utilizes the PokeAPI to fetch various Pokémon data and provides a simple interface for Claude to interact with the Pokémon database.

## Features

- Retrieve basic Pokémon information (ID, name, height, weight, types)
- Get Pokémon sprite image URLs
- Fetch random Pokémon information

## Setup

1. First, install the required gems:
```bash
bundle install
```

2. Start the MCP server:
```bash
ruby poke_api.rb
```

## Usage

### Claude Desktop Configuration

Add the following configuration to your Claude Desktop config file (typically located at `~/.config/claude-desktop/config.json` or `~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "local": {
      "command": "ruby",
      "args": ["/path/to/your/poke_api.rb"],
      "env": {
        "RUBY_ENV": "development"
      },
      "disabled": false,
      "alwaysAllow": ["pokemon_info", "pokemon_sprite"]
    }
  }
}
```

Note: Replace `/path/to/your/poke_api.rb` with the actual path to your `poke_api.rb` file.

### Available Tools

1. `pokemon_info`
   - Retrieves basic Pokémon information
   - Argument: `name_or_id` (Pokémon name or ID)

2. `pokemon_sprite`
   - Gets Pokémon sprite image URL
   - Argument: `name_or_id` (Pokémon name or ID)

## Example

```ruby
# Get Pikachu's information
pokemon_info("pikachu")

# Get Pikachu's sprite image URL
pokemon_sprite("pikachu")
```

## Dependencies

- Ruby
- mcp gem
- net/http
- json
- uri

## License

MIT License

We hope this README helps you understand and use the project effectively. 