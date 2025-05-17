-- VIP Shop Configuration and Logic

-- Make sure Config exists
if not Config then
    Config = {}
    Config.CoinsItem = "vip_coin"
    Config.Items = {
        { name = "adder", label = "adder", price = 50000 },
        { name = "sultanrs", label = "sultanrs", price = 32000 },
        { name = "weapon_pistol", label = "Pistola", price = 800 },
        { name = "black_money", label = "Dinero Negro", price = 1000 },
        { name = "neo", label = "Vysser Neo", price = 50000 }
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
    { name = "kuruma", label = "Kuruma Blindado", price = 3200 },
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
        
        -- Get player coins
        local coins = getPlayerCoins()
        print("[ZK-VIP] Player has " .. coins .. " coins")
        
        -- Get categories and items
        local categories = getCategories()
        print("[ZK-VIP] Found " .. #categories .. " categories")
        
        -- Send everything to UI in a single message
        SendNUIMessage({
            type = "openVipShop",
            coins = coins,
            categories = categories
        })
        
        -- Open menu
        SetNuiFocus(true, true)
        isOpen = true
    end
end)

-- Function to get player coins
function getPlayerCoins()
    local coins = 0
    if exports.ox_inventory then
        coins = exports.ox_inventory:GetItemCount(Config.CoinsItem)
    end
    return coins or 0
end

-- Add debug function to check inventory
RegisterCommand("checkvipcoins", function(source, args, rawCommand)
    local coins = getPlayerCoins()
    print("[ZK-VIP] Debug: Player has " .. coins .. " VIP coins")
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = false,
        args = {"VIP Shop", "You have " .. coins .. " VIP coins"}
    })
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
    print("[ZK-VIP] NUI requested purchase of item: " .. tostring(data.item))
    if data.item then
        TriggerEvent("zkvip:buyItem", data.item)
    end
    cb({})
end)

RegisterNetEvent("zkvip:buyItem")
AddEventHandler("zkvip:buyItem", function(itemName)
    print("[ZK-VIP] Attempting to purchase: " .. itemName)
    
    -- Get current coins before purchase attempt
    local currentCoins = getPlayerCoins()
    print("[ZK-VIP] Current coins before purchase: " .. currentCoins)
    
    -- Find item price
    local itemData = nil
    for _, item in ipairs(Config.Items) do
        if item.name == itemName then
            itemData = item
            break
        end
    end
    
    if itemData then
        print("[ZK-VIP] Item price: " .. itemData.price .. " coins")
    else
        print("[ZK-VIP] ERROR: Item not found in config: " .. itemName)
    end
    
    TriggerServerEvent("zkvip:buyItem", itemName)
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
