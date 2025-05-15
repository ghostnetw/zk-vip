-- VIP Shop Configuration and Logic

-- Make sure Config exists
if not Config then
    Config = {}
    Config.CoinsItem = "vip_coin"
    Config.Items = {
        { name = "rmodc63amg", label = "Amg-c63", price = 50000 },
        { name = "sultanrs", label = "Sultan RS", price = 32000 },
        { name = "weapon_pistol", label = "Pistola", price = 800 },
        { name = "black_money", label = "Dinero Negro", price = 1000 }
    }
    print("[ZK-VIP] Config not loaded, using hardcoded values")
else
    print("[ZK-VIP] Config loaded successfully!")
end

local isOpen = false

-- Check coins function - using ox_inventory to get VIP coins
local function getPlayerCoins()
    -- Make sure Config is loaded
    if not Config or not Config.CoinsItem then
        print("[ZK-VIP] Error: Config or Config.CoinsItem is nil")
        return 0 -- Default value if config is not loaded
    end
    
    print("[ZK-VIP] Checking for coin item: " .. Config.CoinsItem)
    
    -- Method 1: Try using GetItemCount
    local coins = 0
    local success, result = pcall(function()
        if exports.ox_inventory.GetItemCount then
            return exports.ox_inventory:GetItemCount(Config.CoinsItem)
        end
        return nil
    end)
    
    if success and result and type(result) == "number" then
        coins = result
        print("[ZK-VIP] Found " .. coins .. " coins using GetItemCount")
        return coins
    end
    
    -- Method 2: Try using GetPlayerItems and searching
    success, result = pcall(function()
        return exports.ox_inventory:GetPlayerItems()
    end)
    
    if success and result then
        -- Find coins in inventory items
        for _, item in ipairs(result) do
            if item.name == Config.CoinsItem then
                coins = item.count
                print("[ZK-VIP] Found " .. coins .. " coins in player inventory")
                return coins
            end
        end
    end
    
    -- Method 3: Try using direct inventory access
    local inventory = nil
    success, inventory = pcall(function()
        return exports.ox_inventory:GetInventory()
    end)
    
    if success and inventory and inventory.items then
        for _, item in pairs(inventory.items) do
            if item and item.name == Config.CoinsItem then
                coins = item.count
                print("[ZK-VIP] Found " .. coins .. " coins in inventory items")
                return coins
            end
        end
    end
    
    print("[ZK-VIP] Could not find any vip_coin, returning 0")
    return coins
end

-- Define default test items if config isn't loaded
local defaultItems = {
    { name = "veh_kuruma", label = "Kuruma Blindado", price = 3200 },
    { name = "weapon_pistol", label = "Pistola", price = 800 },
    { name = "black_money", label = "Dinero Negro", price = 1000 }
}

-- Load items from config
local function getCategories()
    local categories = {}
    local vehicleItems = {}
    local weaponItems = {}
    local moneyItems = {}
    local specialItems = {}
    
    -- Make sure Config is loaded
    if not Config or not Config.Items then
        print("[ZK-VIP] Error: Config or Config.Items is nil, using default items")
        -- Return a single category with default items
        return {
            { name = "default", label = "Artículos VIP", items = defaultItems }
        }
    end
    
    -- Categorize items
    for _, item in ipairs(Config.Items) do
        if string.match(item.name, "veh_") then
            table.insert(vehicleItems, item)
        elseif string.match(item.name, "weapon_") then
            table.insert(weaponItems, item)
        elseif item.name == "black_money" then
            table.insert(moneyItems, item)
        else
            table.insert(specialItems, item)
        end
    end
    
    if #vehicleItems > 0 then
        table.insert(categories, { name = "vehicles", label = "Vehículos", items = vehicleItems })
    end
    
    if #weaponItems > 0 then
        table.insert(categories, { name = "weapons", label = "Armas", items = weaponItems })
    end
    
    if #moneyItems > 0 then
        table.insert(categories, { name = "money", label = "Dinero", items = moneyItems })
    end
    
    if #specialItems > 0 then
        table.insert(categories, { name = "special", label = "Especial", items = specialItems })
    end
    
    return categories
end

