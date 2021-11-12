Config                            = {}
Config.DrawDistance               = 25.0
Config.Type = 21
Config.Locale = 'fr'

Config.WebHookPlainte = "https://discord.com/api/webhooks/907078711138975784/KgNEM20Uv0C1MFKdsy6i-mlVAEEJ9AKUMaxFdFtaQEkng7fLZFJCFdtopnUUDNU8BJZw" 
Config.Logs_Fouille = "https://discord.com/api/webhooks/855123504865476689/q0quAwu253iuxjDsioMrbFtcg7SdIWnEGSQdxRjl7Sb8DusRc7FBgPlPnWv8CHZgwncd"
Config.Logs_Objets_depot = "https://discord.com/api/webhooks/907083676851011634/dxb3M_p0vDaHa_eDgZBLEpDe9cQQHt0a2am-hChn7zknA-VhPEy0J5nmTcp-mJ81oHGq"
Config.Logs_Objets_retrait = "https://discord.com/api/webhooks/907083018018107453/Q6JfGd27FlTUPQXm5v4uWQgbjm1s0GHDmAauwe-uUofG2mlvvcYLKHEuSPkS7BZhiooq"
Config.Logs_Armes_depot = "https://discord.com/api/webhooks/907092905976528907/bXW2ztnOJeoBpDdjK7KU1vFJ-YwBAaujT_NUuTKGqyQtmkyaeNzm-Erag7A_-P-4Pvoa"
Config.Logs_Armes_retrait = "https://discord.com/api/webhooks/907092848355209266/tTg0qzRPE57q8uehWlnLQbqiWMOGAoEzuIA7QI9U-Xahg5Q_cb8yOdR8ZQg6vqoV97KD"
Config.Logs_PriseFin_Service = "https://discord.com/api/webhooks/907087332291780658/eEwxP8PIyh--BUYnKbKm5dvvHPpOkYxiZmS-UQzvnIdOfurEDj2it-Y1tI6jnAWV5vB1"
Config.Logs_Amende = "https://discord.com/api/webhooks/907706685362163814/72VtMIzZ-E19xM3I4ILcseNzWGc-176AgFzEn5NBa-Umj60HkEB_lSSUHTAlq9p3uxEq"

------------------
Config.Grade_Pour_Radar = 2  -- Accès Menu radar 
Config.Grade_Pour_Objets = 2  -- Accès Menu objets 
Config.Grade_Pour_Chien = 2 -- Accès Menu chien 
Config.Grade_Pour_Camera = 2 -- Accès Menu caméra 
Config.Grade_Pour_AvisRecherche = 1 -- Accès Menu adr 
--------------------
Config.Grade_Pour_PPA = 7 -- retirer/donner ppa
Config.Grade_Pour_Permis = 7 -- retirer/donner permis
------------------

Config.pos = {
    blip = {
        position = {x = 439.14, y = -982.3, z = 30.69}
    },
	garagevoiture = {
        position = {x = 459.90, y = -986.70, z = 24.69, h = 96.0}
    },
	garageheli = {
        position = {x = 463.92, y = -982.43, z = 42.69, h = 87.26}
    },
    garagebateau = {
        position = {x = -778.95, y = -1478.06, z = 1.93, h = 199.23}
    },
	armurerie = {
        position = {x = 480.33, y = -996.59, z = 29.68, h = 92.89}
    },
	vestiaire = {
        position = {x = 462.12, y = -996.43, z = 30.69}
    },
    coffre = {
        position = {x = 449.91, y = -996.77, z = 30.68}
    },
    boss = {
        position = {x = 460.72, y = -985.55, z = 30.72}
    },
    plainterdv = {
        position = {x = 442.73, y = -981.75, z = 29.68, h = 96.15}
    },
    casierjudiciaire = {
        position = {x = 453.80, y = -988.09, z = 30.68}
    }
}

Config.spawn = {
	spawnvoiture = {position = {x = 452.82, y = -987.42, z = 25.69, h = 1.65}},
	spawnheli = {position = {x = 448.69, y = -981.65, z = 43.69, h = 87.916}},
    spawnbato = {position = {x = -797.997, y = -1485.792, z = -0.474, h = 110.404}}
}

Config.armurerie = {
	{nom = "Pistolet", arme = "weapon_pistol", minimum_grade = 1},
	{nom = "Fusil à pompe", arme = "weapon_pumpshotgun_mk2", minimum_grade = 3},
	{nom = "M4", arme = "weapon_carbinerifle", minimum_grade = 7}
}

