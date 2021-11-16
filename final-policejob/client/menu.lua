ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(10)
    end
    while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
    end
    if ESX.IsPlayerLoaded() then

		ESX.PlayerData = ESX.GetPlayerData()

    end
end)

local function LoadAnimDict(dictname)
	if not HasAnimDictLoaded(dictname) then
		RequestAnimDict(dictname) 
		while not HasAnimDictLoaded(dictname) do 
			Citizen.Wait(1)
		end
	end
end


local ped = PlayerPedId()
local vehicle = GetVehiclePedIsIn( ped, false )
local blip = nil
local policeDog = false
local PlayerData = {}
local currentTask = {}
local closestDistance, closestEntity = -1, nil

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
     PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)  
	PlayerData.job = job  
	
	Citizen.Wait(5000) 
end)

loadDict = function(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) RequestAnimDict(dict) end
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
end)


RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

local Items = {}      -- Item que le joueur possède (se remplit lors d'une fouille)
local Armes = {}    -- Armes que le joueur possède (se remplit lors d'une fouille)
local ArgentSale = {}  -- Argent sale que le joueur possède (se remplit lors d'une fouille)
local IsHandcuffed, DragStatus = false, {}
DragStatus.IsDragged          = false

local function MarquerJoueur()
	local ped = GetPlayerPed(ESX.Game.GetClosestPlayer())
	local pos = GetEntityCoords(ped)
	local target, distance = ESX.Game.GetClosestPlayer()
	if distance <= 4.0 then
	DrawMarker(2, pos.x, pos.y, pos.z+1.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 255, 0, 170, 0, 1, 2, 1, nil, nil, 0)
end
end

-- Reprise du menu fouille du pz_core (modifié)
local function getPlayerInv(player)
Items = {}
Armes = {}
ArgentSale = {}

ESX.TriggerServerCallback('finalpolice:getOtherPlayerData', function(data)
	for i=1, #data.accounts, 1 do
		if data.accounts[i].name == 'black_money' and data.accounts[i].money > 0 then
			table.insert(ArgentSale, {
				label    = ESX.Math.Round(data.accounts[i].money),
				value    = 'black_money',
				itemType = 'item_account',
				amount   = data.accounts[i].money
			})

			break
		end
	end
	for i=1, #data.weapons, 1 do
		table.insert(Armes, {
			label    = ESX.GetWeaponLabel(data.weapons[i].name),
			value    = data.weapons[i].name,
			right    = data.weapons[i].ammo,
			itemType = 'item_weapon',
			amount   = data.weapons[i].ammo
		})
	end
	for i=1, #data.inventory, 1 do
		if data.inventory[i].count > 0 then
			table.insert(Items, {
				label    = data.inventory[i].label,
				right    = data.inventory[i].count,
				value    = data.inventory[i].name,
				itemType = 'item_standard',
				amount   = data.inventory[i].count
			})
		end
	end
end, GetPlayerServerId(player))
end

function getInformations(player)
	ESX.TriggerServerCallback('finalpolice:getOtherPlayerData', function(data)
		identityStats = data
	end, GetPlayerServerId(player))
end

local function KeyboardInput(TextEntry, ExampleText, MaxStringLenght)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    blockinput = true
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do 
        Wait(0)
    end 
        
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(500)
        blockinput = false
        return result
    else
        Wait(500)
        blockinput = false
        return nil
    end
end

local current = "police"
local dangerosityTable = {[1] = "Coopératif",[2] = "Dangereux",[3] = "Dangereux et armé",[4] = "Terroriste"}
lspdADRDangerosities = {"Coopératif","Dangereux","Dangereux et armé","Terroriste"}
lspdADRBuilder = {dangerosity = 1}
lspdCJBuilder = {dangerosity = 1}
lspdADRData = nil
lspdCJData = nil
lspdADRindex = 0
lspdCJindex = 0
colorVar = "~o~"


function getDangerosityNameByInt(dangerosity)
    if dangerosityTable[dangerosity] ~= nil then
        return dangerosityTable[dangerosity]
    else
        return dangerosity
    end
end

RegisterNetEvent("corp:adrGet")
AddEventHandler("corp:adrGet", function(result)
    local found = 0
    for k,v in pairs(result) do
        found = found + 1
    end
    if found > 0 then lspdADRData = result end
end)

RegisterNetEvent("corp:cjGet")
AddEventHandler("corp:cjGet", function(result)
    local found = 0
    for k,v in pairs(result) do
        found = found + 1
    end
    if found > 0 then lspdCJData = result end
end)

-----------------------------------------------------------------------------------------------
function Menuf6Police()
	local mf6p = RageUI.CreateMenu("L.S.P.D", "Los Santos Police Departement")
	local inter = RageUI.CreateSubMenu(mf6p, "L.S.P.D", "Los Santos Police Departement")
	local info = RageUI.CreateSubMenu(mf6p, "L.S.P.D", "Los Santos Police Departement")
	local props = RageUI.CreateSubMenu(mf6p, "L.S.P.D", "Los Santos Police Departement")
	local renfort = RageUI.CreateSubMenu(mf6p, "L.S.P.D", "Los Santos Police Departement")
	local voiture = RageUI.CreateSubMenu(mf6p, "L.S.P.D", "Los Santos Police Departement")
	local chien = RageUI.CreateSubMenu(mf6p, "L.S.P.D", "Los Santos Police Departement")
	local cam = RageUI.CreateSubMenu(mf6p, "L.S.P.D", "Los Santos Police Departement")
	local megaphone = RageUI.CreateSubMenu(mf6p, "L.S.P.D", "Los Santos Police Departement")
	local fouiller = RageUI.CreateSubMenu(inter, "L.S.P.D", "Los Santos Police Departement")
	local gererlicenses = RageUI.CreateSubMenu(inter, "L.S.P.D", "Los Santos Police Departement")
	local lspd_main = RageUI.CreateSubMenu(mf6p, "L.S.P.D", "Los Santos Police Departement")
	local lspd_adrcheck = RageUI.CreateSubMenu(lspd_main, "L.S.P.D", "Los Santos Police Departement")
	local lspd_adr = RageUI.CreateSubMenu(lspd_main, "L.S.P.D", "Los Santos Police Departement")
	local lspd_adrlaunch = RageUI.CreateSubMenu(lspd_main, "L.S.P.D", "Los Santos Police Departement")

	RageUI.Visible(mf6p, not RageUI.Visible(mf6p))
	while mf6p do
		Citizen.Wait(0)
			RageUI.IsVisible(mf6p, true, true, true, function()

            RageUI.Checkbox("Prendre/Quitter son service",nil, service,{},function(Hovered,Ative,Selected,Checked)
                if Selected then

                    service = Checked


                    if Checked then
						prisedeservice()
						onservice = true
						RageUI.Popup({
							message = "Vous avez pris votre service !"})
                        
                    else
						findeservice()
                        onservice = false
						RageUI.Popup({
							message = "Vous avez quitter votre service !"})

                    end
                end
            end)

			if onservice then

				RageUI.Separator("↓ ~o~ Intéractions~s~ ↓")

				RageUI.ButtonWithStyle("Intéractions sur civil", nil, {RightLabel = "→"},true, function()
				end, inter)

				RageUI.ButtonWithStyle("Intéractions sur véhicules", nil, {RightLabel = "→"},true, function()
				end, voiture)

				RageUI.ButtonWithStyle("Contacts Radio", nil, {RightLabel = "→"},true, function()
				end, info)

				if ESX.PlayerData.job.grade >= Config.Grade_Pour_AvisRecherche then
				RageUI.ButtonWithStyle("Avis de recherche", nil, {RightLabel = "→"},true, function()
				end, lspd_main)
			else
				RageUI.ButtonWithStyle('Avis de recherche', "Vous n'avez pas le grade nécessaire", {RightBadge = RageUI.BadgeStyle.Lock}, false, function(Hovered, Active, Selected)
						if (Selected) then
							end 
						end)
					end

				if IsPedInAnyVehicle(PlayerPedId(), false) then
				RageUI.ButtonWithStyle("Mégaphone", nil, {RightLabel = "→"},true, function()
				end, megaphone)
				else
				RageUI.ButtonWithStyle('Mégaphone', "Vous devez être dans un véhicule", {RightBadge = RageUI.BadgeStyle.Lock }, false, function(Hovered, Active, Selected)
						if (Selected) then
							end 
						end)
					end

					if ESX.PlayerData.job.grade >= Config.Grade_Pour_Radar then
				RageUI.ButtonWithStyle("Poser/Prendre Radar",nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
					if Selected then
						RageUI.CloseAll()       
						TriggerEvent('police:POLICE_radar')
					end
				end)
			else
				RageUI.ButtonWithStyle('Poser/Prendre Radar', "Vous n'avez pas le grade nécessaire", {RightBadge = RageUI.BadgeStyle.Lock }, false, function(Hovered, Active, Selected)
					if (Selected) then
						end 
				end)
				end

				if ESX.PlayerData.job.grade >= Config.Grade_Pour_Objets then
				RageUI.ButtonWithStyle("Menu Objets", nil, {RightLabel = "→"},true, function()
				end, props)
			else
				RageUI.ButtonWithStyle('Menu Objets', "Vous n'avez pas le grade nécessaire", {RightBadge = RageUI.BadgeStyle.Lock }, false, function(Hovered, Active, Selected)
					if (Selected) then
						end 
					end)
				end

				if ESX.PlayerData.job.grade >= Config.Grade_Pour_Chien then
				RageUI.ButtonWithStyle("Menu Chien", nil, {RightLabel = "→"},true, function()
				end, chien)
			else
				RageUI.ButtonWithStyle('Menu Chien', "Vous n'avez pas le grade nécessaire", {RightBadge = RageUI.BadgeStyle.Lock }, false, function(Hovered, Active, Selected)
					if (Selected) then
						end 
					end)
				end

				if ESX.PlayerData.job.grade >= Config.Grade_Pour_Camera then
				RageUI.ButtonWithStyle("Menu Caméra", nil, {RightLabel = "→"},true, function()
				end, cam)
				else
					RageUI.ButtonWithStyle('Menu Caméra', "Vous n'avez pas le grade nécessaire", {RightBadge = RageUI.BadgeStyle.Lock }, false, function(Hovered, Active, Selected)
						if (Selected) then
							end 
						end)
					end
				end

    end, function()
	end)

	RageUI.IsVisible(inter, true, true, true, function()

		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		RageUI.ButtonWithStyle("Donner une Amende",nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
			if Selected then
				local target, distance = ESX.Game.GetClosestPlayer()
				playerheading = GetEntityHeading(GetPlayerPed(-1))
				playerlocation = GetEntityForwardVector(PlayerPedId())
				playerCoords = GetEntityCoords(GetPlayerPed(-1))
				local target_id = GetPlayerServerId(target)
				if closestPlayer ~= -1 and closestDistance <= 3.0 then
				RageUI.CloseAll()        
				OpenBillingMenu() 
				else
				ESX.ShowNotification('Peronne autour')
				end
			end
		end)

			RageUI.ButtonWithStyle("Vérification licence(s)", nil, {RightLabel = "→"}, closestPlayer ~= -1 and closestDistance <= 3.0, function()
			end, gererlicenses)
			
			RageUI.ButtonWithStyle('Fouiller la personne', nil, {RightLabel = "→"}, closestPlayer ~= -1 and closestDistance <= 3.0, function(_, a, s)
				if a then
					MarquerJoueur()
					if s then
					
					getPlayerInv(closestPlayer)
					ExecuteCommand("me fouille l'individu")
					
				end
			end
			end, fouiller) 

			RageUI.ButtonWithStyle('Faire un test multidrogue', "Soon in VIP > patreon.com/five_dev", {RightBadge = RageUI.BadgeStyle.Lock}, false, function(Hovered, Active, Selected)
				if (Selected) then
					end 
				end)

				RageUI.ButtonWithStyle('Faire un test d\'alcoolémie', "Soon in VIP > patreon.com/five_dev", {RightBadge = RageUI.BadgeStyle.Lock}, false, function(Hovered, Active, Selected)
					if (Selected) then
						end 
					end)
	
			RageUI.ButtonWithStyle('Montrer son badge', "Soon in VIP > patreon.com/five_dev", {RightBadge = RageUI.BadgeStyle.Lock}, false, function(Hovered, Active, Selected)
				if (Selected) then
					end 
				end)
		
        RageUI.ButtonWithStyle("Menotter/démenotter", nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
            if (Selected) then
				local target, distance = ESX.Game.GetClosestPlayer()
				playerheading = GetEntityHeading(GetPlayerPed(-1))
				playerlocation = GetEntityForwardVector(PlayerPedId())
				playerCoords = GetEntityCoords(GetPlayerPed(-1))
				local target_id = GetPlayerServerId(target)
				if closestPlayer ~= -1 and closestDistance <= 3.0 then
                TriggerServerEvent('finalpolice:handcuff', GetPlayerServerId(closestPlayer))
			else
				ESX.ShowNotification('Peronne autour')
				end
            end
        end)

            RageUI.ButtonWithStyle("Escorter", nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
                if (Selected) then
					local target, distance = ESX.Game.GetClosestPlayer()
					playerheading = GetEntityHeading(GetPlayerPed(-1))
					playerlocation = GetEntityForwardVector(PlayerPedId())
					playerCoords = GetEntityCoords(GetPlayerPed(-1))
					local target_id = GetPlayerServerId(target)
					if closestPlayer ~= -1 and closestDistance <= 3.0 then
                TriggerServerEvent('finalpolice:drag', GetPlayerServerId(closestPlayer))
			else
				ESX.ShowNotification('Peronne autour')
				end
            end
        end)

            RageUI.ButtonWithStyle("Mettre dans un véhicule", nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
                if (Selected) then
					local target, distance = ESX.Game.GetClosestPlayer()
					playerheading = GetEntityHeading(GetPlayerPed(-1))
					playerlocation = GetEntityForwardVector(PlayerPedId())
					playerCoords = GetEntityCoords(GetPlayerPed(-1))
					local target_id = GetPlayerServerId(target)
					if closestPlayer ~= -1 and closestDistance <= 3.0 then
                TriggerServerEvent('finalpolice:putInVehicle', GetPlayerServerId(closestPlayer))
			else
				ESX.ShowNotification('Peronne autour')
				end
                end
            end)

            RageUI.ButtonWithStyle("Sortir du véhicule", nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
                if (Selected) then
					local target, distance = ESX.Game.GetClosestPlayer()
					playerheading = GetEntityHeading(GetPlayerPed(-1))
					playerlocation = GetEntityForwardVector(PlayerPedId())
					playerCoords = GetEntityCoords(GetPlayerPed(-1))
					local target_id = GetPlayerServerId(target)
					if closestPlayer ~= -1 and closestDistance <= 3.0 then
                TriggerServerEvent('finalpolice:OutVehicle', GetPlayerServerId(closestPlayer))
			else
				ESX.ShowNotification('Peronne autour')
				end
            end
        end)

		RageUI.ButtonWithStyle("Droit miranda", nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
			if (Selected) then   
			RageUI.Popup({message = "Monsieur / Madame (Prénom et nom de la personne), je vous arrête pour (motif de l'arrestation)."})
			RageUI.Popup({message = "Vous avez le droit de garder le silence."})
			RageUI.Popup({message = "Si vous renoncez à ce droit, tout ce que vous direz pourra être et sera utilisé contre vous."})
			RageUI.Popup({message = "Vous avez le droit à un avocat, si vous n’en avez pas les moyens, un avocat vous sera fourni."})
			RageUI.Popup({message = "Vous avez le droit à une assistance médicale ainsi qu'à de la nourriture et de l'eau."})
			RageUI.Popup({message = "Avez-vous bien compris vos droits ?"})
		end
		end)

		if ESX.PlayerData.job.grade >= Config.Grade_Pour_Permis then	
		RageUI.ButtonWithStyle("Donner le permis de conduire", nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
			if (Selected) then   
			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
				if closestPlayer ~= -1 and closestDistance <= 3.0 then
					TriggerServerEvent('add:addlic', "drive")
				ESX.ShowNotification('Le joueur a bien reçu sont permis')
			 else
				ESX.ShowNotification('Aucun joueurs à proximité')
			end 
		end
		end)
	else
		RageUI.ButtonWithStyle('Donner le permis de conduire', "Vous n'avez pas le grade nécessaire", {RightBadge = RageUI.BadgeStyle.Lock }, false, function(Hovered, Active, Selected)
			if (Selected) then
				end 
			end)
	end	

	if ESX.PlayerData.job.grade >= Config.Grade_Pour_Permis then	
		RageUI.ButtonWithStyle("Retirer le permis de conduire", nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
			if (Selected) then   
			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
				if closestPlayer ~= -1 and closestDistance <= 3.0 then
					TriggerServerEvent('add:sup:addlic', "drive")
				ESX.ShowNotification('Le joueur a bien perdu sont permis')
			 else
				ESX.ShowNotification('Aucun joueurs à proximité')
			end 
		end
		end)
	else
		RageUI.ButtonWithStyle('Retirer le permis de conduire', "Vous n'avez pas le grade nécessaire", {RightBadge = RageUI.BadgeStyle.Lock }, false, function(Hovered, Active, Selected)
			if (Selected) then
				end 
			end)
	end	

		if ESX.PlayerData.job.grade >= Config.Grade_Pour_PPA then			
		RageUI.ButtonWithStyle("Donner le PPA", nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
				if (Selected) then   
				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer ~= -1 and closestDistance <= 3.0 then
						TriggerServerEvent('add:addlic', "weapon")
					ESX.ShowNotification('Le joueur a bien reçu sont ppa')
				 else
					ESX.ShowNotification('Aucun joueurs à proximité')
				end 
			end
			end)
		else
			RageUI.ButtonWithStyle('Donner le PPA', "Vous n'avez pas le grade nécessaire", {RightBadge = RageUI.BadgeStyle.Lock }, false, function(Hovered, Active, Selected)
				if (Selected) then
					end 
				end)
		end	

		if ESX.PlayerData.job.grade >= Config.Grade_Pour_PPA then			
		RageUI.ButtonWithStyle("Retirer le PPA", nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
			if (Selected) then   
			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
				if closestPlayer ~= -1 and closestDistance <= 3.0 then
					TriggerServerEvent('add:sup:addlic', "weapon")
			 else
				ESX.ShowNotification('Aucun joueurs à proximité')
			end 
		end
		end)
	else
		RageUI.ButtonWithStyle('Retirer le PPA', "Vous n'avez pas le grade nécessaire", {RightBadge = RageUI.BadgeStyle.Lock }, false, function(Hovered, Active, Selected)
			if (Selected) then
				end 
			end)
	end	

    end, function()
	end)

	
	RageUI.IsVisible(gererlicenses, true, true, true, function()

		local data = identityStats
		if identityStats == nil then
			RageUI.Separator("")
			RageUI.Separator("~o~En attente des données...")
			RageUI.Separator("")
		else
			if data.licenses ~= nil then
				RageUI.Separator("↓ ~o~Licence ~s~↓")
				if data.licenses ~= nil then
					for i = 1, #data.licenses, 1 do
						if data.licenses[i].label ~= nil and data.licenses[i].type ~= nil then
							RageUI.ButtonWithStyle(data.licenses[i].label ,nil, {RightLabel = "Revoqué ~s~→"}, true, function(_,_,s)
								if s then
									TriggerServerEvent('esx_license:removeLicense', GetPlayerServerId(player), data.licenses[i].type)


									ESX.SetTimeout(300, function()
										RageUI.CloseAll()
										identityStats = nil
										Wait(500)
										RageUI.Visible(RMenu:Get("Police","main"), true)
									end)
								end
							end)
						end
					end
				else
					RageUI.Separator("")
					RageUI.Separator("~o~La personne n'as pas de licence...")
					RageUI.Separator("")
				end
			end
		end

	end, function()
	end)

	RageUI.IsVisible(fouiller, true, true, true, function()
		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

		RageUI.Separator("↓ ~r~Argent Sale ~s~↓")
		for k,v  in pairs(ArgentSale) do
			RageUI.ButtonWithStyle("Argent sale :", nil, {RightLabel = "~r~"..v.label.."$"}, true, function(_, _, s)
				if s then
					local combien = KeyboardInput("Combien ?", '' , '', 8)
					if tonumber(combien) > v.amount then
						ESX.ShowNotification('~g~Quantité invalide')
					else
						TriggerServerEvent('yaya:confiscatePlayerItem', GetPlayerServerId(closestPlayer), v.itemType, v.value, tonumber(combien))
						TriggerEvent('Ise_Logs', Config.Logs_Fouille, 3447003, "FOUILLE POLICE", "Nom : "..GetPlayerName(PlayerId())..".\nA confisquer de l'argent sale: x"..combien.." "..v.value.." à "..GetPlayerName(closestPlayer))
					end
					RageUI.GoBack()
				end
			end)
		end

		RageUI.Separator("↓ ~g~Objets ~s~↓")
		for k,v  in pairs(Items) do
			RageUI.ButtonWithStyle(v.label, nil, {RightLabel = "~g~x"..v.right}, true, function(_, _, s)
				if s then
					local combien = KeyboardInput("Combien ?", '' , '', 8)
					if tonumber(combien) > v.amount then
						ESX.ShowNotification('~g~Quantité invalide')
					else
						TriggerServerEvent('yaya:confiscatePlayerItem', GetPlayerServerId(closestPlayer), v.itemType, v.value, tonumber(combien))
						TriggerEvent('Ise_Logs', Config.Logs_Fouille, 3447003, "FOUILLE POLICE", "Nom : "..GetPlayerName(PlayerId())..".\nA confisquer : x"..combien.." "..v.value.." à "..GetPlayerName(closestPlayer))
					end
					RageUI.GoBack()
				end
			end)
		end
			RageUI.Separator("↓ ~g~Armes ~s~↓")

			for k,v  in pairs(Armes) do
				RageUI.ButtonWithStyle(v.label, nil, {RightLabel = "avec ~g~"..v.right.. " ~s~balle(s)"}, true, function(_, _, s)
					if s then
						local combien = KeyboardInput("Combien ?", '' , '', 8)
						if tonumber(combien) > v.amount then
							ESX.ShowNotification('~g~Quantité invalide')
						else
							TriggerServerEvent('yaya:confiscatePlayerItem', GetPlayerServerId(closestPlayer), v.itemType, v.value, tonumber(combien))
							TriggerEvent('Ise_Logs', Config.Logs_Fouille, 3447003, "FOUILLE POLICE", "Nom : "..GetPlayerName(PlayerId())..".\nA confisquer une arme : x"..combien.." "..v.value.." à "..GetPlayerName(closestPlayer))
						end
						RageUI.GoBack()
					end
				end)
			end

		end, function() 
		end)

		RageUI.IsVisible(props, true, true, true, function()
			local coords  = GetEntityCoords(PlayerPedId())
	
			RageUI.ButtonWithStyle("Cône",nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
				if Selected then 
					spawnObject('prop_roadcone02a')
				end
				end)
	
			RageUI.ButtonWithStyle("Barrière", nil, { RightLabel = "→" }, true, function(Hovered, Active, Selected)
				if Selected then
					spawnObject('prop_barrier_work05')
				end
			end)
				
	
			RageUI.ButtonWithStyle("Herse", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
				if Selected then
					spawnObject('p_ld_stinger_s')
				end
			end)
		
		end, function()
		end)

		RageUI.IsVisible(info, true, true, true, function()

		RageUI.ButtonWithStyle("Prise de service",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				local info = 'prise'
				TriggerServerEvent('police:PriseEtFinservice', info)
			end
		end)

		RageUI.ButtonWithStyle("Fin de service",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				local info = 'fin'
				TriggerServerEvent('police:PriseEtFinservice', info)
			end
		end)

		RageUI.ButtonWithStyle("Pause de service",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				local info = 'pause'
				TriggerServerEvent('police:PriseEtFinservice', info)
			end
		end)

		RageUI.ButtonWithStyle("Standby",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				local info = 'standby'
				TriggerServerEvent('police:PriseEtFinservice', info)
			end
		end)

		RageUI.ButtonWithStyle("Control en cours",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				local info = 'control'
				TriggerServerEvent('police:PriseEtFinservice', info)
			end
		end)

		RageUI.ButtonWithStyle("Refus d'obtempérer",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				local info = 'refus'
				TriggerServerEvent('police:PriseEtFinservice', info)
			end
		end)

		RageUI.ButtonWithStyle("Crime en cours",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				local info = 'crime'
				TriggerServerEvent('police:PriseEtFinservice', info)
			end
		end)

		RageUI.Separator(' ↓ ~o~Renfort~s~ ↓ ')

		RageUI.ButtonWithStyle("Petite demande",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				local raison = 'petit'
				local elements  = {}
				local playerPed = PlayerPedId()
				local coords  = GetEntityCoords(playerPed)
				local name = GetPlayerName(PlayerId())
			TriggerServerEvent('renfort', coords, raison)
		end
	end)

	RageUI.ButtonWithStyle("Moyenne demande",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
		if Selected then
			local raison = 'importante'
			local elements  = {}
			local playerPed = PlayerPedId()
			local coords  = GetEntityCoords(playerPed)
			local name = GetPlayerName(PlayerId())
		TriggerServerEvent('renfort', coords, raison)
	end
end)

RageUI.ButtonWithStyle("Grosse demande",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
	if Selected then
		local raison = 'omgad'
		local elements  = {}
		local playerPed = PlayerPedId()
		local coords  = GetEntityCoords(playerPed)
		local name = GetPlayerName(PlayerId())
	TriggerServerEvent('renfort', coords, raison)
end
end)

    end, function()
	end)

	RageUI.IsVisible(cam, true, true, true, function()

		RageUI.ButtonWithStyle("Caméra 1 (Ballas)", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 25) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 2 (Families)", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 26) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 3 (Vagos)", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 27) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 4 (Superette Unicorn)", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 1) 
			end
		end)


		RageUI.ButtonWithStyle("Caméra 5 (Superette Ballas)", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 2) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 6 (Superette Ballas)", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 3) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 7 (Superette BurgerShot)", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 4) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 8 (Superette Taxi)", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 5) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 9 (Superette Vinewood)", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 6) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 10 (", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 7) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 11", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 8) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 12", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 9) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 13", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 10) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 14", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 11) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 15", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 12) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 16", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 13) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 17", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 14) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 18", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 15) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 19", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 16) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 20", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 17) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 21", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 18) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 22", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 19) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 23", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 20) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 24", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 21) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 25", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 22) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 26", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 23) 
			end
		end)

	end, function()
	end)


	RageUI.IsVisible(megaphone, true, true, true, function()

		RageUI.ButtonWithStyle("Arrêter vous immédiatement !", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 30.0, "stop_the_f_car", 0.6) 
			end
		end)

		RageUI.ButtonWithStyle("Conducteur, STOP votre véhicule", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 30.0, "stop_vehicle-2", 0.6)
			end
		end)
		
		RageUI.ButtonWithStyle("Stop, les mains en l'air", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 30.0, "dont_make_me", 0.6)
			end
		end)

		RageUI.ButtonWithStyle("Stop, plus un geste ! ou on vous tue", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 30.0, "stop_dont_move", 0.6)
			end
		end)

		RageUI.ButtonWithStyle("Reste ici et ne bouge plus !", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 30.0, "stay_right_there", 0.6)
			end
		end)

		RageUI.ButtonWithStyle("Disperssez vous de suite ! ", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 30.0, "disperse_now", 0.6)
			end
		end)

			end, function()
			end)

			RageUI.IsVisible(voiture, true, true, true, function()
		local coords  = GetEntityCoords(PlayerPedId())
		local vehicle = ESX.Game.GetVehicleInDirection()

		RageUI.ButtonWithStyle("Rechercher une plaque",nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
			if Selected then 
				LookupVehicle()
				RageUI.CloseAll()
			end
			end)

			RageUI.ButtonWithStyle("Mettre en fourrière", nil, { RightLabel = "→" }, true, function(Hovered, Active, Selected)
				if Selected then

					TaskStartScenarioInPlace(PlayerPedId(), 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)

					currentTask.busy = true
					currentTask.task = ESX.SetTimeout(10000, function()
						ClearPedTasks(playerPed)
						ESX.Game.DeleteVehicle(vehicle)
						ESX.ShowNotification("~o~Mise en fourrière effectuée")
						currentTask.busy = false
						Citizen.Wait(100) -- sleep the entire script to let stuff sink back to reality
					end)

					-- keep track of that vehicle!
					Citizen.CreateThread(function()
						while currentTask.busy do
							Citizen.Wait(1000)

							vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, 0, 71)
							if not DoesEntityExist(vehicle) and currentTask.busy then
								ESX.ShowNotification("~r~Le véhicule a bougé!")
								ESX.ClearTimeout(currentTask.task)
								ClearPedTasks(playerPed)
								currentTask.busy = false
								break
							end
						end
					end)
				end
			end)

			RageUI.ButtonWithStyle("Crocheter le véhicule", nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
				if Selected then
					local playerPed = PlayerPedId()
					local vehicle = ESX.Game.GetVehicleInDirection()
					local coords = GetEntityCoords(playerPed)
		
					if IsPedSittingInAnyVehicle(playerPed) then
						ESX.ShowNotification('Sorter du véhicule')
						return
					end
		
					if DoesEntityExist(vehicle) then
						isBusy = true
						TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_WELDING', 0, true)
						Citizen.CreateThread(function()
							Citizen.Wait(10000)
		
							SetVehicleDoorsLocked(vehicle, 1)
							SetVehicleDoorsLockedForAllPlayers(vehicle, false)
							ClearPedTasksImmediately(playerPed)
		
							ESX.ShowNotification('Véhicule dévérouiller')
							isBusy = false
						end)
					else
						ESX.ShowNotification('Pas de véhicule proche')
					end
				end
			end)
	
	end, function()
	end)

	RageUI.IsVisible(chien, true, true, true, function()

			RageUI.ButtonWithStyle("Sortir/Rentrer le chien",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
				if Selected then
					if not DoesEntityExist(policeDog) then
                        RequestModel(351016938)
                        while not HasModelLoaded(351016938) do Wait(0) end
                        policeDog = CreatePed(4, 351016938, GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 1.0, -0.98), 0.0, true, false)
                        SetEntityAsMissionEntity(policeDog, true, true)
                        ESX.ShowNotification('~g~Chien Spawn')
                    else
                        ESX.ShowNotification('~r~Chien Rentrer')
                        DeleteEntity(policeDog)
                    end
				end
			end)

			RageUI.ButtonWithStyle("Assis",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
				if Selected then
					if DoesEntityExist(policeDog) then
                        if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(policeDog), true) <= 5.0 then
                            if IsEntityPlayingAnim(policeDog, "creatures@rottweiler@amb@world_dog_sitting@base", "base", 3) then
                                ClearPedTasks(policeDog)
                            else
                                loadDict('rcmnigel1c')
                                TaskPlayAnim(PlayerPedId(), 'rcmnigel1c', 'hailing_whistle_waive_a', 8.0, -8, -1, 120, 0, false, false, false)
                                Wait(2000)
                                loadDict("creatures@rottweiler@amb@world_dog_sitting@base")
                                TaskPlayAnim(policeDog, "creatures@rottweiler@amb@world_dog_sitting@base", "base", 8.0, -8, -1, 1, 0, false, false, false)
                            end
                        else
                            ESX.ShowNotification('dog_too_far')
                        end
                    else
                        ESX.ShowNotification('no_dog')
                    end
				end
			end)

		RageUI.ButtonWithStyle("Cherche de drogue",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				if DoesEntityExist(policeDog) then
					if not IsPedDeadOrDying(policeDog) then
						if GetDistanceBetweenCoords(GetEntityCoords(policeDog), GetEntityCoords(PlayerPedId()), true) <= 3.0 then
							local player, distance = ESX.Game.GetClosestPlayer()
							if distance ~= -1 then
								if distance <= 3.0 then
									local playerPed = GetPlayerPed(player)
									if not IsPedInAnyVehicle(playerPed, true) then
										TriggerServerEvent('esx_policedog:hasClosestDrugs', GetPlayerServerId(player))
									end
								end
							end
						end
					else
						ESX.ShowNotification('Votre chien est mort')
					end
				else
					ESX.ShowNotification('Vous n\'avez pas de chien')
				end
			end
		end)

		RageUI.ButtonWithStyle("Dire d'attaquer",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				if DoesEntityExist(policeDog) then
					if not IsPedDeadOrDying(policeDog) then
						if GetDistanceBetweenCoords(GetEntityCoords(policeDog), GetEntityCoords(PlayerPedId()), true) <= 3.0 then
							local player, distance = ESX.Game.GetClosestPlayer()
							if distance ~= -1 then
								if distance <= 3.0 then
									local playerPed = GetPlayerPed(player)
									if not IsPedInCombat(policeDog, playerPed) then
										if not IsPedInAnyVehicle(playerPed, true) then
											TaskCombatPed(policeDog, playerPed, 0, 16)
										end
									else
										ClearPedTasksImmediately(policeDog)
									end
								end
							end
						end
					else
						ESX.ShowNotification('Votre chien est mort')
					end
				else
					ESX.ShowNotification('Vous n\'avez pas de chien')
			end
		end
	end)

    end, function()
	end)

	RageUI.IsVisible(lspd_main, true, true, true, function()

		RageUI.Separator("↓ ~o~ Intéractions~s~ ↓")

		RageUI.ButtonWithStyle("Consulter les avis de recherche", nil, {RightLabel = "→→"}, true, function(_,_,s)
			if s then
				lspdADRData = nil
				TriggerServerEvent("corp:adrGet")
			end
		end, lspd_adr)

		RageUI.ButtonWithStyle("Lancer un avis de recherche", nil, {RightLabel = "→→"}, true, function()
		end, lspd_adrlaunch)

	end, function()    
	end, 1)

	RageUI.IsVisible(lspd_adr, true, true, true, function()

		if lspdADRData == nil then
			RageUI.Separator("")
			RageUI.Separator("~r~Aucun avis de recherche")
			RageUI.Separator("")
		else

			RageUI.Separator("↓ ~r~ Avis de recherche~s~ ↓")

			for index,adr in pairs(lspdADRData) do
				RageUI.ButtonWithStyle(colorVar.."[NV."..adr.dangerosity.."] ~s~"..adr.firstname.." "..adr.lastname, nil, { RightLabel = "~o~Consulter ~s~→→" }, true, function(_,_,s)
					if s then
						lspdADRindex = index
					end
				end, lspd_adrcheck)
			end
			
		end

	end, function()    
	end, 1)


	RageUI.IsVisible(lspd_adrlaunch, true, true, true, function()
		RageUI.ButtonWithStyle("Prénom : ~s~"..notNilString(lspdADRBuilder.firstname), "~r~Prénom : ~s~"..notNilString(lspdADRBuilder.firstname), { RightLabel = "→" }, true, function(_,_,s)
			if s then
				lspdADRBuilder.firstname = KeyboardInput("Prénom", "", 10)
			end
		end)

		RageUI.ButtonWithStyle("Nom : ~s~"..notNilString(lspdADRBuilder.lastname), "~r~Nom : ~s~"..notNilString(lspdADRBuilder.lastname), { RightLabel = "→" }, true, function(_,_,s)
			if s then
				lspdADRBuilder.lastname = KeyboardInput("Nom", "", 10)
			end
		end)

		RageUI.ButtonWithStyle("Motif :", "~r~Motif : ~s~"..notNilString(lspdADRBuilder.reason), { RightLabel = "→" }, true, function(_,_,s)
			if s then
				lspdADRBuilder.reason = KeyboardInput("Raison", "", 100)
			end
		end)

		RageUI.List("Dangerosité", lspdADRDangerosities, lspdADRBuilder.dangerosity, "~r~Dangerosité (Code) : ~s~"..notNilString(lspdADRBuilder.dangerosity), {}, true, function(Hovered, Active, Selected, Index)
			lspdADRBuilder.dangerosity = Index
		end)

		RageUI.ButtonWithStyle("~g~Sauvegarder et envoyer", "~r~Motif : ~s~"..notNilString(lspdADRBuilder.reason), { RightLabel = "→→" }, lspdADRBuilder.firstname ~= nil and lspdADRBuilder.lastname ~= nil and lspdADRBuilder.reason ~= nil, function(_,_,s)
			if s then
				RageUI.GoBack()
				TriggerServerEvent("corp:adrAdd", lspdADRBuilder)
				lspdADRBuilder = {dangerosity = 1}
				RageUI.Popup({message = "Avis de recherche ajouté à la base de données..."})
			end
		end)

	end, function()    
	end, 1)

	RageUI.IsVisible(lspd_adrcheck, true, true, true, function()
		RageUI.Separator("↓ ~o~Informations ~s~↓")
		RageUI.ButtonWithStyle("~b~Dépositaire: ~s~"..lspdADRData[lspdADRindex].author, nil, {}, true, function()end)
		RageUI.ButtonWithStyle("~b~Date: ~s~"..lspdADRData[lspdADRindex].date, nil, {}, true, function()end)
		RageUI.ButtonWithStyle("~o~Prénom: ~s~"..lspdADRData[lspdADRindex].firstname, nil, {}, true, function()end)
		RageUI.ButtonWithStyle("~o~Nom: ~s~"..lspdADRData[lspdADRindex].lastname, nil, {}, true, function()end)
		RageUI.ButtonWithStyle("~r~Dangerosité: ~s~"..getDangerosityNameByInt(lspdADRData[lspdADRindex].dangerosity), nil, {}, true, function()end)
		RageUI.ButtonWithStyle("~r~Raison: ~s~"..lspdADRData[lspdADRindex].reason, nil, {}, true, function()end)

		if ESX.PlayerData.job.grade >= 4 then
			RageUI.Separator("↓ ~o~Actions ~s~↓")
			RageUI.ButtonWithStyle("~r~Enlever l'avis de recherche", nil, {RightLabel = "→→"}, true, function(_,_,s)
				if s then
					RageUI.GoBack()
					TriggerServerEvent("corp:adrDel", lspdADRindex)
					RageUI.Popup({message = "Avis de recherche retiré de la base de données..."})
				end
			end)
		end

	end, function()    
	end, 1)


	if not RageUI.Visible(mf6p) and not RageUI.Visible(inter) and not RageUI.Visible(info) and not RageUI.Visible(props) and not RageUI.Visible(renfort) and not RageUI.Visible(voiture) and not RageUI.Visible(chien) and not RageUI.Visible(cam) and not RageUI.Visible(voiture) and not RageUI.Visible(megaphone) and not RageUI.Visible(gererlicenses) and not RageUI.Visible(lspd_main) and not RageUI.Visible(lspd_adrcheck) and not RageUI.Visible(lspd_adr) and not RageUI.Visible(lspd_adrlaunch) and not RageUI.Visible(fouiller) then
		mf6p = RMenu:DeleteType("mf6p", true)
	end
