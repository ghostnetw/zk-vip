-- VIP Shop Server-side

-- Make sure Config exists
if not Config then
    Config = {}
    Config.CoinsItem = "vip_coin"
    Config.Items = {
        { name = "rmodc63amg", label = "Mercedes C63 AMG", price = 50000 },
        { name = "sultanrs", label = "Karin-Sultan", price = 32000 },
        { name = "weapon_pistol", label = "Pistola", price = 800 },
        { name = "black_money", label = "Dinero Negro", price = 1000 }
    }
    print("[ZK-VIP] SERVER: Config not loaded, using hardcoded values")
else
    print("[ZK-VIP] SERVER: Config loaded successfully!")
end

-- Item rewards handlers
local itemRewards = {
    -- Vehicle reward handler
    ["sultanrs"] = function(source)
        TriggerClientEvent("zkvip:spawnVehicle", source, "sultanrs", false) -- Spawn Sultan
        print("[ZK-VIP] Spawning Sultan for player " .. GetPlayerName(source))
    end,
    ["veh_zentorno"] = function(source)
        TriggerClientEvent("zkvip:spawnVehicle", source, "zentorno", false)
    end,
    ["veh_t20"] = function(source)
        TriggerClientEvent("zkvip:spawnVehicle", source, "t20", false)
    end,
    ["veh_insurgent"] = function(source)
        TriggerClientEvent("zkvip:spawnVehicle", source, "insurgent2", true)
    end,
    -- Generic vehicle handler (fallback for any vehicle)
    ["vehicle"] = function(source, modelName)
        -- Extract model name from item name if not provided
        if not modelName and source.name and source.name:sub(1, 4) == "veh_" then
            modelName = source.name:sub(5)
        end
        
        -- If we still don't have a model name, use a default
        if not modelName then
            modelName = "adder" -- Default fancy car
        end
        
        TriggerClientEvent("zkvip:spawnVehicle", source, modelName, false)
        print("[ZK-VIP] Spawning vehicle: " .. modelName .. " for player " .. GetPlayerName(source))
    end,
    
    -- Weapon reward handler
    ["weapon_pistol"] = function(source)
        exports.ox_inventory:AddItem(source, "WEAPON_PISTOL", 1, {ammo = 100})
    end,
    ["weapon_smg"] = function(source)
        exports.ox_inventory:AddItem(source, "WEAPON_SMG", 1, {ammo = 200})
    end,
    ["weapon_carbinerifle"] = function(source)
        exports.ox_inventory:AddItem(source, "WEAPON_CARBINERIFLE", 1, {ammo = 200})
    end,
    
    -- Money reward handler
    ["black_money"] = function(source, amount)
        exports.ox_inventory:AddItem(source, "black_money", amount or 10000)
    end,
    
    -- Special items
    ["vip_crate"] = function(source)
        exports.ox_inventory:AddItem(source, "vip_crate", 1)
    end,
    ["parachute"] = function(source)
        exports.ox_inventory:AddItem(source, "parachute", 1)
    end
}