-- Register command to open VIP menu
RegisterCommand("openvip", function(source, args, rawCommand)
    -- Only open if not already open
    if not isOpen then
        print("[ZK-VIP] Opening menu...")
        
        -- Set menu as open and focus NUI
        isOpen = true
        SetNuiFocus(true, true)
        
        -- Get VIP coins and categories safely
        local coins = 4800
        local categories = {}
        
        -- Try to get actual values, but use defaults if fails
        local success, result = pcall(function()
            coins = getPlayerCoins()
            categories = getCategories()
            return true
        end)
        
        if not success then
            print("[ZK-VIP] Error while opening menu: ", result)
            -- At minimum, create a simple category with default items
            categories = {
                { 
                    name = "default", 
                    label = "Artículos VIP", 
                    items = defaultItems 
                }
            }
        end
        
        -- Send NUI message to open the shop interface
        SendNUIMessage({
            type = "openVipShop",
            coins = coins,
            categories = categories
        })
        
        print("[ZK-VIP] Menu opened with " .. #categories .. " categories")
    else
        print("[ZK-VIP] Menu already open")
    end
end, false)

RegisterNUICallback("close", function(data, cb)
    if isOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({ type = "closeVipShop" })
        isOpen = false
        cb({})
    end
end)

RegisterNUICallback("selectCategory", function(data, cb)
    SendNUIMessage({
        type = "updateCategory",
        category = data.category
    })
    cb({})
end)

RegisterNUICallback("buyItem", function(data, cb)
    if isOpen then
        TriggerServerEvent("zkvip:buyItem", data.item)
        cb({})
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isOpen then
            DisableControlAction(0, 200, true) -- ESC key
            DisableControlAction(0, 75, true) -- F key
            DisableControlAction(0, 25, true) -- Right mouse button
        end
    end
end)

RegisterNetEvent("zkvip:closeShop")
AddEventHandler("zkvip:closeShop", function()
    if isOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({ type = "closeVipShop" })
        isOpen = false
    end
end)

RegisterNetEvent("zkvip:spawnVehicle")
AddEventHandler("zkvip:spawnVehicle", function(vehicleModel, armored)
    -- First close the shop UI
    if isOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({ type = "closeVipShop" })
        isOpen = false
    end
    
    -- Get player position
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Request the vehicle model
    local modelHash = GetHashKey(vehicleModel)
    RequestModel(modelHash)
    
    -- Wait for model to load
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 30 do
        timeout = timeout + 1
        Citizen.Wait(100)
    end
    
    if not HasModelLoaded(modelHash) then
        TriggerEvent('ox_lib:notify', {
            title = 'Error',
            description = 'No se pudo cargar el modelo del vehículo',
            type = 'error'
        })
        return
    end
    
    -- Find a safe spawn position in front of the player
    local spawnCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
    local heading = GetEntityHeading(playerPed)
    
    -- Spawn the vehicle
    local vehicle = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, false)
    
    -- Set the player as the driver
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
    
    -- Apply upgrades if it's an armored vehicle
    if armored then
        SetVehicleModKit(vehicle, 0)
        SetVehicleMod(vehicle, 16, 4, false) -- Armor upgrade
        SetVehicleMod(vehicle, 11, 3, false) -- Engine upgrade
        SetVehicleMod(vehicle, 12, 2, false) -- Brakes upgrade
        SetVehicleMod(vehicle, 13, 2, false) -- Transmission upgrade
        SetVehicleWindowTint(vehicle, 1) -- Light smoke window tint
    end
    
    -- Set as player owned
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    
    -- Set fuel level using ox_fuel if available
    local success, error = pcall(function()
        if exports['ox_fuel'] then
            exports['ox_fuel']:SetFuel(vehicle, 100.0)
            print("[ZK-VIP] Applied fuel to spawned vehicle")
        end
    end)
    
    if not success then
        print("[ZK-VIP] No ox_fuel found or error: " .. tostring(error))
    end
    
    -- Give vehicle keys using qbx_vehiclekeys
    local plate = GetVehicleNumberPlateText(vehicle)
    if plate then
        -- Clean plate string
        plate = string.gsub(plate, " ", "")
        
        -- Method 1 - Try direct export
        success, error = pcall(function()
            if exports['qbx_vehiclekeys'] then
                exports['qbx_vehiclekeys']:GiveKeys(plate)
                print("[ZK-VIP] Gave keys for plate: " .. plate .. " via export")
                return true
            end
            return false
        end)
        
        -- Method 2 - Try event if export failed
        if not success or error == false then
            TriggerServerEvent('qbx_vehiclekeys:server:AcquireVehicleKeys', plate)
            print("[ZK-VIP] Gave keys for plate: " .. plate .. " via server event")
        end
    end
    
    -- Notification
    TriggerEvent('ox_lib:notify', {
        title = '¡Vehículo recibido!',
        description = 'Tu nuevo vehículo VIP con llaves ha sido entregado',
        type = 'success'
    })
    
    -- Cleanup
    SetModelAsNoLongerNeeded(modelHash)
end)
