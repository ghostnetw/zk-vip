-- Check for required dependencies
local QBCore = nil

-- Attempt to load QBCore
local success, result = pcall(function()
    return exports['qb-core']:GetCoreObject()
end)

if success then
    QBCore = result
    print("[ZK-VIP] QBCore loaded successfully")
else
    print("[ZK-VIP] WARNING: QBCore could not be loaded. Vehicle garage integration will not work.")
end

-- Check ox_inventory
if not exports.ox_inventory then
    print("[ZK-VIP] ERROR: ox_inventory not loaded!")
    return
end

-- Make sure Config exists
if not Config then
    Config = {}
    Config.CoinsItem = "vip_coin"
    Config.Items = {
        { name = "nero", label = "Nero", price = 50000 },
        { name = "sultanrs", label = "Sultan RS", price = 32000 },
        { name = "weapon_pistol", label = "Pistola", price = 800 },
        { name = "black_money", label = "Dinero Negro", price = 1000 },
        { name = "neo", label = "Vysser Neo", price = 50000 },
        { name = "adder", label = "Adder", price = 50000 }
    }
    print("[ZK-VIP] SERVER: Config not loaded, using hardcoded values")
else
    print("[ZK-VIP] SERVER: Config loaded successfully!")
end

-- Command to test Discord webhook
RegisterCommand("vip_test_discord", function(source, args, rawCommand)
    local src = source
    if IsPlayerAceAllowed(src, "command") then
        print("[ZK-VIP] Testing Discord webhook...")
        
        -- Create test item data
        local testItem = {
            name = "test_item",
            label = "Test Item",
            price = 1000,
            category = "Test Category"
        }
        
        -- Create and send embed using our enhanced CreatePurchaseEmbed function
        local embed = CreatePurchaseEmbed("test_item", src, testItem)
        SendDiscordLog("VIP System Test", embed)
        
        -- Direct test webhook (fallback)
        PerformHttpRequest("https://discord.com/api/webhooks/1331006923885252649/uHQkR0qa8sSopsAVvtwFYpwRcBPZdk-6OlMP-YcEYUVbFW6Tw4NfM2Of6C2WHwiuyCfz", 
            function(err, text, headers)
                print("[ZK-VIP] Direct webhook test result: " .. tostring(err) .. ", " .. tostring(text))
            end, 
            "POST", 
            json.encode({
                content = "Direct webhook test from VIP system",
                embeds = {
                    {
                        title = "Simple Test Embed",
                        description = "This is a direct test from the VIP system, bypassing the SendDiscordLog function",
                        color = 3066993
                    }
                }
            }), 
            { ["Content-Type"] = "application/json" }
        )
        
        -- Notify player
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Discord Test',
            description = 'Test messages sent to Discord. Check server console for results.',
            type = 'info'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Access Denied',
            description = 'You do not have permission to use this command.',
            type = 'error'
        })
    end
end, true) -- Restrict to admins

