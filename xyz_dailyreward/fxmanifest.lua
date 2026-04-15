fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'XYZ DEVELOPMENT'
description 'Advanced Daily Reward System'
version '1.0.0'

ui_page 'html/ui.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server_config.lua',
    'server/server.lua'
}

files {
    'html/ui.html'
}

dependencies {
    'ox_inventory',
    'ox_lib',
    'oxmysql'
}