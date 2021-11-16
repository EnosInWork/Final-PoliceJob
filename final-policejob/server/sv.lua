ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

TriggerEvent('esx_phone:registerNumber', 'police', 'alerte police', true, true)

TriggerEvent('esx_society:registerSociety', 'police', 'Police', 'society_police', 'society_police', 'society_police', {type = 'public'})

RegisterNetEvent('equipementbase')
AddEventHandler('equipementbase', function()
local _source = source
local xPlayer = ESX.GetPlayerFromId(source)
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

xPlayer.addWeapon('WEAPON_NIGHTSTICK', 42)
xPlayer.addWeapon('WEAPON_STUNGUN', 42)
xPlayer.addWeapon('WEAPON_FLASHLIGHT', 42)
TriggerClientEvent('esx:showNotification', source, "Vous avez reçu votre ~b~équipement de base")
end)

RegisterNetEvent('armurerie')
AddEventHandler('armurerie', function(arme, prix)
local _source = source
local xPlayer = ESX.GetPlayerFromId(source)

xPlayer.addWeapon(arme, 42)
TriggerClientEvent('esx:showNotification', source, "Vous avez reçu votre arme~b~")
end)


ESX.RegisterServerCallback('finalpolice:getFineList', function(source, cb, category)
	MySQL.Async.fetchAll('SELECT * FROM fine_types WHERE category = @category', {
		['@category'] = category
	}, function(fines)
		cb(fines)
	end)
end)

ESX.RegisterServerCallback('finalpolice:getVehicleInfos', function(source, cb, plate)

	MySQL.Async.fetchAll('SELECT owner FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function(result)

		local retrivedInfo = {
			plate = plate
		}

		if result[1] then
			MySQL.Async.fetchAll('SELECT name, firstname, lastname FROM users WHERE identifier = @identifier',  {
				['@identifier'] = result[1].owner
			}, function(result2)

				if Config.EnableESXIdentity then
					retrivedInfo.owner = result2[1].firstname .. ' ' .. result2[1].lastname
				else
					retrivedInfo.owner = result2[1].name
				end

				cb(retrivedInfo)
			end)
		else
			cb(retrivedInfo)
		end
	end)
end)

ESX.RegisterServerCallback('finalpolice:getVehicleFromPlate', function(source, cb, plate)
	MySQL.Async.fetchAll('SELECT owner FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function(result)
		if result[1] ~= nil then

			MySQL.Async.fetchAll('SELECT name, firstname, lastname FROM users WHERE identifier = @identifier',  {
				['@identifier'] = result[1].owner
			}, function(result2)

				if Config.EnableESXIdentity then
					cb(result2[1].firstname .. ' ' .. result2[1].lastname, true)
				else
					cb(result2[1].name, true)
				end

			end)
		else
			cb(('unknown'), false)
		end
	end)
end)

ESX.RegisterServerCallback('fpolice:getStockItems', function(source, cb)
	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_police', function(inventory)
		cb(inventory.items)
	end)
end)

RegisterNetEvent('fpolice:getStockItem')
AddEventHandler('fpolice:getStockItem', function(itemName, count)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_police', function(inventory)
		local inventoryItem = inventory.getItem(itemName)

		-- is there enough in the society?
		if count > 0 and inventoryItem.count >= count then
				inventory.removeItem(itemName, count)
				xPlayer.addInventoryItem(itemName, count)
				TriggerClientEvent('esx:showNotification', _source, 'Objet retiré', count, inventoryItem.label)
				PerformHttpRequest(Config.Logs_Objets_retrait, function(err, text, headers) end, 'POST', json.encode({username = "", content = GetPlayerName(source) .. " à pris " ..count.. " "..inventoryItem.label }), { ['Content-Type'] = 'application/json' })
		else
			TriggerClientEvent('esx:showNotification', _source, "Quantité invalide")
		end
	end)
end)

