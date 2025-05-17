# ZK-VIP Shop System

A comprehensive VIP shop system for FiveM servers using QBCore framework and ox_inventory. This resource allows server administrators to create a VIP shop where players can spend special VIP coins to purchase exclusive items, vehicles, and other benefits.

![VIP Shop Banner](https://img.icons8.com/dusk/50/ghost--v1.png)

## 🌟 Features

- **User-Friendly Shop Interface**: Clean and intuitive UI for players to browse and purchase VIP items
- **Multiple Item Categories**: Support for vehicles, weapons, money, and special items
- **Easy Configuration**: Simple configuration file to add, remove, or modify shop items
- **Discord Logging**: Detailed logs of all purchases sent to Discord with player info
- **Vehicle Integration**: Seamless integration with garage systems for vehicle purchases
- **Admin Commands**: Test and administrative commands for server management

## 📋 Requirements

- [QBCore Framework](https://github.com/qbcore-framework/qb-core)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [jg-advancedgarages](https://github.com/JGUsman007/JG-Advanced-Garages) (for vehicle integration)

## 🔧 Installation

1. Drop the `vip` resource into your `resources/[interfaz]` folder
2. Add `ensure vip` to your server.cfg
3. Configure Discord webhook URL in `discord_logs.lua`
4. Customize items and prices in `config.lua`
5. Restart your server

## ⚙️ Configuration

### Config.lua

```lua
Config = {}

-- Name of the VIP coin item in your inventory
Config.CoinsItem = "vip_coin"

-- Available items in the shop
Config.Items = {
    -- Format: { name = "item_name", label = "Display Name", price = 1000, category = "category_name" }
    
    -- Example vehicles
    { name = "veh_adder", label = "Adder", price = 8606, category = "vehicles_vip" },
    { name = "veh_neo", label = "Neo", price = 8569, category = "vehicles_vip" },
    
    -- Example weapons
    { name = "weapon_pistol", label = "Pistola", price = 800, category = "weapons" },
    
    -- Example money items
    { name = "black_money", label = "Dinero Negro ($10k)", price = 1000, category = "money" },
}
```

### Discord Logging

Configure your Discord webhook in `discord_logs.lua`:

```lua
local discordWebhookURL = "YOUR_WEBHOOK_URL_HERE"
```

## 🎮 How to Use

### Player Usage

1. Players need VIP coins in their inventory to make purchases
2. Open the shop using the command: `/vip`
3. Browse categories and select items to purchase
4. Click "Buy" button to purchase the item

### Admin Commands

- `/vip_test_discord` - Test Discord logging
- `/refresh && /stop vip && /start vip` - Restart the resource if needed

## 🛠️ Technical Details

- **Server Scripts**: Handle purchase validation, rewards, and logging
- **Client Scripts**: Manage UI interaction and display
- **Discord Logging**: Detailed purchase logs with player info and license
- **Inventory Integration**: Uses ox_inventory for item management
- **Vehicle Integration**: Direct SQL integration with vehicle tables

## 📷 Discord Logs

Discord logs include:
- 👤 Player Name
- 🆔 Player License
- 🏷️ Item Purchased
- 💵 Price Paid
- 📍 Server Information

## 🧑‍💻 Development & Customization

The system is built with customization in mind. Key files:

- `server.lua` - Main server-side logic
- `discord_logs.lua` - Discord webhook integration
- `config.lua` - Item and price configuration
- `html/` - UI files for the shop interface

## 📃 License

This resource is created by ZK-GH0ST.

## 💬 Support

For support, join our Discord server: [YOUR_DISCORD_INVITE_HERE]

---

*Made with ❤️ by ZK-GH0ST - Customized for your FiveM server*