end
end

Keys.Register('F6', 'Police', 'Ouvrir le menu Police', function()
	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
    	Menuf6Police()
	end
end)


RegisterNetEvent('renfort:setBlip')
AddEventHandler('renfort:setBlip', function(coords, raison)
	if raison == 'petit' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		PlaySoundFrontend(-1, "OOB_Start", "GTAO_FM_Events_Soundset", 1)
		ESX.ShowAdvancedNotification('LSPD INFORMATIONS', '~b~Demande de renfort', 'Demande de renfort demandé.\nRéponse: ~g~CODE-2\n~w~Importance: ~g~Légère.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
		color = 2
	elseif raison == 'importante' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		PlaySoundFrontend(-1, "OOB_Start", "GTAO_FM_Events_Soundset", 1)
		ESX.ShowAdvancedNotification('LSPD INFORMATIONS', '~b~Demande de renfort', 'Demande de renfort demandé.\nRéponse: ~g~CODE-3\n~w~Importance: ~o~Importante.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
		color = 47
	elseif raison == 'omgad' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		PlaySoundFrontend(-1, "OOB_Start", "GTAO_FM_Events_Soundset", 1)
		PlaySoundFrontend(-1, "FocusIn", "HintCamSounds", 1)
		ESX.ShowAdvancedNotification('LSPD INFORMATIONS', '~b~Demande de renfort', 'Demande de renfort demandé.\nRéponse: ~g~CODE-99\n~w~Importance: ~r~URGENTE !\nDANGER IMPORTANT', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
		PlaySoundFrontend(-1, "FocusOut", "HintCamSounds", 1)
		color = 1
	end
	local blipId = AddBlipForCoord(coords)
	SetBlipSprite(blipId, 161)
	SetBlipScale(blipId, 1.2)
	SetBlipColour(blipId, color)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString('Demande renfort')
	EndTextCommandSetBlipName(blipId)
	Wait(80 * 1000)
	RemoveBlip(blipId)
end)

RegisterNetEvent('police:InfoService')
AddEventHandler('police:InfoService', function(service, nom)
	if service == 'prise' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('LSPD INFORMATIONS', '~b~Prise de service', 'Agent: ~g~'..nom..'\n~w~Code: ~g~10-8\n~w~Information: ~g~Prise de service.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'fin' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('LSPD INFORMATIONS', '~b~Fin de service', 'Agent: ~g~'..nom..'\n~w~Code: ~g~10-10\n~w~Information: ~g~Fin de service.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'pause' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('LSPD INFORMATIONS', '~b~Pause de service', 'Agent: ~g~'..nom..'\n~w~Code: ~g~10-6\n~w~Information: ~g~Pause de service.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'standby' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('LSPD INFORMATIONS', '~b~Mise en standby', 'Agent: ~g~'..nom..'\n~w~Code: ~g~10-12\n~w~Information: ~g~Standby, en attente de dispatch.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'control' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('LSPD INFORMATIONS', '~b~Control routier', 'Agent: ~g~'..nom..'\n~w~Code: ~g~10-48\n~w~Information: ~g~Control routier en cours.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'refus' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('LSPD INFORMATIONS', '~b~Refus d\'obtemperer', 'Agent: ~g~'..nom..'\n~w~Code: ~g~10-30\n~w~Information: ~g~Refus d\'obtemperer / Delit de fuite en cours.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'crime' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('LSPD INFORMATIONS', '~b~Crime en cours', 'Agent: ~g~'..nom..'\n~w~Code: ~g~10-31\n~w~Information: ~g~Crime en cours / poursuite en cours.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	end
end)

RegisterNetEvent('finalpolice:handcuff')
AddEventHandler('finalpolice:handcuff', function()

IsHandcuffed    = not IsHandcuffed;
local playerPed = GetPlayerPed(-1)

Citizen.CreateThread(function()

if IsHandcuffed then

	RequestAnimDict('mp_arresting')
	while not HasAnimDictLoaded('mp_arresting') do
		Citizen.Wait(100)
	end

	TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)
	DisableControlAction(2, 37, true)
	SetEnableHandcuffs(playerPed, true)
	SetPedCanPlayGestureAnims(playerPed, false)
	FreezeEntityPosition(playerPed,  true)
	DisableControlAction(0, 24, true) -- Attack
	DisableControlAction(0, 257, true) -- Attack 2
	DisableControlAction(0, 25, true) -- Aim
	DisableControlAction(0, 263, true) -- Melee Attack 1
	DisableControlAction(0, 37, true) -- Select Weapon
	DisableControlAction(0, 47, true)  -- Disable weapon
	DisplayRadar(false)

else

	ClearPedSecondaryTask(playerPed)
	SetEnableHandcuffs(playerPed, false)
	SetPedCanPlayGestureAnims(playerPed,  true)
	FreezeEntityPosition(playerPed, false)
	DisplayRadar(true)

end

  end)
end)

RegisterNetEvent('finalpolice:drag')
AddEventHandler('finalpolice:drag', function(cop)
  IsDragged = not IsDragged
  CopPed = tonumber(cop)
end)

Citizen.CreateThread(function()
  while true do
    Wait(0)
    if IsHandcuffed then
      if IsDragged then
        local ped = GetPlayerPed(GetPlayerFromServerId(CopPed))
        local myped = GetPlayerPed(-1)
        AttachEntityToEntity(myped, ped, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
      else
        DetachEntity(GetPlayerPed(-1), true, false)
      end
    end
  end
end)

RegisterNetEvent('finalpolice:putInVehicle')
AddEventHandler('finalpolice:putInVehicle', function()
  local playerPed = GetPlayerPed(-1)
  local coords    = GetEntityCoords(playerPed)
  if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
    local vehicle = GetClosestVehicle(coords.x,  coords.y,  coords.z,  5.0,  0,  71)
    if DoesEntityExist(vehicle) then
      local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
      local freeSeat = nil
      for i=maxSeats - 1, 0, -1 do
        if IsVehicleSeatFree(vehicle,  i) then
          freeSeat = i
          break
        end
      end
      if freeSeat ~= nil then
        TaskWarpPedIntoVehicle(playerPed,  vehicle,  freeSeat)
      end
    end
  end
end)

RegisterNetEvent('finalpolice:OutVehicle')
AddEventHandler('finalpolice:OutVehicle', function(t)
  local ped = GetPlayerPed(t)
  ClearPedTasksImmediately(ped)
  plyPos = GetEntityCoords(GetPlayerPed(-1),  true)
  local xnew = plyPos.x+2
  local ynew = plyPos.y+2

  SetEntityCoords(GetPlayerPed(-1), xnew, ynew, plyPos.z)
end)

-- Handcuff
Citizen.CreateThread(function()
  while true do
    Wait(0)
    if IsHandcuffed then
      DisableControlAction(0, 142, true) -- MeleeAttackAlternate
      DisableControlAction(0, 30,  true) -- MoveLeftRight
      DisableControlAction(0, 31,  true) -- MoveUpDown
    end
  end
end)

local PlayerData = {}
local societypolicemoney = nil

function notNilString(str)
    if str == nil then
        return ""
    else
        return str
    end
end

function spawnObject(name)
	local plyPed = PlayerPedId()
	local coords = GetEntityCoords(plyPed, false) + (GetEntityForwardVector(plyPed) * 1.0)

	ESX.Game.SpawnObject(name, coords, function(obj)
		SetEntityHeading(obj, GetEntityPhysicsHeading(plyPed))
		PlaceObjectOnGroundProperly(obj)
	end)
end

function BossPolice()
	local fPolice = RageUI.CreateMenu("Actions Patron", "Police")
  
	  RageUI.Visible(fPolice, not RageUI.Visible(fPolice))
  
			  while fPolice do
				  Citizen.Wait(0)
					  RageUI.IsVisible(fPolice, true, true, true, function()
  
					  if societypolicemoney ~= nil then
						  RageUI.ButtonWithStyle("Argent société :", nil, {RightLabel = "$" .. societypolicemoney}, true, function()
						  end)
					  end
  
					  RageUI.ButtonWithStyle("Retirer de l'argent",nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
						  if Selected then
							  local amount = KeyboardInput("Montant", "", 10)
							  amount = tonumber(amount)
							  if amount == nil then
								  RageUI.Popup({message = "Montant invalide"})
							  else
								  TriggerServerEvent('esx_society:withdrawMoney', 'police', amount)
								  RefreshpoliceMoney()
							  end
						  end
					  end)
  
					  RageUI.ButtonWithStyle("Déposer de l'argent",nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
						  if Selected then
							  local amount = KeyboardInput("Montant", "", 10)
							  amount = tonumber(amount)
							  if amount == nil then
								  RageUI.Popup({message = "Montant invalide"})
							  else
								  TriggerServerEvent('esx_society:depositMoney', 'police', amount)
								  RefreshpoliceMoney()
							  end
						  end
					  end) 
  
					  RageUI.ButtonWithStyle("Recruter", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
						if (Selected) then   
							local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
							if closestPlayer ~= -1 and closestDistance <= 3.0 then
								TriggerServerEvent('patron:recruter', "police", false, GetPlayerServerId(closestPlayer))
							 else
								ESX.ShowNotification('Aucun joueur à proximité')
							end 
							
						end
						end)
						RageUI.ButtonWithStyle("Promouvoir", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
						if (Selected) then   
							local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
							if closestPlayer ~= -1 and closestDistance <= 3.0 then
								TriggerServerEvent('patron:promouvoir', "police", false, GetPlayerServerId(closestPlayer))
							 else
								ESX.ShowNotification('Aucun joueur à proximité')
							end 
							
						end
						end)
						RageUI.ButtonWithStyle("Rétrograder", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
						if (Selected) then   
							local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
							if closestPlayer ~= -1 and closestDistance <= 3.0 then
								TriggerServerEvent('patron:descendre', "police", false, GetPlayerServerId(closestPlayer))
							 else
								ESX.ShowNotification('Aucun joueur à proximité')
							end 
							
						end
						end)
						RageUI.ButtonWithStyle("Virer", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
						if (Selected) then   
							local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
							if closestPlayer ~= -1 and closestDistance <= 3.0 then
								TriggerServerEvent('patron:virer', "police", false, GetPlayerServerId(closestPlayer))
							 else
								ESX.ShowNotification('Aucun joueur à proximité')
							end 
							
						end
						end)

						RageUI.ButtonWithStyle('Actions sur salariés', "Soon In VIP > patreon.com/five_dev", {RightBadge = RageUI.BadgeStyle.Lock }, false, function(Hovered, Active, Selected)
							if (Selected) then
								end 
						end)
						
				  end, function()
			  end)
			  if not RageUI.Visible(fPolice) then
			  fPolice = RMenu:DeleteType("Actions Patron", true)
		  end
	  end
  end   
  
Citizen.CreateThread(function()
	  while true do
		  local Timer = 800
		  if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' and ESX.PlayerData.job.grade_name == 'boss' then
		  local plyCoords3 = GetEntityCoords(GetPlayerPed(-1), false)
		  local dist3 = Vdist(plyCoords3.x, plyCoords3.y, plyCoords3.z, Config.pos.boss.position.x, Config.pos.boss.position.y, Config.pos.boss.position.z)
		  if dist3 <= 7.0 then
			  Timer = 0
			  DrawMarker(20, Config.pos.boss.position.x, Config.pos.boss.position.y, Config.pos.boss.position.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 255, 255, 0, 1, 2, 0, nil, nil, 0)
			  end
			  if dist3 <= 2.0 then
				  Timer = 0   
						RageUI.Text({ message = "Appuyez sur ~b~[E]~s~ pour accéder aux actions de patron", time_display = 1 })
						if IsControlJustPressed(1,51) then
						RefreshpoliceMoney()           
						BossPolice()
					  end   
				  end
			  end 
		  Citizen.Wait(Timer)
	  end
end)

function RefreshpoliceMoney()
	if ESX.PlayerData.job ~= nil and ESX.PlayerData.job.grade_name == 'boss' then
		ESX.TriggerServerCallback('esx_society:getSocietyMoney', function(money)
			UpdateSocietypoliceMoney(money)
		end, ESX.PlayerData.job.name)
	end
end

function UpdateSocietypoliceMoney(money)
	societypolicemoney = ESX.Math.GroupDigits(money)
end
 
--------------------------------------------------------------------------------------------------------------------------------------- 
-- p. coffre

function Coffrepolice()
    local Cpolice = RageUI.CreateMenu("Coffre", "Los Santos Police Departement")
	local Stockpolice = RageUI.CreateSubMenu(Stockpolice, "Coffre", "Los Santos Police Departement")

        RageUI.Visible(Cpolice, not RageUI.Visible(Cpolice))
            while Cpolice do
            Citizen.Wait(0)
            RageUI.IsVisible(Cpolice, true, true, true, function()

                RageUI.Separator("↓ Objet(s) ↓")

                    RageUI.ButtonWithStyle("Retirer Objet(s)",nil, {RightLabel = ""}, true, function(Hovered, Active, Selected)
                        if Selected then
                            FRetirerobjet()
                            RageUI.CloseAll()
                        end
                    end)
                    
                    RageUI.ButtonWithStyle("Déposer Objet(s)",nil, {RightLabel = ""}, true, function(Hovered, Active, Selected)
                        if Selected then
                            ADeposerobjet()
                            RageUI.CloseAll()
                        end
                    end)

					RageUI.Separator("↓ Arme(s) ↓")

						RageUI.ButtonWithStyle("Prendre Arme(s)",nil, {RightLabel = ""}, true, function(Hovered, Active, Selected)
							if Selected then
								OpenGetWeaponMenu()
								RageUI.CloseAll()
							end
						end)
						
						RageUI.ButtonWithStyle("Déposer Arme(s)",nil, {RightLabel = ""}, true, function(Hovered, Active, Selected)
							if Selected then
								OpenPutWeaponMenu()
								RageUI.CloseAll()
							end
						end)

                end, function()
                end)

            if not RageUI.Visible(Cpolice) then
            Cpolice = RMenu:DeleteType("Coffre", true)
        end
    end
end

Citizen.CreateThread(function()
	while true do
		local Timer = 800
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
		local plycrdjob = GetEntityCoords(GetPlayerPed(-1), false)
		local jobdist = Vdist(plycrdjob.x, plycrdjob.y, plycrdjob.z, Config.pos.coffre.position.x, Config.pos.coffre.position.y, Config.pos.coffre.position.z)
		if jobdist <= 10.0 then
			Timer = 0
			DrawMarker(20, Config.pos.coffre.position.x, Config.pos.coffre.position.y, Config.pos.coffre.position.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 255, 255, 0, 1, 2, 0, nil, nil, 0)
			end
			if jobdist <= 1.0 then
				Timer = 0
					RageUI.Text({ message = "Appuyez sur ~b~[E]~s~ pour accéder au coffre", time_display = 1 })
					if IsControlJustPressed(1,51) then
					Coffrepolice()
				end   
			end
		end 
	Citizen.Wait(Timer)   
end
end)

---------------------------------------------------------------------------------------------------------------------------------------

itemstock = {}
function FRetirerobjet()
    local Stockpolice = RageUI.CreateMenu("Coffre", "Police")
    ESX.TriggerServerCallback('fpolice:getStockItems', function(items) 
    itemstock = items
   
    RageUI.Visible(Stockpolice, not RageUI.Visible(Stockpolice))
        while Stockpolice do
            Citizen.Wait(0)
                RageUI.IsVisible(Stockpolice, true, true, true, function()
                        for k,v in pairs(itemstock) do 
                            if v.count > 0 then
                            RageUI.ButtonWithStyle(v.label, nil, {RightLabel = v.count}, true, function(Hovered, Active, Selected)
                                if Selected then
                                    local count = KeyboardInput("Combien ?", "", 2)
                                    TriggerServerEvent('fpolice:getStockItem', v.name, tonumber(count))
                                    FRetirerobjet()
                                end
                            end)
                        end
                    end
                end, function()
                end)
            if not RageUI.Visible(Stockpolice) then
            Stockpolice = RMenu:DeleteType("Coffre", true)
        end
    end
     end)
end

local PlayersItem = {}
function ADeposerobjet()
    local StockPlayer = RageUI.CreateMenu("Coffre", "Police")
    ESX.TriggerServerCallback('fpolice:getPlayerInventory', function(inventory)
        RageUI.Visible(StockPlayer, not RageUI.Visible(StockPlayer))
    while StockPlayer do
        Citizen.Wait(0)
            RageUI.IsVisible(StockPlayer, true, true, true, function()
                for i=1, #inventory.items, 1 do
                    if inventory ~= nil then
                         local item = inventory.items[i]
                            if item.count > 0 then
                                        RageUI.ButtonWithStyle(item.label, nil, {RightLabel = item.count}, true, function(Hovered, Active, Selected)
                                            if Selected then
                                            local count = KeyboardInput("Combien ?", '' , 8)
                                            TriggerServerEvent('fpolice:putStockItems', item.name, tonumber(count))
                                            ADeposerobjet()
                                        end
                                    end)
                                end
                            else
                                RageUI.Separator('Chargement en cours')
                            end
                        end
                    end, function()
                    end)
                if not RageUI.Visible(StockPlayer) then
                StockPlayer = RMenu:DeleteType("Coffre", true)
            end
        end
    end)
end


--------------------------------------------------------------------------------------------------
-- p. Vest

Citizen.CreateThread(function()
    while true do
        local Timer = 800
        if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
        local plyCoords3 = GetEntityCoords(GetPlayerPed(-1), false)
        local dist3 = Vdist(plyCoords3.x, plyCoords3.y, plyCoords3.z, Config.pos.vestiaire.position.x, Config.pos.vestiaire.position.y, Config.pos.vestiaire.position.z)
        if dist3 <= 7.0 then
            Timer = 0
            DrawMarker(20, Config.pos.vestiaire.position.x, Config.pos.vestiaire.position.y, Config.pos.vestiaire.position.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 255, 255, 0, 1, 2, 0, nil, nil, 0)
            end
            if dist3 <= 2.0 then
                Timer = 0   
                        RageUI.Text({ message = "Appuyez sur ~b~[E]~s~ pour accéder au vestiaire", time_display = 1 })
                        if IsControlJustPressed(1,51) then
							CloackRoomPolice()
                    end   
                end
            end 
        Citizen.Wait(Timer)
    end
end)

function CloackRoomPolice()
	local ckr = RageUI.CreateMenu("L.S.P.D", "Los Santos Police Departement")
	RageUI.Visible(ckr, not RageUI.Visible(ckr))
	while ckr do
		Citizen.Wait(0)
			RageUI.IsVisible(ckr, true, true, true, function()

					RageUI.Separator("~o~"..GetPlayerName(PlayerId()).. "~w~ - ~o~" ..ESX.PlayerData.job.grade_label.. "")

						for index,infos in pairs(police.clothes.specials) do
							RageUI.ButtonWithStyle(infos.label,nil, {RightBadge = RageUI.BadgeStyle.Clothes}, ESX.PlayerData.job.grade >= infos.minimum_grade, function(_,_,s)
								if s then
									ApplySkin(infos)
								end
							end)
						end

                        RageUI.Separator("~o~Gestion du Gilet par balle")

						for index,infos in pairs(police.clothes.grades) do
							RageUI.ButtonWithStyle(infos.label,nil, {RightBadge = RageUI.BadgeStyle.Clothes}, ESX.PlayerData.job.grade >= infos.minimum_grade, function(_,_,s)
							if s then
								ApplySkin(infos)
								SetPedArmour(PlayerPedId(), 100)
							end
						end)
					end
				
				end, function() 
				end)
		
			if not RageUI.Visible(ckr) then
			ckr = RMenu:DeleteType("ckr", true)
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------
-- p. Garage

function GaragePolice()
    local gp = RageUI.CreateMenu("~y~Garage", "Liste des voitures")
    RageUI.Visible(gp, not RageUI.Visible(gp))
    while gp do
        Citizen.Wait(0)
            RageUI.IsVisible(gp, true, true, true, function()

			local pCo = GetEntityCoords(PlayerPedId())
	
			for k,v in pairs(police.vehicles.car) do
				if v.category ~= nil then 
					RageUI.Separator(v.category)
				else 
					RageUI.ButtonWithStyle(v.label, nil, {RightLabel = "Stock(s): [~b~"..v.stock.."~s~]"}, ESX.PlayerData.job.grade >= v.minimum_grade, function(_,_,s)
						if s then
							if v.stock > 0 then
							Citizen.CreateThread(function()
								local model = GetHashKey(v.model)
								RequestModel(model)
								while not HasModelLoaded(model) do Citizen.Wait(1) end
								local vehicle = CreateVehicle(model, Config.spawn.spawnvoiture.position.x, Config.spawn.spawnvoiture.position.y, Config.spawn.spawnvoiture.position.z, Config.spawn.spawnvoiture.position.h, true, false)
								SetModelAsNoLongerNeeded(model)
								SetPedIntoVehicle(GetPlayerPed(-1), vehicle, -1)
								TriggerServerEvent('ddx_vehiclelock:givekey', 'no', GetVehicleNumberPlateText(vehicle))
								SetVehicleMaxMods(vehicle)
								police_garage = false
								RageUI.CloseAll()
								v.stock = v.stock - 1
							end)
							else 
								RageUI.Popup({message = "Plus de véhicule chef"})
							end
						end
					end)
				end
			end

			RageUI.ButtonWithStyle("Ranger le véhicule", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
				if (Selected) then
					local veh,dist4 = ESX.Game.GetClosestVehicle(playerCoords)  

						if dist4 < 5 then
						DeleteEntity(veh)
						TriggerServerEvent('ddx_vehiclelock:deletekeyjobs', 'no')
						end

					end
				end) 
				end, function()    
				end)

		if not RageUI.Visible(gp) then
			gp = RMenu:DeleteType("gp", true)
		end
	end
end

Citizen.CreateThread(function()
    while true do
        local Timer = 800
        if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
        local plyCoords3 = GetEntityCoords(GetPlayerPed(-1), false)
        local dist3 = Vdist(plyCoords3.x, plyCoords3.y, plyCoords3.z, Config.pos.garagevoiture.position.x, Config.pos.garagevoiture.position.y, Config.pos.garagevoiture.position.z)
            if dist3 <= 5.0 then 
                Timer = 0
                        RageUI.Text({ message = "Appuyer sur [~b~E~w~] pour intéragir", time_display = 1 })
                        if IsControlJustPressed(1,51) then
                            GaragePolice()
                    end   
                end
            end 
        Citizen.Wait(Timer)
    end
end)

function GarageHeliPolice()
	local ghp = RageUI.CreateMenu("~y~Garage", "Liste des hélicoptère")
		RageUI.Visible(ghp, not RageUI.Visible(ghp))
			while ghp do
    			Citizen.Wait(0)
        			RageUI.IsVisible(ghp, true, true, true, function()
  
					RageUI.ButtonWithStyle("Ranger au garage", nil, {RightLabel = "→→→"},true, function(Hovered, Active, Selected)
					if (Selected) then   
					local veh,dist4 = ESX.Game.GetClosestVehicle(playerCoords)
					if dist4 < 4 then
						DeleteEntity(veh)
						RageUI.CloseAll()
						end 
					end
				end) 
		
					RageUI.ButtonWithStyle("Hélico du LSPD", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
					if (Selected) then
					Citizen.Wait(1)  
					spawnuniCarre("buzzard")
					RageUI.CloseAll()
					end
				end)
              
                  end, function()
                  end)
   
		if not RageUI.Visible(ghp) then
			ghp = RMenu:DeleteType("ghp", true)
		end
	end
end
      
Citizen.CreateThread(function()
while true do
    local Timer = 800
    if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
    local plyCoords3 = GetEntityCoords(GetPlayerPed(-1), false)
    local dist3 = Vdist(plyCoords3.x, plyCoords3.y, plyCoords3.z, Config.pos.garageheli.position.x, Config.pos.garageheli.position.y, Config.pos.garageheli.position.z)
        if dist3 <= 2.0 then 
            Timer = 0
                    RageUI.Text({ message = "Appuyer sur [~b~E~w~] pour intéragir", time_display = 1 })
                    if IsControlJustPressed(1,51) then
                        GarageHeliPolice()
                end   
            end
        end 
        Citizen.Wait(Timer)
    end
end)

  function spawnuniCarre(car)
      local car = GetHashKey(car)
      RequestModel(car)
      while not HasModelLoaded(car) do
          RequestModel(car)
          Citizen.Wait(0)
      end
      local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), false))
      local vehicle = CreateVehicle(car, Config.spawn.spawnheli.position.x, Config.spawn.spawnheli.position.y, Config.spawn.spawnheli.position.z, Config.spawn.spawnheli.position.h, true, false)
      SetEntityAsMissionEntity(vehicle, true, true)
      local plaque = "LSPD"..math.random(1,9)
      SetVehicleNumberPlateText(vehicle, plaque) 
      SetPedIntoVehicle(GetPlayerPed(-1),vehicle,-1)
      SetVehicleMaxMods(vehicle)
end

------- armurerie

function ArmureriePolice()
    local armp = RageUI.CreateMenu("Armurerie", "Los Santos Police Departement")
    RageUI.Visible(armp, not RageUI.Visible(armp))
    while armp do
        Citizen.Wait(0)
            RageUI.IsVisible(armp, true, true, true, function()

			RageUI.ButtonWithStyle("Rendre les armes de service", nil, {RightLabel = "→"}, true, function(h, a, s)
				if s then
					RageUI.Popup({message = "Vous avez déposer toutes vos armes de service !"})
					RemoveAllPedWeapons(PlayerPedId(), true)
				end
			end)

            RageUI.ButtonWithStyle("Equipement de base", nil, { },true, function(Hovered, Active, Selected)
                if (Selected) then   
                    TriggerServerEvent('equipementbase')
                end
            end)

            for k,v in pairs(Config.armurerie) do
				if ESX.PlayerData.job.grade >= v.minimum_grade then
                RageUI.ButtonWithStyle(v.nom, nil, { },true, function(Hovered, Active, Selected)
                    if (Selected) then   
                        TriggerServerEvent('armurerie', v.arme, v.prix)
                    end
                end)
			end
		end

        end, function()
        end)
        if not RageUI.Visible(armp) then
            armp = RMenu:DeleteType("armp", true)
        end
    end
end

Citizen.CreateThread(function()
    while true do
        local Timer = 800
        if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
        local plyCoords3 = GetEntityCoords(GetPlayerPed(-1), false)
        local dist3 = Vdist(plyCoords3.x, plyCoords3.y, plyCoords3.z, Config.pos.armurerie.position.x, Config.pos.armurerie.position.y, Config.pos.armurerie.position.z)
            if dist3 <= 2.0 then 
                Timer = 0
                        RageUI.Text({ message = "Appuyer sur [~b~E~w~] pour intéragir", time_display = 1 })
                        if IsControlJustPressed(1,51) then
                            ArmureriePolice()
                    end   
                end
            end 
        Citizen.Wait(Timer)
    end
end)


Citizen.CreateThread(function()
    local hash = GetHashKey("mp_m_shopkeep_01")
    while not HasModelLoaded(hash) do
    RequestModel(hash)
    Wait(20)
	end
	ped = CreatePed("PED_TYPE_CIVMALE", "s_m_y_cop_01", Config.pos.garageheli.position.x, Config.pos.garageheli.position.y, Config.pos.garageheli.position.z, Config.pos.garageheli.position.h, false, true)
	ped = CreatePed("PED_TYPE_CIVMALE", "s_m_y_cop_01", Config.pos.garagevoiture.position.x, Config.pos.garagevoiture.position.y, Config.pos.garagevoiture.position.z, Config.pos.garagevoiture.position.h, false, true)
	ped = CreatePed("PED_TYPE_CIVMALE", "s_m_y_cop_01", Config.pos.plainterdv.position.x, Config.pos.plainterdv.position.y, Config.pos.plainterdv.position.z, Config.pos.plainterdv.position.h, false, true)
	ped = CreatePed("PED_TYPE_CIVMALE", "s_m_y_cop_01", Config.pos.armurerie.position.x, Config.pos.armurerie.position.y, Config.pos.armurerie.position.z, Config.pos.armurerie.position.h, false, true)
	ped = CreatePed("PED_TYPE_CIVMALE", "s_m_y_cop_01", Config.pos.garagebateau.position.x, Config.pos.garagebateau.position.y, Config.pos.garagebateau.position.z, Config.pos.garagebateau.position.h, false, true)
	SetBlockingOfNonTemporaryEvents(ped, true)
	FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
end)

function BateauPolice()
    local batp = RageUI.CreateMenu("Garage", "Pour sortir des bateau de police.")
    RageUI.Visible(batp, not RageUI.Visible(batp))
    while batp do
        Citizen.Wait(0)
            RageUI.IsVisible(batp, true, true, true, function()
        	RageUI.ButtonWithStyle("Ranger bateau", "Pour ranger un bateau.", {RightLabel = "→→→"},true, function(Hovered, Active, Selected)
            if (Selected) then   
            local veh,dist4 = ESX.Game.GetClosestVehicle(playerCoords)
			if dist4 < 9 then
				DeleteEntity(veh)
			end	
            end
            end)         
            if ESX.PlayerData.job.grade_name == 'sergeant' or ESX.PlayerData.job.grade_name == 'lieutenant' or ESX.PlayerData.job.grade_name == 'boss' then 
            RageUI.ButtonWithStyle("Bateau", "Pour sortir un bateau.", {RightLabel = "→→→"},true, function(Hovered, Active, Selected)
            if (Selected) then 
            spawnbatopolice("predator")
            end
            end)
        	
        end

            
        end, function()
        end)
        if not RageUI.Visible(batp) then
            batp = RMenu:DeleteType("batp", true)
        end
    end
end

Citizen.CreateThread(function()
    while true do
        local Timer = 800
        if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
        local plyCoords3 = GetEntityCoords(GetPlayerPed(-1), false)
        local dist3 = Vdist(plyCoords3.x, plyCoords3.y, plyCoords3.z, Config.pos.garagebateau.position.x, Config.pos.garagebateau.position.y, Config.pos.garagebateau.position.z)
            if dist3 <= 2.0 then 
                Timer = 0
                        RageUI.Text({ message = "Appuyez sur [~b~E~w~] pour accéder au garage bateau", time_display = 1 })
                        if IsControlJustPressed(1,51) then
                            BateauPolice()
                    end   
                end
            end 
            Citizen.Wait(Timer)
        end
    end)

function spawnbatopolice(car)
    local car = GetHashKey(car)
    RequestModel(car)
    while not HasModelLoaded(car) do
        RequestModel(car)
        Citizen.Wait(0)
    end
    local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), false))
    local vehicle = CreateVehicle(car, Config.spawn.spawnbato.position.x, Config.spawn.spawnbato.position.y, Config.spawn.spawnbato.position.z, Config.spawn.spawnbato.position.h, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    local plaque = "LSPDH"..math.random(1,9).."C"..math.random(1,9)
    SetVehicleNumberPlateText(vehicle, plaque) 
    SetPedIntoVehicle(GetPlayerPed(-1),vehicle,-1) 
    TriggerServerEvent('ddx_vehiclelock:givekey', 'no', GetVehicleNumberPlateText(vehicle))
end


------------------------------------------------------------------------------------------

local FirstName = nil
local LastName = nil
local Subject = nil
local Desc = nil
local tel = nil
local cansend = false

function ServicePolice()
    local servpopo = RageUI.CreateMenu("Accueil de Police", "Que puis-je faire pour vous ?")
	local plainte = RageUI.CreateSubMenu(servpopo, "L.S.P.D", "Los Santos Police Departement")
    RageUI.Visible(servpopo, not RageUI.Visible(servpopo))
    while servpopo do
        Citizen.Wait(0)
            RageUI.IsVisible(servpopo, true, true, true, function()

			RageUI.ButtonWithStyle("Appeler un agent de police ", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
				if (Selected) then  
				TriggerServerEvent("genius:sendcall") 
                Notification("~r~Central LSPD",nil, "Votre appel à bien été pris en compte", "CHAR_CALL911", 8)
				end
			end)

			RageUI.ButtonWithStyle("Déposer une plainte", nil, {RightLabel = "→"},true, function()
			end, plainte)    
            
    end, function()
	end)

	RageUI.IsVisible(plainte, true, true, true, function()

		RageUI.ButtonWithStyle("Votre Nom : ~s~"..notNilString(LastName), nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
			if (Selected) then   
                LastName = KeyboardInput("Votre Nom:",nil,20)
			end
		end)   

		RageUI.ButtonWithStyle("Votre Prénom : ~s~"..notNilString(FirstName), nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
			if (Selected) then   
                FirstName = KeyboardInput("Votre Prénom:",nil,20)
			end
		end)   

		RageUI.ButtonWithStyle("Votre Numéro de téléphone~s~ : ~s~"..notNilString(tel), nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
			if (Selected) then   
                tel = KeyboardInput("Votre Numéro :",nil,350)
			end
		end)   

		RageUI.ButtonWithStyle("Sujet de votre Plainte~s~ : ~s~"..notNilString(Subject), nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
			if (Selected) then   
                Subject = KeyboardInput("Votre Sujet:",nil,30)
			end
		end)   

		RageUI.ButtonWithStyle("Votre Plainte~s~ : ~s~"..notNilString(Desc), nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
			if (Selected) then   
                Desc = KeyboardInput("Votre Description:",nil,350)
			end
		end)  

		if LastName ~= nil and LastName ~= "" and FirstName ~= nil and FirstName ~= "" and tel ~= nil and tel ~= "" and Subject ~= nil and Subject ~= "" and Desc ~= nil and Desc ~= "" then
			cansend = true
		end

        RageUI.ButtonWithStyle("~g~~h~Envoyer", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
            if (Selected) then   
                RageUI.CloseAll()
                TriggerServerEvent("genius:sendplainte", LastName, FirstName,tel ,Subject, Desc)
                Notification("~r~Central LSPD",nil, "Votre plainte à bien été pris en compte", "CHAR_CALL911", 8)
                reset()
            end
        end)

	end, function()
	end)
	
        if not RageUI.Visible(servpopo) and not RageUI.Visible(plainte) then
            servpopo = RMenu:DeleteType("servpopo", true)
        end
    end
end

Citizen.CreateThread(function()
    while true do
        local Timer = 800
        local plyCoords3 = GetEntityCoords(GetPlayerPed(-1), false)
        local dist3 = Vdist(plyCoords3.x, plyCoords3.y, plyCoords3.z, Config.pos.plainterdv.position.x, Config.pos.plainterdv.position.y, Config.pos.plainterdv.position.z)
		if dist3 <= 15.0 then 
			Timer = 0
		DrawMarker(20, 441.04, -981.91, 30.68, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 255, 255, 0, 1, 2, 0, nil, nil, 0)
		end
		if dist3 <= 5.0 then 
                Timer = 0
                        RageUI.Text({ message = "Appuyez sur [~b~E~w~] pour accéder aux services de police", time_display = 1 })
                        if IsControlJustPressed(1,51) then
                            ServicePolice()
                    end   
                end
        Citizen.Wait(Timer)
    end
end)

function OpenBillingMenu()

	ESX.UI.Menu.Open(
	  'dialog', GetCurrentResourceName(), 'billing',
	  {
		title = "Amende"
	  },
	  function(data, menu)
	  
		local amount = tonumber(data.value)
		local player, distance = ESX.Game.GetClosestPlayer()
  
		if player ~= -1 and distance <= 3.0 then
  
		  menu.close()
		  if amount == nil then
			  ESX.ShowNotification("~r~Problèmes~s~: Montant invalide")
		  else
			local playerPed        = GetPlayerPed(-1)
			TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TIME_OF_DEATH', 0, true)
			Citizen.Wait(5000)
			  TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(player), "society_police", ('police'), amount)
			  Citizen.Wait(100)
			  ESX.ShowNotification("~r~Vous avez bien envoyer la facture")
		  end
  
		else
		  ESX.ShowNotification("~r~Problèmes~s~: Aucun joueur à proximitée")
		end
  
	  end,
	  function(data, menu)
		  menu.close()
	  end
	)
  end
