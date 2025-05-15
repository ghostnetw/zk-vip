Config = {}

-- Nombre del ítem moneda (NO CAMBIAR)
Config.CoinsItem = "vip_coin" -- Este es el item que representa monedas VIP en el inventario

-- Ítems disponibles
Config.Items = {
    -- Vehículos VIP
    { name = "rmodc63amg", label = "Mercedes C63 AMG", price = 5000, category = "vehicles_vip", image = "c63amg.png" },
    { name = "neo", label = "Vysser Neo", price = 3000, category = "vehicles_vip", image = "neo.png" },
    { name = "sultanrs", label = "Sultan RS", price = 2500, category = "vehicles_vip", image = "sultanrs.png" },
    
    -- Vehículos Sport
    { name = "veh_zentorno", label = "Zentorno", price = 2800, category = "vehicles_sport", image = "zentorno.png" },
    { name = "veh_t20", label = "T20", price = 3500, category = "vehicles_sport", image = "t20.png" },
    { name = "veh_jester", label = "Jester", price = 2200, category = "vehicles_sport", image = "jester.png" },
    { name = "veh_infernus", label = "Infernus", price = 2900, category = "vehicles_sport", image = "infernus.png" },
    
    -- Vehículos Blindados
    { name = "veh_insurgent", label = "Insurgent", price = 4000, category = "vehicles_armored", image = "insurgent.png" },
    { name = "veh_kuruma2", label = "Kuruma Blindado", price = 3200, category = "vehicles_armored", image = "kuruma.png" },
    
    -- Armas
    { name = "weapon_pistol", label = "Pistola", price = 800, category = "weapons", image = "pistol.png" },
    { name = "weapon_smg", label = "SMG", price = 1200, category = "weapons", image = "smg.png" },
    { name = "weapon_carbinerifle", label = "Carabina", price = 1800, category = "weapons", image = "carbine.png" },
    
    -- Dinero
    { name = "black_money", label = "Dinero Negro ($10k)", price = 1000, category = "money", image = "blackmoney.png" },
    { name = "black_money", label = "Dinero Negro ($25k)", price = 2200, category = "money", image = "blackmoney.png" },
    
    -- Especial
    { name = "vip_crate", label = "Caja VIP", price = 5000, category = "special", image = "crate.png" },
    { name = "parachute", label = "Paracaídas", price = 500, category = "special", image = "parachute.png" },
}
