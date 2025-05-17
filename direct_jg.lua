-- Direct integration with jg-advancedgarages
-- This file contains functions to directly integrate with jg-advancedgarages

-- Store QBCore reference passed from server.lua
local _QBCore = nil

-- Initialize function to receive QBCore and other globals
local function Initialize(QBCore)
    _QBCore = QBCore
    print("[ZK-VIP] Direct JG module initialized" .. (QBCore and " with QBCore" or ""))
    return true
end

-- Function to spy on how jg-advancedgarages adds vehicles
local function InspectJGGaragesFunctions()
    -- Only run if jg-advancedgarages is available
    if not exports['jg-advancedgarages'] then
        print("[ZK-VIP] jg-advancedgarages is not available")
        return false
    end

    -- Print debug info about the resource
    print("[ZK-VIP] Inspecting jg-advancedgarages...")
    
    -- Get info about the jg-advancedgarages resource
    local resourceState = GetResourceState('jg-advancedgarages')
    print("[ZK-VIP] jg-advancedgarages state: " .. resourceState)
    
    -- Try a different approach to find exported functions
    local exportFunctions = {}
    
    -- Common export function names to test
    local commonExports = {
        "getAllGarages", "addVehicle", "AddVehicle", "addCarToGarage",
        "storeVehicle", "addCar", "InsertVehicle", "CreateVehicle"
    }
    
    for _, funcName in ipairs(commonExports) do
        local success, _ = pcall(function()
            return exports['jg-advancedgarages'][funcName] ~= nil
        end)
        
        if success and exports['jg-advancedgarages'][funcName] then
            table.insert(exportFunctions, funcName)
        end
    end
    
    if #exportFunctions > 0 then
        print("[ZK-VIP] Found " .. #exportFunctions .. " export functions:")
        for _, funcName in ipairs(exportFunctions) do
            print("  - " .. funcName)
        end
    else
        print("[ZK-VIP] No export functions found")
    end
    
    return true
end

-- Function to query the database for garage structure
local function InspectGarageDatabase()
    -- Check if MySQL is loaded or accessible
    local mysqlSuccess, _ = pcall(function() 
        return MySQL ~= nil and MySQL.Sync ~= nil 
    end)
    
    if not mysqlSuccess or not MySQL or not MySQL.Sync then
        print("[ZK-VIP] MySQL not available")
        return
    end
    
    -- Check if jg-advancedgarages tables exist
    local tables = {'player_cars', 'player_vehicles'}
    
    for _, tableName in ipairs(tables) do
        local tableExists = MySQL.Sync.fetchScalar('SHOW TABLES LIKE ?', {tableName})
        if tableExists then
            print("[ZK-VIP] Table exists: " .. tableName)
            
            -- Get column structure
            local columns = MySQL.Sync.fetchAll('DESCRIBE ' .. tableName)
            if columns then
                print("[ZK-VIP] Table structure for " .. tableName .. ":")
                for _, column in ipairs(columns) do
                    print("  - " .. column.Field .. " (" .. column.Type .. ")")
                end
            end
            
            -- Get sample data (first row)
            local sampleData = MySQL.Sync.fetchAll('SELECT * FROM ' .. tableName .. ' LIMIT 1')
            if sampleData and #sampleData > 0 then
                print("[ZK-VIP] Sample data from " .. tableName .. ":")
                for k, v in pairs(sampleData[1]) do
                    if type(v) == "string" and string.len(v) > 100 then
                        v = string.sub(v, 1, 100) .. "... (truncated)"
                    end
                    print("  - " .. k .. ": " .. tostring(v))
                end
            else
                print("[ZK-VIP] No data in " .. tableName)
            end
        else
            print("[ZK-VIP] Table does not exist: " .. tableName)
        end
    end
end

-- Function to add a vehicle to jg-advancedgarages by directly copying a known working vehicle
-- This is a last resort approach that should work in most cases
local function AddVehicleByTemplate(playerId, vehicleModel, plate, citizenid)
    -- If no citizenid was provided, try to get it from QBCore if available
    if not citizenid and _QBCore then
        local Player = _QBCore.Functions.GetPlayer(playerId)
        if Player then
            citizenid = Player.PlayerData.citizenid
        end
    end
    
    if not citizenid then
        print("[ZK-VIP] Could not get player citizenid")
        return false
    end
    
    -- Check if MySQL is loaded or accessible
    local mysqlSuccess, _ = pcall(function() 
        return MySQL ~= nil and MySQL.Sync ~= nil 
    end)
    
    if not mysqlSuccess or not MySQL or not MySQL.Sync then
        print("[ZK-VIP] MySQL not available")
        return false
    end
    
    -- Determine which table to use
    local targetTable
    local tableExists = MySQL.Sync.fetchScalar('SHOW TABLES LIKE ?', {'player_cars'})
    if tableExists then
        targetTable = 'player_cars'
    else
        tableExists = MySQL.Sync.fetchScalar('SHOW TABLES LIKE ?', {'player_vehicles'})
        if tableExists then
            targetTable = 'player_vehicles'
        else
            print("[ZK-VIP] Could not find vehicle storage table")
            return false
        end
    end
    
    print("[ZK-VIP] Using table: " .. targetTable)
    
    -- Find an existing vehicle to use as template
    local template = MySQL.Sync.fetchAll('SELECT * FROM ' .. targetTable .. ' LIMIT 1')
    if not template or #template == 0 then
        print("[ZK-VIP] No template vehicle found")
        return false
    end
    
    print("[ZK-VIP] Found template vehicle")
    
    -- Create an insert query based on the template
    local columns = {}
    local values = {}
    local placeholders = {}
    
    for k, v in pairs(template[1]) do
        table.insert(columns, k)
        
        -- Special handling for specific fields
        if k == 'id' then
            table.insert(placeholders, 'NULL') -- Let the database assign an ID
        elseif k == 'citizenid' then
            table.insert(placeholders, '?')
            table.insert(values, citizenid)
        elseif k == 'vehicle' then
            table.insert(placeholders, '?')
            table.insert(values, vehicleModel)
        elseif k == 'hash' and GetHashKey then
            table.insert(placeholders, '?')
            table.insert(values, GetHashKey(vehicleModel) or 0)
        elseif k == 'plate' then
            table.insert(placeholders, '?')
            table.insert(values, plate)
        elseif k == 'mods' then
            local modsData = {
                model = vehicleModel,
                plate = plate,
                fuelLevel = 100,
                engineHealth = 1000.0,
                bodyHealth = 1000.0,
                color1 = 0,
                color2 = 0
            }
            table.insert(placeholders, '?')
            table.insert(values, json.encode(modsData))
        else
            table.insert(placeholders, '?')
            table.insert(values, v)
        end
    end
    
    -- Build and execute query
    local query = 'INSERT INTO ' .. targetTable .. ' (' .. table.concat(columns, ', ') .. ') VALUES (' .. table.concat(placeholders, ', ') .. ')'
    print("[ZK-VIP] Executing query: " .. query)
    
    local success = pcall(function()
        MySQL.Async.execute(query, values)
    end)
    
    if success then
        print("[ZK-VIP] Successfully added vehicle using template method")
        return true
    else
        print("[ZK-VIP] Failed to add vehicle using template method")
        return false
    end
end

-- Export functions
return {
    InspectJGGaragesFunctions = InspectJGGaragesFunctions,
    InspectGarageDatabase = InspectGarageDatabase,
    AddVehicleByTemplate = AddVehicleByTemplate
}