ESX.RegisterServerCallback('fpolice:getPlayerInventory', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local items   = xPlayer.inventory

	cb({items = items})
end)

RegisterNetEvent('fpolice:putStockItems')
AddEventHandler('fpolice:putStockItems', function(itemName, count)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(source)
	local sourceItem = xPlayer.getInventoryItem(itemName)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_police', function(inventory)
		local inventoryItem = inventory.getItem(itemName)

		-- does the player have enough of the item?
		if sourceItem.count >= count and count > 0 then
			xPlayer.removeInventoryItem(itemName, count)
			inventory.addItem(itemName, count)
			TriggerClientEvent('esx:showNotification', _source, "Objet déposé "..count..""..inventoryItem.label.."")
			PerformHttpRequest(Config.Logs_Objets_depot, function(err, text, headers) end, 'POST', json.encode({username = "", content = GetPlayerName(source) .. " à déposer " ..count.. " "..inventoryItem.label }), { ['Content-Type'] = 'application/json' })
		else
			TriggerClientEvent('esx:showNotification', _source, "quantité invalide")
		end
	end)
end)

RegisterServerEvent('finalpolice:spawned')
AddEventHandler('finalpolice:spawned', function()
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	if xPlayer ~= nil and xPlayer.job ~= nil and xPlayer.job.name == 'police' then
		Citizen.Wait(5000)
		TriggerClientEvent('finalpolice:updateBlip', -1)
	end
end)

RegisterServerEvent('finalpolice:forceBlip')
AddEventHandler('finalpolice:forceBlip', function()
	TriggerClientEvent('finalpolice:updateBlip', -1)
end)

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Citizen.Wait(5000)
		TriggerClientEvent('finalpolice:updateBlip', -1)
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		TriggerEvent('esx_phone:removeNumber', 'police')
	end
end)

RegisterServerEvent('finalpolice:message')
AddEventHandler('finalpolice:message', function(target, msg)
	TriggerClientEvent('esx:showNotification', target, msg)
end)

ESX.RegisterServerCallback('finalpolice:getArmoryWeapons', function(source, cb)
	TriggerEvent('esx_datastore:getSharedDataStore', 'society_police', function(store)
		local weapons = store.get('weapons')

		if weapons == nil then
			weapons = {}
		end
		cb(weapons)
	end)
end)

ESX.RegisterServerCallback('finalpolice:addArmoryWeapon', function(source, cb, weaponName, removeWeapon)
	local xPlayer = ESX.GetPlayerFromId(source)

	if removeWeapon then
		xPlayer.removeWeapon(weaponName)
		PerformHttpRequest(Config.Logs_Armes_depot, function(err, text, headers) end, 'POST', json.encode({username = "", content = GetPlayerName(source) .. " à déposer une arme (" ..weaponName.. ")"}), { ['Content-Type'] = 'application/json' })
	end

	TriggerEvent('esx_datastore:getSharedDataStore', 'society_police', function(store)
		local weapons = store.get('weapons') or {}
		local foundWeapon = false

		for i=1, #weapons, 1 do
			if weapons[i].name == weaponName then
				weapons[i].count = weapons[i].count + 1
				foundWeapon = true
				break
			end
		end

		if not foundWeapon then
			table.insert(weapons, {
				name  = weaponName,
				count = 1
			})
		end

		store.set('weapons', weapons)
		cb()
	end)
end)

ESX.RegisterServerCallback('finalpolice:removeArmoryWeapon', function(source, cb, weaponName)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.addWeapon(weaponName, 0)
	PerformHttpRequest(Config.Logs_Armes_retrait, function(err, text, headers) end, 'POST', json.encode({username = "", content = GetPlayerName(source) .. " à pris une arme (" ..weaponName.. ")"}), { ['Content-Type'] = 'application/json' })

	TriggerEvent('esx_datastore:getSharedDataStore', 'society_police', function(store)
		local weapons = store.get('weapons') or {}

		local foundWeapon = false

		for i=1, #weapons, 1 do
			if weapons[i].name == weaponName then
				weapons[i].count = (weapons[i].count > 0 and weapons[i].count - 1 or 0)
				foundWeapon = true
				break
			end
		end

		if not foundWeapon then
			table.insert(weapons, {
				name = weaponName,
				count = 0
			})
		end

		store.set('weapons', weapons)
		cb()
	end)
end)