-- Purchase event handler
RegisterServerEvent("zkvip:buyItem")
AddEventHandler("zkvip:buyItem", function(itemName)
    local src = source
    print("[ZK-VIP] Purchase request received for item: " .. itemName)
    
    -- Safety check for Config
    if not Config or not Config.Items or not Config.CoinsItem then
        print("[ZK-VIP] ERROR: Config is missing required properties")
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error de Sistema',
            description = 'Error de configuración',
            type = 'error'
        })
        return
    end
    
    -- Find item in config
    local itemData = nil
    for _, item in ipairs(Config.Items) do
        if item.name == itemName then
            itemData = item
            break
        end
    end
    
    if not itemData then
        print("[ZK-VIP] Item not found in config: " .. itemName)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Item no encontrado',
            type = 'error'
        })
        return
    end
    
    -- Debug print coin item name
    print("[ZK-VIP] Checking for coin item: " .. Config.CoinsItem)
    
    -- Debug print coin item name
    print("[ZK-VIP] Checking coins for player " .. GetPlayerName(src) .. ", looking for " .. Config.CoinsItem)
    
    -- Check if player has enough coins
    local hasEnoughCoins = false
    local coinCount = 0
    
    -- Method 1: Try using GetItemCount
    local success, result = pcall(function()
        if exports.ox_inventory.GetItemCount then
            return exports.ox_inventory:GetItemCount(src, Config.CoinsItem)
        end
        return nil
    end)
    
    if success and result and type(result) == "number" then
        coinCount = result
        hasEnoughCoins = coinCount >= itemData.price
        print("[ZK-VIP] Player has " .. coinCount .. " coins using GetItemCount, needs " .. itemData.price)
    else
        -- Method 2: Try using GetItem
        success, result = pcall(function()
            return exports.ox_inventory:GetItem(src, Config.CoinsItem, nil, true)
        end)
        
        if success and result and type(result) == "number" then
            coinCount = result
            hasEnoughCoins = coinCount >= itemData.price
            print("[ZK-VIP] Player has " .. coinCount .. " coins using GetItem, needs " .. itemData.price)
        else
            -- Method 3: Try getting the full inventory and search
            local inventory = nil
            success, inventory = pcall(function()
                return exports.ox_inventory:GetInventory(src)
            end)
            
            if success and inventory and inventory.items then
                for _, item in pairs(inventory.items) do
                    if item and item.name == Config.CoinsItem then
                        coinCount = item.count
                        hasEnoughCoins = coinCount >= itemData.price
                        print("[ZK-VIP] Player has " .. coinCount .. " coins from inventory, needs " .. itemData.price)
                        break
                    end
                end
            end
        end
    end
    
    -- Final check - if we still have no coins but the player should have, force a few for testing
    if coinCount == 0 then
        -- Uncomment for testing:
        -- coinCount = 9999
        -- hasEnoughCoins = true
        -- print("[ZK-VIP] Forcing coins for testing: " .. coinCount)
        
        print("[ZK-VIP] No vip_coins found for player " .. GetPlayerName(src))
    end
    
    if not hasEnoughCoins then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Monedas insuficientes',
            description = 'Necesitas ' .. itemData.price .. ' monedas VIP',
            type = 'error'
        })
        return
    end
    
    -- Try to remove coins
    local removed = false
    
    success, result = pcall(function()
        return exports.ox_inventory:RemoveItem(src, Config.CoinsItem, itemData.price)
    end)
    
    if success then
        removed = result
    else
        print("[ZK-VIP] Error removing coins: " .. tostring(result))
    end
    
    if not removed then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'No se pudieron remover las monedas',
            type = 'error'
        })
        return
    end
    
    print("[ZK-VIP] Coins removed successfully, executing reward")
    
    -- Execute reward
    local reward = itemRewards[itemData.name]
    if reward then
        local rewardSuccess = true
        
        if type(reward) == "function" then
            success, result = pcall(reward, src)
            rewardSuccess = success
            
            if not success then
                print("[ZK-VIP] Error executing reward: " .. tostring(result))
                rewardSuccess = false
            end
        else
            print("[ZK-VIP] Reward not a function: " .. itemData.name)
            rewardSuccess = false
        end
        
        if rewardSuccess then
            -- Notify player of success
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Compra exitosa',
                description = 'Has comprado ' .. itemData.label,
                type = 'success'
            })
            
            print("[ZK-VIP] " .. GetPlayerName(src) .. " ha comprado " .. itemData.label .. " por " .. itemData.price .. " monedas")
        else
            -- Reward failed, return coins
            exports.ox_inventory:AddItem(src, Config.CoinsItem, itemData.price)
            
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Error',
                description = 'Error al entregar el item, monedas devueltas',
                type = 'error'
            })
        end
    else
        -- Reward function not found, return coins
        exports.ox_inventory:AddItem(src, Config.CoinsItem, itemData.price)
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Este item no está disponible actualmente',
            type = 'error'
        })
        
        print("[ZK-VIP] No reward function found for: " .. itemData.name)
    end
end)