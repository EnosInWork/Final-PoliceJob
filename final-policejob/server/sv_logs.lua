WebHook = "https://discord.com/api/webhooks/855123504865476689/q0quAwu253iuxjDsioMrbFtcg7SdIWnEGSQdxRjl7Sb8DusRc7FBgPlPnWv8CHZgwncd"
WebHook2 = "https://discord.com/api/webhooks/855123545935970374/sHCxiLmFB_9pBCj8ZHrluLqbO7OG4s66Bxh5e0B0TmDvp0GyGz5nqPUuWro8FDX9E7H4"
Name = "Five-Dev"
Logo = "https://resize-europe1.lanmedia.fr/r/622,311,forcex,center-middle/img/var/europe1/storage/images/europe1/international/le-panda-geant-nest-plus-en-danger-mais-reste-menace-2837755/28733065-1-fre-FR/Le-panda-geant-n-est-plus-en-danger-mais-reste-menace.jpg" -- He must finish by .png or .jpg
LogsBlue = 3447003
LogsRed = 15158332
LogsYellow = 15844367
LogsOrange = 15105570
LogsGrey = 9807270
LogsPurple = 10181046
LogsGreen = 3066993
LogsLightBlue = 1752220

RegisterNetEvent('Ise_Logs')
AddEventHandler('Ise_Logs', function(Webhook, Color, Title, Description)
	Ise_Logs(Webhook, Color, Title, Description)
end)

function Ise_Logs(webhook, Color, Title, Description)
	local Content = {
	        {
	            ["color"] = Color,
	            ["title"] = Title,
	            ["description"] = Description,
		        ["footer"] = {
	                ["text"] = Name,
	                ["icon_url"] = Logo,
	            },
	        }
	    }
	PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({username = Name, embeds = Content}), { ['Content-Type'] = 'application/json' })
end

--Ise_Logs(LogsGreen, "Serveur démarré", "Aucun soucis visible, tout est bon capitaine.")

AddEventHandler('playerDropped', function(reason)
	local identifier
	local steam
	local playerId = source
	local PcName = GetPlayerName(playerId)
	for k,v in ipairs(GetPlayerIdentifiers(playerId)) do
		if string.match(v, 'license:') then
			identifier = string.sub(v, 9)
			break
		end
	end
	for k,v in ipairs(GetPlayerIdentifiers(playerId)) do
		if string.match(v, 'steam:') then
			steam = string.sub(v, 7)
			break
		end
	end
	Ise_Logs(LogsRed, "Deconnexion du serveur", "Nom : "..PcName.."\nLicense : license:"..identifier.."\nSteam : steam:"..steam.."\nRaison : "..reason)
end)



AddEventHandler("playerConnecting", function ()
	local identifier
	local steam
	local playerId = source
	local PcName = GetPlayerName(playerId)
	for k,v in ipairs(GetPlayerIdentifiers(playerId)) do
		if string.match(v, 'license:') then
			identifier = string.sub(v, 9)
			break
		end
	end
	for k,v in ipairs(GetPlayerIdentifiers(playerId)) do
		if string.match(v, 'steam:') then
			steam = string.sub(v, 7)
			break
		end
	end
	Ise_Logs(LogsGreen, "Connexion au serveur", "Nom : "..PcName.."\nLicense : license:"..identifier.."\nSteam : steam:"..steam.."")
end)