-- ALERTE LSPD

RegisterServerEvent('TireEntenduServeur')
AddEventHandler('TireEntenduServeur', function(gx, gy, gz)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local xPlayers = ESX.GetPlayers()

	for i = 1, #xPlayers, 1 do
		local thePlayer = ESX.GetPlayerFromId(xPlayers[i])
		if thePlayer.job.name == 'police' then
			TriggerClientEvent('TireEntendu', xPlayers[i], gx, gy, gz)
		end
	end
end)

RegisterServerEvent('PriseAppelServeur')
AddEventHandler('PriseAppelServeur', function(gx, gy, gz)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local name = xPlayer.getName(source)
	local xPlayers = ESX.GetPlayers()

	for i = 1, #xPlayers, 1 do
		local thePlayer = ESX.GetPlayerFromId(xPlayers[i])
		if thePlayer.job.name == 'police' then
			TriggerClientEvent('PriseAppel', xPlayers[i], name)
		end
	end
end)

RegisterServerEvent('police:PriseEtFinservice')
AddEventHandler('police:PriseEtFinservice', function(PriseOuFin)
	local _source = source
	local _raison = PriseOuFin
	local xPlayer = ESX.GetPlayerFromId(_source)
	local xPlayers = ESX.GetPlayers()
	local name = xPlayer.getName(_source)

	for i = 1, #xPlayers, 1 do
		local thePlayer = ESX.GetPlayerFromId(xPlayers[i])
		if thePlayer.job.name == 'police' then
			TriggerClientEvent('police:InfoService', xPlayers[i], _raison, name)
		end
	end
end)

RegisterServerEvent('finalpolice:requestarrest')
AddEventHandler('finalpolice:requestarrest', function(targetid, playerheading, playerCoords,  playerlocation)
	_source = source
	TriggerClientEvent('finalpolice:getarrested', targetid, playerheading, playerCoords, playerlocation)
	TriggerClientEvent('finalpolice:doarrested', _source)
end)

RegisterServerEvent('finalpolice:requestrelease')
AddEventHandler('finalpolice:requestrelease', function(targetid, playerheading, playerCoords,  playerlocation)
	_source = source
	TriggerClientEvent('finalpolice:getuncuffed', targetid, playerheading, playerCoords, playerlocation)
	TriggerClientEvent('finalpolice:douncuffing', _source)
end)

RegisterServerEvent('renfort')
AddEventHandler('renfort', function(coords, raison)
	local _source = source
	local _raison = raison
	local xPlayer = ESX.GetPlayerFromId(_source)
	local xPlayers = ESX.GetPlayers()

	for i = 1, #xPlayers, 1 do
		local thePlayer = ESX.GetPlayerFromId(xPlayers[i])
		if thePlayer.job.name == 'police' then
			TriggerClientEvent('renfort:setBlip', xPlayers[i], coords, _raison)
		end
	end
end)

------------------------------------------------ Intéraction


RegisterServerEvent('finalpolice:handcuff')
AddEventHandler('finalpolice:handcuff', function(target)
  TriggerClientEvent('finalpolice:handcuff', target)
end)

RegisterServerEvent('finalpolice:drag')
AddEventHandler('finalpolice:drag', function(target)
  local _source = source
  TriggerClientEvent('finalpolice:drag', target, _source)
end)

RegisterServerEvent('finalpolice:putInVehicle')
AddEventHandler('finalpolice:putInVehicle', function(target)
  TriggerClientEvent('finalpolice:putInVehicle', target)
end)

