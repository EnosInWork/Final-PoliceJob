LogsBlue = 3447003
LogsRed = 15158332
LogsYellow = 15844367
LogsOrange = 15105570
LogsGrey = 9807270
LogsPurple = 10181046
LogsGreen = 3066993
LogsLightBlue = 1752220

RegisterNetEvent('Ise_Logs')
AddEventHandler('Ise_Logs', function(webhook, Color, Title, Description)
	TriggerServerEvent('Ise_Logs', webhook, Color, Title, Description)
end)