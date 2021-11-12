-----------------------------------------
---------------- Logs -------------------
-----------------------------------------

function prisedeservice()
    TriggerServerEvent("priseservice")
end
  
function findeservice()
    TriggerServerEvent("finservice")
end

function amendelol()
    TriggerServerEvent("LogsAmende")
end

-----------------------------------------
---------------- Plainte ----------------
-----------------------------------------

function reset()
    FirstName = nil
    LastName = nil
    Subject = nil
    Desc = nil
    cansend = false
    tel = nil
end

-----------------------------------------

function Notification(title, subject, msg, icon, iconType)
	AddTextEntry('showAdNotification', msg)
	SetNotificationTextEntry('showAdNotification')
	SetNotificationMessage(icon, icon, false, iconType, title, subject)
	DrawNotification(false, false)
end

-----------------------------------------

function SetVehicleMaxMods(vehicle)
    local props = {
      modEngine       = 2,
      modBrakes       = 2,
      modTransmission = 2,
      modSuspension   = 3,
      modTurbo        = true,
    }
    ESX.Game.SetVehicleProperties(vehicle, props)
end

-----------------------------------------

function ApplySkin(infos)
	TriggerEvent('skinchanger:getSkin', function(skin)
		local uniformObject

		if skin.sex == 0 then
			uniformObject = infos.variations.male
		else
			uniformObject = infos.variations..female
		end

		if uniformObject then
			TriggerEvent('skinchanger:loadClothes', skin, uniformObject)
		end

		infos.onEquip()
	end)
end

-----------------------------------------

function OpenGetWeaponMenu()

	ESX.TriggerServerCallback('finalpolice:getArmoryWeapons', function(weapons)
		local elements = {}

		for i=1, #weapons, 1 do
			if weapons[i].count > 0 then
				table.insert(elements, {
					label = 'x' .. weapons[i].count .. ' ' .. ESX.GetWeaponLabel(weapons[i].name),
					value = weapons[i].name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_get_weapon',
		{
			title    = ('Armurerie'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)

			menu.close()

			ESX.TriggerServerCallback('finalpolice:removeArmoryWeapon', function()
			OpenGetWeaponMenu()
			end, data.current.value)

		end, function(data, menu)
			menu.close()
		end)
	end)

end

function OpenPutWeaponMenu()
	local elements   = {}
	local playerPed  = PlayerPedId()
	local weaponList = ESX.GetWeaponList()

	for i=1, #weaponList, 1 do
		local weaponHash = GetHashKey(weaponList[i].name)

		if HasPedGotWeapon(playerPed, weaponHash, false) and weaponList[i].name ~= 'WEAPON_UNARMED' then
			table.insert(elements, {
				label = weaponList[i].label,
				value = weaponList[i].name
			})
		end
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_put_weapon',
	{
		title    = ('Armurerie'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)

		menu.close()

		ESX.TriggerServerCallback('finalpolice:addArmoryWeapon', function()
			OpenPutWeaponMenu()
		end, data.current.value, true)

	end, function(data, menu)
		menu.close()
	end)
end

---------------------------------------------------------------------------------

function OpenVehicleInfosMenu(vehicleData)
	ESX.TriggerServerCallback('finalpolice:getVehicleInfos', function(retrivedInfo)
		local elements = {{label = ("Plaque" ..retrivedInfo.plate)}}

		if retrivedInfo.owner == nil then
			table.insert(elements, {label = ('Propriétaire inconnu')})
		else
			table.insert(elements, {label = ("Propriétaire" ..retrivedInfo.owner)})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_infos', {
			css      = 'police',
			title    = ('Info véhicule'),
			align    = 'top-left',
			elements = elements
		}, nil, function(data, menu)
			menu.close()
		end)
	end, vehicleData.plate)
end

function LookupVehicle()
	ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'lookup_vehicle', {
		title = ('Entrer le nom dans la base de données'),
	}, function(data, menu)
		local length = string.len(data.value)
		if not data.value or length < 2 or length > 8 then
			ESX.ShowNotification('Une erreur c\'est produite')
		else
			ESX.TriggerServerCallback('finalpolice:getVehicleInfos', function(retrivedInfo)
				local elements = {{label = ("Plaque" ..retrivedInfo.plate)}}
				menu.close()

				if not retrivedInfo.owner then
					table.insert(elements, {label = ('Propriétaire inconnu')})
				else
					table.insert(elements, {label = ("Propriétaire" ..retrivedInfo.owner)})
				end

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_infos', {
					title    = ('Info véhicule'),
					align    = 'top-left',
					elements = elements
				}, nil, function(data2, menu2)
					menu2.close()
				end)
			end, data.value)

		end
	end, function(data, menu)
		menu.close()
	end)
end