---------------------------------- p. casier

function CasierPolice()
	local CdePopop = RageUI.CreateMenu("Casier Judiciaire", "Los Santos Police Departement")
	local cj_infos = RageUI.CreateSubMenu(CdePopop, "Casier Judiciaire", "Los Santos Police Departement")
	local cj = RageUI.CreateSubMenu(CdePopop, "Casier Judiciaire", "Los Santos Police Departement")
	local cj_add = RageUI.CreateSubMenu(CdePopop, "Casier Judiciaire", "Los Santos Police Departement")

	  RageUI.Visible(CdePopop, not RageUI.Visible(CdePopop))
  
			  while CdePopop do
				  Citizen.Wait(0)
					  RageUI.IsVisible(CdePopop, true, true, true, function()

					RageUI.Separator("↓ ~o~ Intéractions~s~ ↓")
		
					RageUI.ButtonWithStyle("Consulter la base de données", nil, {RightLabel = "→"}, true, function(_,_,s)
						if s then
							lspdCJData = nil
							TriggerServerEvent("corp:cjGet")
						end
					end, cj)

					RageUI.ButtonWithStyle("Ajouter un civil à la base de données", nil, {RightLabel = "→"}, true, function()
					end, cj_add)


				end, function()
			  	end)
		
			RageUI.IsVisible(cj, true, true, true, function()
		
				if lspdCJData == nil then
					RageUI.Separator("")
					RageUI.Separator("~r~Aucun casier")
					RageUI.Separator("")
				else
					for index,cj in pairs(lspdCJData) do
						RageUI.ButtonWithStyle("→ "..cj.firstname.." "..cj.lastname, nil, { RightLabel = "~b~→→" }, true, function(_,_,s)
							if s then
								lspdCJindex = index
							end
						end, cj_infos)
					end
					
				end
		
			end, function()
			end)
		
			RageUI.IsVisible(cj_add, true, true, true, function()

				RageUI.ButtonWithStyle("Prénom : ~b~"..notNilString(lspdCJBuilder.firstname), "~r~Prénom : ~s~"..notNilString(lspdCJBuilder.firstname), { RightLabel = "→" }, true, function(_,_,s)
					if s then
						lspdCJBuilder.firstname = KeyboardInput("Prénom", "", 10)
					end
				end)
		
				RageUI.ButtonWithStyle("Nom : ~b~"..notNilString(lspdCJBuilder.lastname), "~r~Nom : ~s~"..notNilString(lspdCJBuilder.lastname), { RightLabel = "→" }, true, function(_,_,s)
					if s then
						lspdCJBuilder.lastname = KeyboardInput("Nom", "", 10)
					end
				end)
		
				RageUI.ButtonWithStyle("Motif : ~b~"..notNilString(lspdCJBuilder.reason), "~r~Motif : ~s~"..notNilString(lspdCJBuilder.reason), { RightLabel = "→" }, true, function(_,_,s)
					if s then
						lspdCJBuilder.reason = KeyboardInput("Raison", "", 100)
					end
				end)
		
				RageUI.ButtonWithStyle("~g~Ajouter", nil, { RightLabel = "→→" }, lspdCJBuilder.firstname ~= nil and lspdCJBuilder.lastname ~= nil and lspdCJBuilder.reason ~= nil, function(_,_,s)
					if s then
						RageUI.GoBack()
						TriggerServerEvent("corp:cjAdd", lspdCJBuilder)
						RageUI.Popup({message = "Civil ajouter à la base de données..."})
					end
				end)

			end, function()
			end)
		
			RageUI.IsVisible(cj_infos, true, true, true, function()
				RageUI.Separator("↓ ~r~Informations ~s~↓")
				RageUI.ButtonWithStyle("~g~Dépositaire: ~s~"..lspdCJData[lspdCJindex].author, nil, {}, true, function()end)
				RageUI.ButtonWithStyle("~g~Le: ~s~"..lspdCJData[lspdCJindex].date, nil, {}, true, function()end)
				RageUI.ButtonWithStyle("~o~Prénom/Nom: ~s~"..lspdCJData[lspdCJindex].firstname.." "..lspdCJData[lspdCJindex].lastname, nil, {}, true, function()end)
				RageUI.ButtonWithStyle("~o~Motif(s): ~s~"..lspdCJData[lspdCJindex].reason, nil, {}, true, function()end)


					RageUI.Separator("↓ ~r~Actions ~s~↓")

					RageUI.ButtonWithStyle('Ajouter un motif au casier ', "Soon In VIP > patreon.com/five_dev", {RightBadge = RageUI.BadgeStyle.Lock }, false, function(Hovered, Active, Selected)
						if (Selected) then
							end 
					end)

					RageUI.ButtonWithStyle('Suppimer un motif du casier ', "Soon In VIP > patreon.com/five_dev", {RightBadge = RageUI.BadgeStyle.Lock }, false, function(Hovered, Active, Selected)
						if (Selected) then
							end 
					end)

					RageUI.ButtonWithStyle("~r~Supprimer le casier", nil, {RightLabel = "→→"}, true, function(_,_,s)
						if s then
							RageUI.GoBack()
							TriggerServerEvent("corp:cjDel", lspdCJindex)
							RageUI.Popup({message = "Civil retirer de la base de données..."})
						end
					end)

		
				end, function()
				end)

			  if not RageUI.Visible(CdePopop) and not RageUI.Visible(cj_infos) and not RageUI.Visible(cj) and not RageUI.Visible(cj_add) then
			  CdePopop = RMenu:DeleteType("Casier Judiciaire", true)
		  end
	  end
  end   
  
  Citizen.CreateThread(function()
	  while true do
		  local Timer = 800
		  local plyCoords3 = GetEntityCoords(GetPlayerPed(-1), false)
		  local dist3 = Vdist(plyCoords3.x, plyCoords3.y, plyCoords3.z, Config.pos.casierjudiciaire.position.x, Config.pos.casierjudiciaire.position.y, Config.pos.casierjudiciaire.position.z)

		  if dist3 <= 7.0 then
			  Timer = 0
			  DrawMarker(20, Config.pos.casierjudiciaire.position.x, Config.pos.casierjudiciaire.position.y, Config.pos.casierjudiciaire.position.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 255, 255, 0, 1, 2, 0, nil, nil, 0)
		end
			  if dist3 <= 2.0 then
				  Timer = 0   
					RageUI.Text({ message = "Appuyez sur ~b~[E]~s~ pour accéder aux casiers judiciaire", time_display = 1 })
					if IsControlJustPressed(1,51) then         
					CasierPolice()
					  end   
				  end
		  Citizen.Wait(Timer)
	  end
end)


Citizen.CreateThread(function()
	local comicomap = AddBlipForCoord(Config.pos.blip.position.x, Config.pos.blip.position.y, Config.pos.blip.position.z)
	SetBlipSprite(comicomap, 60)
	SetBlipColour(comicomap, 29)
	SetBlipAsShortRange(comicomap, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString("L.S.P.D")
	EndTextCommandSetBlipName(comicomap)
end)