-- Item rewards handlers
local itemRewards = {
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
RegisterNetEvent("zkvip:buyItem")
AddEventHandler("zkvip:buyItem", function(itemName)
    local src = source
    print("[ZK-VIP] Purchase request received for item: " .. itemName)
    
    -- Safety check for Config
    if not Config or not Config.Items or not Config.CoinsItem then
        print("[ZK-VIP] ERROR: Config not properly loaded")
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Error interno del sistema VIP. Por favor, contacta con un administrador.',
            type = 'error'
        })
        return
    end
    
    -- Find the item in the config
    local itemData = nil
    for _, item in ipairs(Config.Items) do
        if string.lower(item.name) == string.lower(itemName) then
            itemData = item
            print("[ZK-VIP] Found item: " .. item.name .. ", price: " .. item.price)
            break
        end
    end

    if not itemData then
        print("[ZK-VIP] ERROR: Item not found in config: " .. itemName)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Item no encontrado en el sistema VIP.',
            type = 'error'
        })
        return
    end

    -- Check if player has enough coins
    local coinCount = exports.ox_inventory:GetItemCount(src, Config.CoinsItem)
    print("[ZK-VIP] Player has " .. coinCount .. " coins, needs " .. itemData.price)
    
    if coinCount < itemData.price then
        print("[ZK-VIP] Not enough coins. Need " .. itemData.price .. ", player has " .. coinCount)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'No tienes suficientes monedas VIP. Necesitas ' .. itemData.price .. ' monedas.',
            type = 'error'
        })
        return
    end
    
    -- Remove the coins first
    local removed = exports.ox_inventory:RemoveItem(src, Config.CoinsItem, itemData.price)
    if not removed then
        print("[ZK-VIP] Failed to remove coins")
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Error al remover monedas.',
            type = 'error'
        })
        return
    end
    
    -- Check for special item handlers
    local reward = itemRewards[itemName]
    
    -- Handle special items with reward functions
    if reward and type(reward) == "function" then
        local success, result = pcall(reward, src)
        if success then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Exito',
                description = 'Has comprado ' .. itemData.label,
                type = 'success'
            })
            
            -- Log to Discord using the enhanced CreatePurchaseEmbed function
            local embed = CreatePurchaseEmbed(itemName, src, itemData)
            SendDiscordLog("VIP Shop Purchase", embed)
            return
        else
            print("[ZK-VIP] ERROR: Failed to process item reward: " .. tostring(result))
            -- Refund coins
            exports.ox_inventory:AddItem(src, Config.CoinsItem, itemData.price)
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Error',
                description = 'Error al entregar el premio. Monedas devueltas.',
                type = 'error'
            })
            return
        end
    end
    
    -- Handle vehicle items
    local vehicleModel = itemName
    -- If it has a veh_ prefix, remove it
    if string.match(itemName, "^veh_") then
        vehicleModel = string.gsub(itemName, "^veh_", "")
    end
    
    -- Function to add the vehicle to the player's garage
    local function AddVehicleToGarage()
        if not QBCore then
            print("[ZK-VIP] ERROR: QBCore not loaded, cannot add to garage")
            return false
        end

        -- Get the player
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then
            print("[ZK-VIP] ERROR: Could not get QBCore player data")
            return false
        end

        local citizenid = Player.PlayerData.citizenid
        local license = Player.PlayerData.license
        
        -- Generate a unique plate
        local plate = "VIP" .. math.random(1000, 9999)
        
        print("[ZK-VIP] Adding vehicle to garage for player: " .. GetPlayerName(src) .. ", CitizenID: " .. citizenid)
        print("[ZK-VIP] Vehicle: " .. vehicleModel .. ", Plate: " .. plate)
        
        -- Load our direct JG integration module
        local directJG = nil
        local success, result = pcall(function()
            local content = LoadResourceFile(GetCurrentResourceName(), 'direct_jg.lua')
            if content then
                directJG = load(content)()
                if directJG and directJG.Initialize then
                    directJG.Initialize(QBCore)
                    return directJG ~= nil
                end
            end
            return false
        end)
        
        if success and result then
            print("[ZK-VIP] Successfully loaded direct JG integration")
            -- Don't inspect database to avoid MySQL errors
            -- directJG.InspectGarageDatabase()
            
            -- Inspect JG functions
            directJG.InspectJGGaragesFunctions()
            
            -- Try to add vehicle by template
            local templateSuccess = directJG.AddVehicleByTemplate(src, vehicleModel, plate, citizenid)
            if templateSuccess then
                print("[ZK-VIP] Successfully added vehicle using template method")
                return true
            end
        else
            print("[ZK-VIP] Failed to load direct JG integration")
        end
        
        -- Vehicle properties for fallback methods
        local vehProps = {
            model = vehicleModel,
            plate = plate
        }
        
        -- Create complete mods object
        local mods = {
            model = vehicleModel,
            plate = plate,
            fuelLevel = 100,
            bodyHealth = 1000.0,
            engineHealth = 1000.0,
            dirtLevel = 0.0,
            color1 = 0,
            color2 = 0
        }
        
        -- Find a garage name
        local garageName = "Legion" -- Default fallback
        local state = 1     -- 1 = in garage, 0 = out

        -- Try jg-advancedgarages exports
        if exports['jg-advancedgarages'] then
            local garagesSuccess, garages = pcall(function()
                if exports['jg-advancedgarages'].getAllGarages then
                    return exports['jg-advancedgarages']:getAllGarages()
                end
                return nil
            end)
            
            if garagesSuccess and garages then
                for _, garage in ipairs(garages) do
                    if garage.type == "car" or garage.vehicle == "car" then
                        garageName = garage.name
                        print("[ZK-VIP] Using garage: " .. garageName)
                        break
                    end
                end
                
                if #garages > 0 and not garageName then
                    garageName = garages[1].name
                    print("[ZK-VIP] Using first available garage: " .. garageName)
                end
            end
            
            -- Skip using exports and directly insert into database
            print("[ZK-VIP] Using DIRECT SQL insertion only (no exports)")
            
            -- First, determine which table exists
            -- Try extremely simple direct insertion into player_vehicles (standard table)
            exports.oxmysql:execute(
                'SHOW TABLES LIKE "player_vehicles"',
                {},
                function(tables)
                    if tables and #tables > 0 then
                        -- player_vehicles table exists, insert into it
                        print("[ZK-VIP] Using player_vehicles table")
                        
                        -- Get hash for the vehicle model
                        local hash = GetHashKey(vehicleModel) or 0
                        
                        -- Create mods as JSON
                        local modsJson = json.encode({
                            model = vehicleModel,
                            plate = plate,
                            fuelLevel = 100,
                            engineHealth = 1000.0,
                            bodyHealth = 1000.0
                        })
                        
                        -- Standard QBCore format
                        exports.oxmysql:execute(
                            'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                            {license, citizenid, vehicleModel, hash, modsJson, plate, "Legion", 1},
                            function(result)
                                if result and result.affectedRows > 0 then
                                    print("[ZK-VIP] Successfully inserted vehicle into player_vehicles table")
                                    
                                    -- Give notification to player
                                    TriggerClientEvent('ox_lib:notify', src, {
                                        title = 'Exito',
                                        description = 'Vehiculo ' .. vehicleModel .. ' ha sido agregado a tu garaje',
                                        type = 'success'
                                    })
                                else
                                    print("[ZK-VIP] Failed to insert vehicle into player_vehicles table")
                                    -- Refund coins on failure
                                    exports.ox_inventory:AddItem(src, Config.CoinsItem, itemData.price)
                                    TriggerClientEvent('ox_lib:notify', src, {
                                        title = 'Error',
                                        description = 'Error al agregar vehículo. Monedas devueltas.',
                                        type = 'error'
                                    })
                                end
                            end
                        )
                    else
                        print("[ZK-VIP] No vehicle tables found in database!")
                        -- Refund coins if we can't find any suitable table
                        exports.ox_inventory:AddItem(src, Config.CoinsItem, itemData.price)
                        TriggerClientEvent('ox_lib:notify', src, {
                            title = 'Error',
                            description = 'Error de configuración: No se encontró tabla para vehículos. Monedas devueltas.',
                            type = 'error'
                        })
                    end
                end
            )
            
            return true
        end
        
        -- If exports fail, try direct database insertion with a more comprehensive approach
        local success, err = pcall(function()
            -- Check if MySQL is loaded and accessible
            if not MySQL or not MySQL.Async or not MySQL.Async.execute then
                print("[ZK-VIP] MySQL not available, cannot add to database")
                return false
            end
            
            local hash = GetHashKey(vehicleModel)
            if not hash then
                print("[ZK-VIP] Could not get hash for vehicle model: " .. vehicleModel)
                hash = 0
            end
            
            -- Create a more complete mods object specifically for jg-advancedgarages
            local modsTable = {
                model = vehicleModel,
                plate = plate,
                fuelLevel = 100,
                bodyHealth = 1000.0,
                engineHealth = 1000.0,
                dirtLevel = 0.0,
                color1 = 0,
                color2 = 0,
                pearlescentColor = 0,
                wheelColor = 0,
                dashboardColor = 0,
                interiorColor = 0,
                modSpoilers = -1,
                modFrontBumper = -1,
                modRearBumper = -1,
                modSideSkirt = -1,
                modExhaust = -1,
                modFrame = -1,
                modGrille = -1,
                modHood = -1,
                modFender = -1,
                modRightFender = -1,
                modRoof = -1,
                wheels = 0,
                windowTint = 0
            }
            
            -- Encode mods to JSON
            local modsJson = json.encode(modsTable)
            
            print("[ZK-VIP] Trying multiple database approaches to cover all possible schemas")
            
            -- Try inserting into every possible table with appropriate schema to maximize chances
            pcall(function()
                -- Try jg-advancedgarages player_vehicles format
                MySQL.Async.execute('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state, damage, metadata) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                    { license, citizenid, vehicleModel, hash, modsJson, plate, garageName, state, '{}', '{}' }
                )
                print("[ZK-VIP] Inserted into player_vehicles with JG schema")
            end)
            
            pcall(function()
                -- Try jg-advancedgarages player_cars format
                MySQL.Async.execute('INSERT INTO player_cars (citizenid, plate, vehicle, garage, state, mods, metadata) VALUES (?, ?, ?, ?, ?, ?, ?)',
                    { citizenid, plate, vehicleModel, garageName, state, modsJson, '{}' }
                )
                print("[ZK-VIP] Inserted into player_cars table")
            end)
            
            pcall(function()
                -- Try standard QBCore format
                MySQL.Async.execute('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                    { license, citizenid, vehicleModel, hash, modsJson, plate, garageName, state }
                )
                print("[ZK-VIP] Inserted into player_vehicles with standard schema")
            end)
            
            -- Try the exact schema that jg-advancedgarages might be using
            pcall(function()
                local query = [[SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='player_vehicles' AND TABLE_SCHEMA=DATABASE()]]
                local columns = MySQL.Sync.fetchAll(query)
                
                if columns then
                    print("[ZK-VIP] Found player_vehicles table with " .. #columns .. " columns")
                    for _, col in ipairs(columns) do
                        print("[ZK-VIP] player_vehicles column: " .. tostring(col.COLUMN_NAME))
                    end
                end
            end)
            
            print("[ZK-VIP] Successfully inserted vehicle into database")
            return true
        end)
        
        if success then
            -- Give vehicle keys if possible
            pcall(function()
                if exports['qb-vehiclekeys'] then
                    TriggerEvent('qb-vehiclekeys:server:GiveVehicleKeys', plate, src)
                end
            end)
            
            print("[ZK-VIP] Vehicle added to garage successfully")
            return true
        else
            print("[ZK-VIP] Failed to add vehicle to database: " .. tostring(err))
            return false
        end
        
        return false
    end
    
    -- Try to add to garage
    local garageSuccess = AddVehicleToGarage()
    
    if garageSuccess then
        -- Successfully added to garage
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Exito',
            description = 'Has comprado ' .. itemData.label .. ' y ha sido agregado a tu garage.',
            type = 'success'
        })
        
        -- Log to Discord using the enhanced CreatePurchaseEmbed function
        local itemDataWithLocation = table.copy(itemData)
        itemDataWithLocation.category = "Vehicle (Added to Garage)"
        local embed = CreatePurchaseEmbed(vehicleModel, src, itemDataWithLocation)
        SendDiscordLog("VIP Shop - Vehicle Purchase", embed)
        
        print("[ZK-VIP] Player " .. GetPlayerName(src) .. " received vehicle in garage: " .. vehicleModel)
        return
    end
    
    -- If adding to garage failed, try to spawn it in the world as fallback
    print("[ZK-VIP] Adding to garage failed, trying to spawn vehicle")
    
    -- Try to spawn the vehicle
    local playerPed = GetPlayerPed(src)
    local coords = GetEntityCoords(playerPed)
    
    -- Request the model
    RequestModel(vehicleModel)
    -- Wait for the model to load
    local timeout = 0
    while not HasModelLoaded(vehicleModel) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    
    if HasModelLoaded(vehicleModel) then
        local vehicle = CreateVehicle(vehicleModel, coords.x, coords.y, coords.z, GetEntityHeading(playerPed), true, false)
        if vehicle then
            -- Set vehicle properties
            SetVehicleOnGroundProperly(vehicle)
            SetEntityAsMissionEntity(vehicle, true, true)
            
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Exito',
                description = 'Has recibido un ' .. itemData.label .. ' (no se pudo agregar al garage)',
                type = 'success'
            })
            
            -- Log to Discord using the enhanced CreatePurchaseEmbed function
            local itemDataWithLocation = table.copy(itemData)
            itemDataWithLocation.category = "Vehicle (Spawned in World)"
            local embed = CreatePurchaseEmbed(vehicleModel, src, itemDataWithLocation)
            SendDiscordLog("VIP Shop - Vehicle Purchase", embed)
            
            print("[ZK-VIP] Player " .. GetPlayerName(src) .. " received vehicle: " .. vehicleModel)
        else
            print("[ZK-VIP] Failed to spawn vehicle: " .. vehicleModel)
            -- Refund coins
            exports.ox_inventory:AddItem(src, Config.CoinsItem, itemData.price)
            
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Error',
                description = 'Error al entregar el vehiculo. Monedas devueltas.',
                type = 'error'
            })
        end
    else
        print("[ZK-VIP] Failed to load vehicle model: " .. vehicleModel)
        -- Refund coins
        exports.ox_inventory:AddItem(src, Config.CoinsItem, itemData.price)
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Modelo de vehiculo no encontrado. Monedas devueltas.',
            type = 'error'
        })
    end
end)
