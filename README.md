# XYZ Daily Reward

A free FiveM daily reward script with a modern UI, SQL saving, and improved server-side protection.

## Features

* Modern custom UI
* Daily reward claiming system
* SQL data saving
* Configurable rewards
  
## Security

* Session and token validation
* Nonce-based claim protection
* Anti spam protection
* Anti double-claim protection
* Server-side reward validation
* Safer reward delivery flow

## Notes

* The webhook is stored server-side only
* Rewards are handled on the server
* Designed to be simple to configure and easy to use

## Requirements

* oxmysql
* ox_inventory
* xyz_lib
## Installation

1. Download the script
2. Put it into your resources folder
3. Import the SQL table automatically by starting the resource
4. Configure your rewards in `config.lua`
5. Add your webhook to `server_config.lua`
6. Ensure the resource in your server config

## Configuration

* Edit `config.lua` for rewards and general settings
* Edit `server_config.lua` for the webhook
