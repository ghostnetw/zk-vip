-- Discord Logging Module
print("[ZK-VIP Discord Log] discord_logs.lua loaded.") -- Test print

-- Helper function to copy tables (needed for itemData manipulation)
if not table.copy then
    table.copy = function(t)
        local u = {}
        for k, v in pairs(t) do
            u[k] = v
        end
        return u
    end
end

local discordWebhookURL = "https://discord.com/api/webhooks/1331006923885252649/uHQkR0qa8sSopsAVvtwFYpwRcBPZdk-6OlMP-YcEYUVbFW6Tw4NfM2Of6C2WHwiuyCfz" -- Replace with your actual webhook URL

-- Configuration for images - must be publicly accessible URLs for Discord
local defaultItemImage = "https://img.icons8.com/dusk/50/ghost--v1.png"

-- Vehicle images for Discord - updated with ghost icon
local vehicleImages = {
    adder = "https://img.icons8.com/dusk/50/ghost--v1.png",
    alpha = "https://img.icons8.com/dusk/50/ghost--v1.png",
    sultanrs = "https://img.icons8.com/dusk/50/ghost--v1.png",
    neo = "https://img.icons8.com/dusk/50/ghost--v1.png",
    neon = "https://img.icons8.com/dusk/50/ghost--v1.png",
    b800 = "https://img.icons8.com/dusk/50/ghost--v1.png",
    granlb = "https://img.icons8.com/dusk/50/ghost--v1.png",
    bugatti = "https://img.icons8.com/dusk/50/ghost--v1.png"
    -- Add more vehicles as needed
}

-- Function to get item image URL from ox_inventory or vehicle list - with ABSOLUTE URLs for Discord
local function getItemImage(itemName)
    -- If no item name provided, return default image
    if not itemName or itemName == "" then
        return defaultItemImage
    end
    
    -- Remove 'veh_' prefix for vehicles if present
    local isVehicle = false
    local itemNameClean = itemName
    
    if string.match(itemName, "^veh_") then
        itemNameClean = string.gsub(itemName, "^veh_", "")
        isVehicle = true
    end
    
    -- If it's a vehicle, use vehicle images from our predefined list
    if isVehicle then
        return vehicleImages[itemNameClean] or defaultItemImage
    elseif vehicleImages[itemName] then
        -- Also check without the prefix
        return vehicleImages[itemName] or defaultItemImage
    end
    
    -- For all other items, use a generic image since Discord can't access relative URLs
    return defaultItemImage
end