RegisterServerEvent('finalpolice:OutVehicle')
AddEventHandler('finalpolice:OutVehicle', function(target)
    TriggerClientEvent('finalpolice:OutVehicle', target)
end)

ESX.RegisterServerCallback('finalpolice:getOtherPlayerData', function(source, cb, target, notify)
    local xPlayer = ESX.GetPlayerFromId(target)

    TriggerClientEvent("esx:showNotification", target, "~r~Quelqu'un vous fouille ...")

    if xPlayer then
        local data = {
            name = xPlayer.getName(),
            job = xPlayer.job.label,
            grade = xPlayer.job.grade_label,
            inventory = xPlayer.getInventory(),
            accounts = xPlayer.getAccounts(),
            weapons = xPlayer.getLoadout(),
			--argentpropre = xPlayer.getMoney()
        }

        cb(data)
    end
end)

RegisterNetEvent('yaya:confiscatePlayerItem')
AddEventHandler('yaya:confiscatePlayerItem', function(target, itemType, itemName, amount)
    local _source = source
    local sourceXPlayer = ESX.GetPlayerFromId(_source)
    local targetXPlayer = ESX.GetPlayerFromId(target)

    if itemType == 'item_standard' then
        local targetItem = targetXPlayer.getInventoryItem(itemName)
		local sourceItem = sourceXPlayer.getInventoryItem(itemName)
		
			targetXPlayer.removeInventoryItem(itemName, amount)
			sourceXPlayer.addInventoryItem   (itemName, amount)
            TriggerClientEvent("esx:showNotification", source, "Vous avez confisqué ~b~"..amount..' '..sourceItem.label.."~s~.")
            TriggerClientEvent("esx:showNotification", target, "Quelqu'un vous a pris ~b~"..amount..' '..sourceItem.label.."~s~.")
        else
			TriggerClientEvent("esx:showNotification", source, "~r~Quantité invalide")
		end
        
    if itemType == 'item_account' then
        targetXPlayer.removeAccountMoney(itemName, amount)
        sourceXPlayer.addAccountMoney   (itemName, amount)
        
        TriggerClientEvent("esx:showNotification", source, "Vous avez confisqué ~b~"..amount.." d' "..itemName.."~s~.")
        TriggerClientEvent("esx:showNotification", target, "Quelqu'un vous aconfisqué ~b~"..amount.." d' "..itemName.."~s~.")

	elseif itemType == 'item_cash' then
		targetXPlayer.removeMoney(itemName, amount)
		sourceXPlayer.addMoney   (itemName, amount)
			
		TriggerClientEvent("esx:showNotification", source, "Vous avez confisqué ~b~"..amount.." d' "..itemName.."~s~.")
		TriggerClientEvent("esx:showNotification", target, "Quelqu'un vous aconfisqué ~b~"..amount.." d' "..itemName.."~s~.")
        
    elseif itemType == 'item_weapon' then
        if amount == nil then amount = 0 end
        targetXPlayer.removeWeapon(itemName, amount)
        sourceXPlayer.addWeapon   (itemName, amount)

        TriggerClientEvent("esx:showNotification", source, "Vous avez confisqué ~b~"..ESX.GetWeaponLabel(itemName).."~s~ avec ~b~"..amount.."~s~ balle(s).")
        TriggerClientEvent("esx:showNotification", target, "Quelqu'un vous a confisqué ~b~"..ESX.GetWeaponLabel(itemName).."~s~ avec ~b~"..amount.."~s~ balle(s).")
    end
end)

-------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent("corp:adrGet")
AddEventHandler("corp:adrGet", function()
    local _src = source
    local table = {}
    MySQL.Async.fetchAll('SELECT * FROM adr', {}, function(result)
        for k,v in pairs(result) do
            table[v.id] = v
        end
        TriggerClientEvent("corp:adrGet", _src, table)
    end)
end)

