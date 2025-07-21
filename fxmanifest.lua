fx_version 'cerulean'
game 'gta5'
lua54 'yes'


author 'huzo'
description 'Boss menu + Gun Locker + Shop Integrated into 1 menu.'

shared_scripts {
    "config.lua",
}

client_scripts {
	"@ox_lib/init.lua",
	"client/functions.lua",
    "client/client.lua",
}

server_scripts {
	"server/server.lua",
	"server/sConfig.lua",
}
