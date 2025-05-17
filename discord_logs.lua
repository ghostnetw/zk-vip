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

-- Configuration for images
local serverUrl = "" -- Leave empty for relative URLs
local defaultItemImage = "https://i.imgur.com/9QdqNXs.png"

-- Vehicles image mappings - you can add more vehicles here as needed
local vehicleImages = {
    adder = "https://i.imgur.com/9QdqNXs.png",
    alpha = "https://i.imgur.com/9QdqNXs.png",
    sultanrs = "https://i.imgur.com/9QdqNXs.png",
    neo = "https://i.imgur.com/9QdqNXs.png",
    neon = "https://i.imgur.com/9QdqNXs.png"
    -- Add more vehicles as needed
}

-- Function to get item image URL from ox_inventory or vehicle list
local function getItemImage(itemName)
    -- Remove 'veh_' prefix for vehicles if present
    local isVehicle = false
    local itemNameClean = itemName
    
    if string.match(itemName, "^veh_") then
        itemNameClean = string.gsub(itemName, "^veh_", "")
        isVehicle = true
    end
    
    -- If it's a vehicle, use vehicle images
    if isVehicle then
        return vehicleImages[itemNameClean] or defaultItemImage
    end
    
    -- For regular items, use ox_inventory images
    local inventoryImagePath = serverUrl .. "ox_inventory/web/images/" .. itemNameClean .. ".png"
    
    -- Special handling for weapons (they have a different prefix in ox_inventory)
    if string.match(itemNameClean, "^weapon_") then
        return inventoryImagePath
    end
    
    -- Return the ox_inventory path for regular items
    return inventoryImagePath
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
    return "https://i.imgur.com/9QdqNXs.png" -- Default avatar if Discord ID not found
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

-- Function to send a message to Discord
-- message: The main content of the message
-- embed: (Optional) An embed object as per Discord webhook documentation
function SendDiscordLog(message, embed)
    -- Create a simple payload that is guaranteed to work
    local data = {
        content = "🛒 **VIP Shop: ** " .. message,
        username = "ZK-VIP System",
        avatar_url = "https://i.imgur.com/9QdqNXs.png"
    }
    
    -- Only add embeds if provided and keep it simple
    if embed then
        -- Extract player name if available
        local playerName = "Unknown Player"
        if embed.author and embed.author.name then
            playerName = string.match(embed.author.name, "([^%s]+)")
        end
        
        -- Extract license if available
        local license = "Unknown"
        if embed.fields and embed.fields[2] then
            local fieldValue = embed.fields[2].value or ""
            license = string.match(fieldValue, "FiveM License:** `([^`]+)`") or "Unknown"
        end
        
        -- Get item details
        local itemName = "Unknown Item"
        local itemPrice = "0"
        if embed.fields and embed.fields[1] then
            local fieldValue = embed.fields[1].value or ""
            itemName = string.match(fieldValue, "Name:** ([^\n]+)") or "Unknown Item"
            itemPrice = string.match(fieldValue, "Price:** ([^\n]+)") or "0 coins"
        end
        
        -- Get server info for location - safe method that won't cause errors
        local serverName = GetConvar("sv_hostname", "Unknown Server")
        local locationText = "📡 " .. serverName
        
        -- Timestamp for the transaction
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        
        data.embeds = {{
            title = "💰 VIP Purchase",
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
                    inline = true
                },
                {
                    name = "💵 Price",
                    value = itemPrice,
                    inline = true
                },
                {
                    name = "📍 Location",
                    value = locationText,
                    inline = true
                }
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    end

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
function CreatePurchaseEmbed(itemName, playerSrc, itemData)
    -- Initialize variables with safe defaults
    local playerName = "Unknown"
    local avatarUrl = "https://i.imgur.com/9QdqNXs.png"
    
    -- Error handling for player source - must have a valid numeric player ID
    local validSource = false
    if playerSrc and type(playerSrc) == "number" and playerSrc > 0 then
        if GetPlayerName(playerSrc) then
            validSource = true
            playerName = GetPlayerName(playerSrc) or "Unknown Player"
            avatarUrl = getPlayerAvatarUrl(playerSrc) or "https://i.imgur.com/9QdqNXs.png"
        end
    end
    
    -- Error handling for itemData
    local itemLabel = "Unknown Item"
    local itemCategory = "Unknown Type"
    local itemPrice = 0
    
    if itemData then
        itemLabel = itemData.label or itemName or "Unknown Item"
        itemCategory = itemData.category or "Vehicle"
        itemPrice = itemData.price or 0
    end
    
    -- Create the embed object
    local embed = {
        title = "VIP Shop Purchase",
        color = 5763719, -- Green color
        thumbnail = {
            url = getItemImage(itemName or "")
        },
        author = {
            name = playerName .. " purchased: " .. itemLabel,
            icon_url = avatarUrl
        },
        description = "A purchase was made in the VIP shop",
        fields = {
            {
                name = "📦 Item Details",
                value = "**Name:** " .. itemLabel .. 
                       "\n**Type:** " .. itemCategory .. 
                       "\n**Price:** " .. itemPrice .. " VIP Coins",
                inline = true
            },
            {
                name = "👤 Player Information",
                value = "**Name:** " .. playerName .. "\n" .. getPlayerInfo(playerSrc or 0),
                inline = true
            }
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time()),
        footer = {
            text = "ZK-VIP System",
            icon_url = "https://r2.fivemanage.com/rNuxARYnz7C0keGsVTuqt/logo(2).png"
        }
    }
    
    -- Log the created embed
    print("[ZK-VIP] Created purchase embed for item: " .. (itemName or "unknown"))
    
    return embed
end

-- You can add more functions here for different types of logs if needed

-- Example usage (for testing - remove in production):
-- Citizen.CreateThread(function()
--     Citizen.Wait(5000) -- Wait 5 seconds after resource start
--     SendDiscordLog("Server started and Discord logging is active!")
-- end) 