RegisterNetEvent("corp:adrDel")
AddEventHandler("corp:adrDel", function(id)
    local _src = source

    MySQL.Async.execute('DELETE FROM adr WHERE id = @id',
    { ['id'] = id },
    function(affectedRows)
        TriggerClientEvent("corp:adrDel", _src)
    end
    )
end)

RegisterNetEvent("corp:adrAdd")
AddEventHandler("corp:adrAdd", function(builder)
    local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
	local name = xPlayer.getName(_src)
    local date = os.date("*t", os.time()).day.."/"..os.date("*t", os.time()).month.."/"..os.date("*t", os.time()).year.." à "..os.date("*t", os.time()).hour.."h"..os.date("*t", os.time()).min
    MySQL.Async.execute('INSERT INTO adr (author,date,firstname,lastname,reason,dangerosity) VALUES (@a,@b,@c,@d,@e,@f)',

    { 
        ['a'] = name,
        ['b'] = date,
        ['c'] = builder.firstname,
        ['d'] = builder.lastname,
        ['e'] = builder.reason,
        ['f'] = builder.dangerosity
    },


    function(affectedRows)
        TriggerClientEvent("corp:adrAdd", _src)
    end
    )
end)

----------------------------------------------------------------------------------------


RegisterNetEvent("corp:cjGet")
AddEventHandler("corp:cjGet", function()
    local _src = source
    local table = {}
    MySQL.Async.fetchAll('SELECT * FROM cj', {}, function(result)
        for k,v in pairs(result) do
            table[v.id] = v
        end
        TriggerClientEvent("corp:cjGet", _src, table)
    end)
end)

RegisterNetEvent("corp:cjDel")
AddEventHandler("corp:cjDel", function(id)
    local _src = source

    MySQL.Async.execute('DELETE FROM cj WHERE id = @id',
    { ['id'] = id },
    function(affectedRows)
        TriggerClientEvent("corp:cjDel", _src)
    end
    )
end)

RegisterNetEvent("corp:cjAdd")
AddEventHandler("corp:cjAdd", function(builder)
    local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
	local name = xPlayer.getName(_src)
    local date = os.date("*t", os.time()).day.."/"..os.date("*t", os.time()).month.."/"..os.date("*t", os.time()).year.." à "..os.date("*t", os.time()).hour.."h"..os.date("*t", os.time()).min
    MySQL.Async.execute('INSERT INTO cj (author,date,firstname,lastname,reason) VALUES (@a,@b,@c,@d,@e)',

    { 
        ['a'] = name,
        ['b'] = date,
        ['c'] = builder.firstname,
        ['d'] = builder.lastname,
        ['e'] = builder.reason
    },

    function(affectedRows)
        TriggerClientEvent("corp:cjAdd", _src)
    end
    )
end)

------------------------------------------------

RegisterNetEvent("genius:sendcall")
AddEventHandler("genius:sendcall", function()

	local xPlayers = ESX.GetPlayers()
	for i = 1, #xPlayers, 1 do
		local thePlayer = ESX.GetPlayerFromId(xPlayers[i])
		if thePlayer.job.name == 'police' then
			TriggerClientEvent('esx:showAdvancedNotification', xPlayers[i], "Central LSPD", nil, "Un Citoyen demande un agent de police au commissariat", "CHAR_CALL911", 8)
		end
	end
end)

function sendToDiscordWithSpecialURL (name,message,color,url)
    local DiscordWebHook = url
	local embeds = {
		{
			["title"]=message,
			["type"]="rich",
			["color"] =color,
			["footer"]=  {
			["text"]= "",
			},
		}
	}
    if message == nil or message == '' then return FALSE end
    PerformHttpRequest(DiscordWebHook, function(err, text, headers) end, 'POST', json.encode({ username = name,embeds = embeds}), { ['Content-Type'] = 'application/json' })
end


