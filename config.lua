Config = {}

-- Nombre del ítem moneda (NO CAMBIAR)
Config.CoinsItem = "vip_coin" -- Este es el item que representa monedas VIP en el inventario

-- Ítems disponibles
Config.Items = {
    -- Vehículos VIP 
    { name = "veh_adder", label = "Adder", price = 8606, category = "vehicles_vip" },
    { name = "veh_alpha", label = "Alpha", price = 8252, category = "vehicles_vip" },
    { name = "veh_sultanrs", label = "Sultan RS", price = 8219, category = "vehicles_vip" },
    { name = "veh_neo", label = "Neo", price = 8569, category = "vehicles_vip" },
    { name = "veh_neon", label = "Neon", price = 65763, category = "vehicles_vip" },
    { name = "b800", label = "Mercedes B800", price = 65763, category = "vehicles_vip" },
    { name = "granlb", label = "MassaritiMC", price = 65763, category = "vehicles_vip" },
    { name = "bugatti", label = "Bugatti Veyron", price = 65763, category = "vehicles_vip" },

    -- Armas
    { name = "weapon_pistol", label = "Pistola", price = 800, category = "weapons" },
    { name = "weapon_smg", label = "SMG", price = 1200, category = "weapons" },
    { name = "weapon_carbinerifle", label = "Carabina", price = 1800, category = "weapons" },

    -- Dinero Sucio
    { name = "black_money", label = "Dinero Negro ($10k)", price = 1000, category = "money" },
    { name = "black_money", label = "Dinero Negro ($25k)", price = 2200, category = "money" },

    -- Especial
    { name = "parachute", label = "Paracaídas", price = 500, category = "special" },
}
