fx_version 'cerulean'
game 'gta5'

author 'ZK'
description 'Tienda VIP Futurista'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/background.png'
}

-- Load config first
shared_scripts {
    'config.lua'
}

-- Then load the other scripts
client_scripts {
    'config.lua', -- Load config again to be sure
    'client.lua'
}

server_scripts {
    'config.lua', -- Load config again to be sure
    'server.lua'
}