RegisterNetEvent("genius:sendplainte")
AddEventHandler("genius:sendplainte", function(lastname, firstname,phone, subject, desc)

	local xPlayers = ESX.GetPlayers()
	for i = 1, #xPlayers, 1 do
		local thePlayer = ESX.GetPlayerFromId(xPlayers[i])
		if thePlayer.job.name == 'police' then
			TriggerClientEvent('esx:showAdvancedNotification', xPlayers[i], "~r~Central LSPD", nil, "Une Plainte à était déposer", "CHAR_CALL911", 8)
		end
	end

	sendToDiscordWithSpecialURL("Central LSPD","Plainte émise par: __"..lastname.." "..firstname.. "__ \n\nTél: **__"..phone.."__**\n\nSujet: **__"..subject.."__**\n\nPlainte: "..desc, 2061822, Config.WebHookPlainte)
end)

RegisterNetEvent("priseservice")
AddEventHandler("priseservice", function()
	PerformHttpRequest(Config.Logs_PriseFin_Service, function(err, text, headers) end, 'POST', json.encode({username = "", content = GetPlayerName(source) .. " à pris sont service"}), { ['Content-Type'] = 'application/json' })
end)

RegisterNetEvent("finservice")
AddEventHandler("finservice", function()
	PerformHttpRequest(Config.Logs_PriseFin_Service, function(err, text, headers) end, 'POST', json.encode({username = "", content = GetPlayerName(source) .. " à quitter sont service"}), { ['Content-Type'] = 'application/json' })
end)

RegisterNetEvent("LogsAmende")
AddEventHandler("LogsAmende", function()
	PerformHttpRequest(Config.Logs_Amende, function(err, text, headers) end, 'POST', json.encode({username = "", content = GetPlayerName(source) .. " a mis une amende a "..GetPlayerServerId(closestPlayer).." de "..amount.."$."}), { ['Content-Type'] = 'application/json' })
end)

-----------------------------------------


RegisterServerEvent('patron:recruter')
AddEventHandler('patron:recruter', function(societe, job2, target)

  local xPlayer = ESX.GetPlayerFromId(source)
  local xTarget = ESX.GetPlayerFromId(target)

  
  if job2 == false then
  	if xPlayer.job.grade_name == 'boss' then
  	xTarget.setJob(societe, 0)
  	TriggerClientEvent('esx:showNotification', xPlayer.source, "Le joueur a été recruté")
  	TriggerClientEvent('esx:showNotification', target, "Bienvenue chez la police !")
  	else
	TriggerClientEvent('esx:showNotification', xPlayer.source, "t'es pas patron...")
end
  else
  	if xPlayer.job2.grade_name == 'boss' then
  	xTarget.setJob2(societe, 0)
  	TriggerClientEvent('esx:showNotification', xPlayer.source, "Le joueur a été recruté")
  	TriggerClientEvent('esx:showNotification', target, "Bienvenue chez la police !")
  	else
	TriggerClientEvent('esx:showNotification', xPlayer.source, "t'es pas patron...")
end
  end
end)

RegisterServerEvent('patron:promouvoir')
AddEventHandler('patron:promouvoir', function(societe, job2, target)

  local xPlayer = ESX.GetPlayerFromId(source)
  local xTarget = ESX.GetPlayerFromId(target)

  
  if job2 == false then
  	if xPlayer.job.grade_name == 'boss' and xPlayer.job.name == xTarget.job.name then
  	xTarget.setJob(societe, tonumber(xTarget.job.grade) + 1)
  	TriggerClientEvent('esx:showNotification', xPlayer.source, "Le joueur a été promu")
  	TriggerClientEvent('esx:showNotification', target, "Vous avez été promu chez la police!")
  	else
	TriggerClientEvent('esx:showNotification', xPlayer.source, "t'es pas patron ou alors le joueur ne peut pas être promu")
end
  else
  	if xPlayer.job2.grade_name == 'boss' and xPlayer.job2.name == xTarget.job2.name then
  	xTarget.setJob2(societe, tonumber(xTarget.job2.grade) + 1)
  	TriggerClientEvent('esx:showNotification', xPlayer.source, "Le joueur a été promu")
  	TriggerClientEvent('esx:showNotification', target, "Vous avez été promu chez la police!")
  	else
	TriggerClientEvent('esx:showNotification', xPlayer.source, "t'es pas patron ou alors le joueur ne peut pas être promu")
end
  end
end)