-- Function to get player's Discord ID
local function getPlayerDiscordId(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string.match(id, "discord:") then
            local discordId = string.gsub(id, "discord:", "")
            return discordId
        end
    end
    return nil
end

-- Function to get player's avatar URL from Discord
local function getPlayerAvatarUrl(src)
    local discordId = getPlayerDiscordId(src)
    if discordId then
        return "https://r2.fivemanage.com/rNuxARYnz7C0keGsVTuqt/" .. discordId .. "/" .. discordId .. ".png"
    end
    return "https://img.icons8.com/dusk/50/ghost--v1.png" -- Default avatar if Discord ID not found
end

-- Function to format player info
local function getPlayerInfo(src)
    local steamId = nil
    local license = nil
    local discord = nil
    local fivemLicense = nil
    
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string.match(id, "steam:") then
            steamId = id
        elseif string.match(id, "license:") then
            license = id
            -- Extract the clean FiveM license without the prefix
            fivemLicense = string.gsub(id, "license:", "")
        elseif string.match(id, "discord:") then
            discord = id
        end
    end
    
    -- Format the player info with FiveM license highlighted
    return string.format("**FiveM License:** `%s`\n**Steam:** %s\n**License:** %s\n**Discord:** %s", 
        fivemLicense or "N/A",
        steamId or "N/A", 
        license or "N/A",
        discord or "N/A")
end

-- Simplified function to send a message to Discord
function SendDiscordLog(message, title, playerName, itemName, itemPrice, license)
    -- Default values
    title = title or "💰 VIP Purchase"
    playerName = playerName or "Unknown Player"
    itemName = itemName or "Unknown Item"
    itemPrice = itemPrice or 0
    license = license or "Unknown"
    
    -- Create a simple payload with minimal processing
    local serverName = GetConvar("sv_hostname", "ZK-GH0ST")
    local locationText = "📡 " .. serverName
    
    -- Create the discord payload
    local data = {
        content = "🛒 **VIP Shop: ** " .. message,
        username = "ZK-VIP System",
        avatar_url = "https://img.icons8.com/dusk/50/ghost--v1.png",
        embeds = {
            {
                title = title,
                description = "✅ Transaction completed successfully",
                color = 3066993,  -- Green color
                fields = {
                    {
                        name = "👤 Player",
                        value = playerName,
                        inline = true
                    },
                    {
                        name = "🆔 License",
                        value = "`" .. license .. "`",
                        inline = true
                    },
                    {
                        name = "🏷️ Item",
                        value = itemName,
                        inline = false
                    },
                    {
                        name = "💵 Price",
                        value = tostring(itemPrice) .. " VIP Coins",
                        inline = true
                    },
                    {
                        name = "📍 Server",
                        value = locationText,
                        inline = true
                    }
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                thumbnail = {
                    url = getItemImage(itemName) or defaultItemImage
                },
                footer = {
                    text = "ZK-VIP System",
                    icon_url = "https://img.icons8.com/dusk/50/ghost--v1.png"
                }
            }
        }
    }

    -- Convert to JSON with error handling
    local success, jsonData = pcall(json.encode, data)
    if not success then
        print("[ZK-VIP] ERROR: Failed to encode JSON: " .. tostring(jsonData))
        return
    end
    
    -- Debug info
    print("[ZK-VIP] Sending simple Discord webhook: " .. message)

    -- Send with response handling
    PerformHttpRequest(discordWebhookURL, function(statusCode, text)
        if statusCode == 200 or statusCode == 204 then
            print("[ZK-VIP] Discord webhook sent successfully")
        else
            print("[ZK-VIP] Discord webhook failed with status code: " .. tostring(statusCode) .. ", response: " .. tostring(text))
        end
    end, 'POST', jsonData, { ['Content-Type'] = 'application/json' })
end

-- Store the player source in the embed data for later use
-- Direct function to log a purchase to Discord with all details
function LogPurchaseToDiscord(itemName, playerSrc, itemData)
    -- Safety check for arguments
    if not playerSrc then 
        print("[ZK-VIP] ERROR: Invalid player source in LogPurchaseToDiscord")
        return false
    end

    -- Get basic player info
    local playerName = GetPlayerName(playerSrc) or "Unknown"
    local license = "Unknown"
    local avatarUrl = "https://img.icons8.com/dusk/50/ghost--v1.png"
    
    -- Get player license directly with error handling
    if playerSrc > 0 then
        local identifiers = GetPlayerIdentifiers(playerSrc)
        if identifiers then
            for _, id in ipairs(identifiers) do
                if string.match(id, "license:") then
                    license = string.gsub(id, "license:", "")
                    break
                end
            end
        end
    end
    
    -- Get Discord avatar safely
    local discordId = getPlayerDiscordId(playerSrc)
    if discordId then
        avatarUrl = "https://r2.fivemanage.com/rNuxARYnz7C0keGsVTuqt/" .. discordId .. "/" .. discordId .. ".png"
    end
    
    -- Get item details directly with validation
    local itemLabel = itemName or "Unknown Item"
    local itemCategory = "VIP Item"
    local itemPrice = 0
    
    -- Safely extract item data
    if itemData then
        if type(itemData.label) == "string" then
            itemLabel = itemData.label
        end
        
        if type(itemData.category) == "string" then
            itemCategory = itemData.category
        end
        
        if type(itemData.price) == "number" then
            itemPrice = itemData.price
        end
    end
    
    -- Debug info to console
    print(string.format("[ZK-VIP] Purchase log - Player: %s, License: %s, Item: %s, Price: %d", 
        playerName, license, itemLabel, itemPrice))
    
    -- Get server info
    local serverName = GetConvar("sv_hostname", "ZK-GH0ST")
    
    -- Create a clean payload directly
    local data = {
        username = "ZK-VIP System",
        avatar_url = "https://img.icons8.com/dusk/50/ghost--v1.png",
        embeds = {
            {
                title = "💰 VIP Purchase",
                description = "✅ Transaction completed successfully",
                color = 3066993, -- Green color
                author = {
                    name = playerName,
                    icon_url = avatarUrl
                },
                fields = {
                    {
                        name = "👤 Player",
                        value = playerName,
                        inline = true
                    },
                    {
                        name = "🆔 License",
                        value = "`" .. license .. "`",
                        inline = true
                    },
                    {
                        name = "🏷️ Item",
                        value = itemLabel,
                        inline = false
                    },
                    {
                        name = "💵 Price",
                        value = tostring(itemPrice) .. " VIP Coins",
                        inline = true
                    },
                    {
                        name = "📍 Server",
                        value = "📡 " .. serverName,
                        inline = true
                    }
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                thumbnail = {
                    url = getItemImage(itemName or "")
                }
            }
        }
    }
    
    -- Convert to JSON with error handling
    local success, jsonData = pcall(json.encode, data)
    if not success then
        print("[ZK-VIP] ERROR: Failed to encode JSON: " .. tostring(jsonData))
        return
    end
    
    -- Send to Discord directly
    PerformHttpRequest(discordWebhookURL, function(statusCode, text)
        if statusCode == 200 or statusCode == 204 then
            print("[ZK-VIP] Discord webhook sent successfully")
        else
            print("[ZK-VIP] Discord webhook failed with status code: " .. tostring(statusCode) .. ", response: " .. tostring(text))
            print("[ZK-VIP] Webhook data: " .. jsonData)
        end
    end, 'POST', jsonData, { ['Content-Type'] = 'application/json' })
    
    -- Return true to indicate success
    return true
end

-- Legacy function name for backward compatibility
function CreatePurchaseEmbed(itemName, playerSrc, itemData)
    -- Just call the new function directly
    return LogPurchaseToDiscord(itemName, playerSrc, itemData)
end

-- Add a test command to verify Discord logging works
RegisterCommand('vip_test_discord', function(source, args)
    -- Check if player is admin
    if IsPlayerAceAllowed(source, 'command') then
        local testItem = {
            name = "test_item",
            label = "Test Item",
            price = 1000,
            category = "testing"
        }
        LogPurchaseToDiscord("test_item", source, testItem)
        TriggerClientEvent('QBCore:Notify', source, 'Discord test log sent!', 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'You do not have permission to use this command', 'error')
    end
end, false)

-- Example usage (for testing - remove in production):
-- Citizen.CreateThread(function()
--     Citizen.Wait(5000) -- Wait 5 seconds after resource start
--     SendDiscordLog("Server started and Discord logging is active!")
-- end) 