police = {
    clothes = {
        specials = {
            [0] = {
                label = "Reprendre sa tenue civil",
                minimum_grade = 0, -- grade minmum pour prendre la tenue
                variations = {male = {}, female = {}},
                onEquip = function()
                    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                        TriggerEvent('skinchanger:loadSkin', skin)
                    end)
                    SetPedArmour(PlayerPedId(), 0)
                end
            },
            [1] = {
                label = "Tenue Police",
                minimum_grade = 0, -- grade minmum pour prendre la tenue
                variations = {
                    male = {
                        ['bags_1'] = 0, ['bags_2'] = 0,
                        ['tshirt_1'] = 39, ['tshirt_2'] = 0,
                        ['torso_1'] = 55, ['torso_2'] = 0,
                        ['arms'] = 30,
                        ['pants_1'] = 46, ['pants_2'] = 0,
                        ['shoes_1'] =25, ['shoes_2'] = 0,
                        ['mask_1'] = 0, ['mask_2'] = 0,
                        ['bproof_1'] = 0,
                        ['chain_1'] = 0,
                        ['helmet_1'] = -1, ['helmet_2'] = 0,
                    },
                    female = {
                        ['bags_1'] = 0, ['bags_2'] = 0,
                        ['tshirt_1'] = 15,['tshirt_2'] = 2,
                        ['torso_1'] = 65, ['torso_2'] = 2,
                        ['arms'] = 36, ['arms_2'] = 0,
                        ['pants_1'] = 38, ['pants_2'] = 2,
                        ['shoes_1'] = 12, ['shoes_2'] = 6,
                        ['mask_1'] = 0, ['mask_2'] = 0,
                        ['bproof_1'] = 0,
                        ['chain_1'] = 0,
                        ['helmet_1'] = -1, ['helmet_2'] = 0,
                    }
                },
                onEquip = function()  
                end
            },
            [2] = {
                label = "Tenue Officier",
                minimum_grade = 1, -- grade minmum pour prendre la tenue
                variations = {
                    male = {
                        ['bags_1'] = 0, ['bags_2'] = 0,
                        ['tshirt_1'] = 39, ['tshirt_2'] = 0,
                        ['torso_1'] = 55, ['torso_2'] = 0,
                        ['arms'] = 30,
                        ['pants_1'] = 46, ['pants_2'] = 0,
                        ['shoes_1'] =25, ['shoes_2'] = 0,
                        ['mask_1'] = 0, ['mask_2'] = 0,
                        ['bproof_1'] = 0,
                        ['chain_1'] = 0,
                        ['helmet_1'] = -1, ['helmet_2'] = 0,
                    },
                    female = {
                        ['bags_1'] = 0, ['bags_2'] = 0,
                        ['tshirt_1'] = 15,['tshirt_2'] = 2,
                        ['torso_1'] = 65, ['torso_2'] = 2,
                        ['arms'] = 36, ['arms_2'] = 0,
                        ['pants_1'] = 38, ['pants_2'] = 2,
                        ['shoes_1'] = 12, ['shoes_2'] = 6,
                        ['mask_1'] = 0, ['mask_2'] = 0,
                        ['bproof_1'] = 0,
                        ['chain_1'] = 0,
                        ['helmet_1'] = -1, ['helmet_2'] = 0,
                    }
                },
                onEquip = function()  
                end
            },
            [3] = {
                label = "Tenue Sergent",
                minimum_grade = 2, -- grade minmum pour prendre la tenue
                variations = {
                    male = {
                        ['bags_1'] = 0, ['bags_2'] = 0,
                        ['tshirt_1'] = 39, ['tshirt_2'] = 0,
                        ['torso_1'] = 55, ['torso_2'] = 0,
                        ['arms'] = 30,
                        ['pants_1'] = 46, ['pants_2'] = 0,
                        ['shoes_1'] =25, ['shoes_2'] = 0,
                        ['mask_1'] = 0, ['mask_2'] = 0,
                        ['bproof_1'] = 0,
                        ['chain_1'] = 0,
                        ['helmet_1'] = -1, ['helmet_2'] = 0,
                    },
                    female = {
                        ['bags_1'] = 0, ['bags_2'] = 0,
                        ['tshirt_1'] = 15,['tshirt_2'] = 2,
                        ['torso_1'] = 65, ['torso_2'] = 2,
                        ['arms'] = 36, ['arms_2'] = 0,
                        ['pants_1'] = 38, ['pants_2'] = 2,
                        ['shoes_1'] = 12, ['shoes_2'] = 6,
                        ['mask_1'] = 0, ['mask_2'] = 0,
                        ['bproof_1'] = 0,
                        ['chain_1'] = 0,
                        ['helmet_1'] = -1, ['helmet_2'] = 0,
                    }
                },
                onEquip = function()  
                end
            },
            [4] = {
                label = "Tenue Lieutenant",
                minimum_grade = 3, -- grade minmum pour prendre la tenue
                variations = {
                    male = {
                        ['bags_1'] = 0, ['bags_2'] = 0,
                        ['tshirt_1'] = 39, ['tshirt_2'] = 0,
                        ['torso_1'] = 55, ['torso_2'] = 0,
                        ['arms'] = 30,
                        ['pants_1'] = 46, ['pants_2'] = 0,
                        ['shoes_1'] =25, ['shoes_2'] = 0,
                        ['mask_1'] = 0, ['mask_2'] = 0,
                        ['bproof_1'] = 0,
                        ['chain_1'] = 0,
                        ['helmet_1'] = -1, ['helmet_2'] = 0,
                    },
                    female = {
                        ['bags_1'] = 0, ['bags_2'] = 0,
                        ['tshirt_1'] = 15,['tshirt_2'] = 2,
                        ['torso_1'] = 65, ['torso_2'] = 2,
                        ['arms'] = 36, ['arms_2'] = 0,
                        ['pants_1'] = 38, ['pants_2'] = 2,
                        ['shoes_1'] = 12, ['shoes_2'] = 6,
                        ['mask_1'] = 0, ['mask_2'] = 0,
                        ['bproof_1'] = 0,
                        ['chain_1'] = 0,
                        ['helmet_1'] = -1, ['helmet_2'] = 0,
                    }
                },
                onEquip = function()  
                end
            },
            [5] = {
                label = "Tenue Directeur",
                minimum_grade = 4, -- grade minmum pour prendre la tenue
                variations = {
                    male = {
                        ['bags_1'] = 0, ['bags_2'] = 0,
                        ['tshirt_1'] = 39, ['tshirt_2'] = 0,
                        ['torso_1'] = 55, ['torso_2'] = 0,
                        ['arms'] = 30,
                        ['pants_1'] = 46, ['pants_2'] = 0,
                        ['shoes_1'] =25, ['shoes_2'] = 0,
                        ['mask_1'] = 0, ['mask_2'] = 0,
                        ['bproof_1'] = 0,
                        ['chain_1'] = 0,
                        ['helmet_1'] = -1, ['helmet_2'] = 0,
                    },
                    female = {
                        ['bags_1'] = 0, ['bags_2'] = 0,
                        ['tshirt_1'] = 15,['tshirt_2'] = 2,
                        ['torso_1'] = 65, ['torso_2'] = 2,
                        ['arms'] = 36, ['arms_2'] = 0,
                        ['pants_1'] = 38, ['pants_2'] = 2,
                        ['shoes_1'] = 12, ['shoes_2'] = 6,
                        ['mask_1'] = 0, ['mask_2'] = 0,
                        ['bproof_1'] = 0,
                        ['chain_1'] = 0,
                        ['helmet_1'] = -1, ['helmet_2'] = 0,
                    }
                },
                onEquip = function()  
                end
            }
        },
        grades = {
            [0] = {
                label = "Mettre",
                minimum_grade = 0, -- grade minmum pour prendre la tenue
                variations = {
                male = {
                    ['bproof_1'] = 1,
                },
                female = {
                    ['bproof_1'] = 1,
                }
            },
            onEquip = function()
            end
        },
		[1] = {
			label = "Enlever",
			minimum_grade = 0, -- grade minmum pour prendre la tenue
			variations = {
			male = {
				['bproof_1'] = 0,
			},
			female = {
				['bproof_1'] = 0,
			}
		},
		onEquip = function()
		end
	},
    }
},
	vehicles = {                                                         -- category = Separator en rageui 
        car = {                                                           -- Label = nom ig qui apparaitra sur le bouton 
            {category = "↓ ~b~Véhicules ~s~↓"},                           -- Model = nom de spawn du véhicule
            {model = "police6", label = "4x4 K-9 Police departement", minimum_grade = 0, stock = 5}, --minimum_grade = grade minmum pour prendre
			{model = "police2", label = "Dodge Charger", minimum_grade = 1, stock = 5},
            {model = "police3", label = "4x4 Cruiser", minimum_grade = 3, stock = 5},
            {model = "ghispo2", label = "Maserati - VIR", minimum_grade = 4, stock = 5},
            {model = "pol718", label = "Porsche - VIR", minimum_grade = 4, stock = 5},
            {category = "↓ ~b~Rangement ~s~↓"},
        },
    }
}