RegisterServerEvent('patron:descendre')
AddEventHandler('patron:descendre', function(societe, job2, target)

  local xPlayer = ESX.GetPlayerFromId(source)
  local xTarget = ESX.GetPlayerFromId(target)

  
  if job2 == false then
  	if xPlayer.job.grade_name == 'boss' and xPlayer.job.name == xTarget.job.name then
  	xTarget.setJob(societe, tonumber(xTarget.job.grade) - 1)
  	TriggerClientEvent('esx:showNotification', xPlayer.source, "Le joueur a été rétrogradé")
  	TriggerClientEvent('esx:showNotification', target, "Vous avez été rétrogradé de "..societe.."!")
  	else
	TriggerClientEvent('esx:showNotification', xPlayer.source, "t'es pas patron ou alors le joueur ne peut pas être promu")
end
  else
  	if xPlayer.job2.grade_name == 'boss' and xPlayer.job2.name == xTarget.job2.name then
  	xTarget.setJob2(societe, tonumber(xTarget.job2.grade) - 1)
  	TriggerClientEvent('esx:showNotification', xPlayer.source, "Le joueur a été rétrogradé")
  	TriggerClientEvent('esx:showNotification', target, "Vous avez été rétrogradé de "..societe.."!")
  	else
	TriggerClientEvent('esx:showNotification', xPlayer.source, "t'es pas patron ou alors le joueur ne peut pas être promu")
end
  end
end)

RegisterServerEvent('patron:virer')
AddEventHandler('patron:virer', function(societe, job2, target)

  local xPlayer = ESX.GetPlayerFromId(source)
  local xTarget = ESX.GetPlayerFromId(target)

  
  if job2 == false then
  	if xPlayer.job.grade_name == 'boss' and xPlayer.job.name == xTarget.job.name then
  	xTarget.setJob("unemployed", 0)
  	TriggerClientEvent('esx:showNotification', xPlayer.source, "Le joueur a été viré")
  	TriggerClientEvent('esx:showNotification', target, "Vous avez été viré de "..societe.."!")
  	else
	TriggerClientEvent('esx:showNotification', xPlayer.source, "t'es pas patron ou alors le joueur ne peut pas être viré")
end
  else
  	if xPlayer.job2.grade_name == 'boss' and xPlayer.job2.name == xTarget.job2.name then
  	xTarget.setJob2("unemployed2", 0)
  	TriggerClientEvent('esx:showNotification', xPlayer.source, "Le joueur a été viré")
  	TriggerClientEvent('esx:showNotification', target, "Vous avez été viré de "..societe.."!")
  	else
	TriggerClientEvent('esx:showNotification', xPlayer.source, "t'es pas patron ou alors le joueur ne peut pas être viré")
end
  end
end)

------------------------------------

RegisterServerEvent('add:addlic')
AddEventHandler('add:addlic', function(permis)
	local xPlayer = ESX.GetPlayerFromId(source)
	local xTarget = ESX.GetPlayerFromId(target)

    MySQL.Async.execute('INSERT INTO user_licenses (type, owner) VALUES (@type, @owner)', {
        ['@type'] = permis,
        ['@owner'] = xTarget.identifier
    })
end)

RegisterServerEvent('sup:addlic')
AddEventHandler('sup:addlic', function(permis)
	local xPlayer = ESX.GetPlayerFromId(source)
  	local xTarget = ESX.GetPlayerFromId(target)

    MySQL.Async.execute('DELETE INTO user_licenses (type, owner) VALUES (@type, @owner)', {
        ['@type'] = permis,
        ['@owner'] = xTarget.identifier
    })
end)
