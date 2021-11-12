fx_version 'adamant'

game 'gta5'

client_scripts {"lib/RMenu.lua","lib/menu/RageUI.lua","lib/menu/Menu.lua","lib/menu/MenuController.lua","lib/components/*.lua","lib/menu/elements/*.lua","lib/menu/items/*.lua","lib/menu/panels/*.lua","lib/menu/panels/*.lua","lib/menu/windows/*.lua"}

client_scripts {'@es_extended/locale.lua','client/*.lua','config.lua'}

server_scripts {'@mysql-async/lib/MySQL.lua','@es_extended/locale.lua','server/*.lua','config.lua'}

dependencies {'es_extended'}