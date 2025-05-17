$(function() {
    // Hide container initially
    $('#zk-vip-container').hide();
    
    // Store categories and current items
    let allCategories = [];
    let currentCategory = null;
    
    // Handle messages from client
    window.addEventListener('message', function(event) {
        const data = event.data;
        console.log('NUI message received:', data.type);
        
        if (data.type === "openVipShop") {
            console.log('Opening VIP shop with coins:', data.coins);
            
            // Update coins display
            $('#coin-count').text(data.coins);
            
            // Check if categories exist and store them
            if (data.categories && Array.isArray(data.categories)) {
                console.log('Categories received:', data.categories.length);
                allCategories = data.categories;
                
                // Setup category selection dropdown
                $('#category').empty();
                $.each(allCategories, function(index, category) {
                    $('#category').append(`<option value="${category.name}">${category.label}</option>`);
                });
                
                // Select first category by default
                if (allCategories.length > 0) {
                    currentCategory = allCategories[0].name;
                    displayCategoryItems(allCategories[0]);
                }
            } else {
                console.error('No categories received or invalid format');
                // Handle legacy format (direct items array)
                if (data.items && Array.isArray(data.items)) {
                    console.log('Using legacy items format');
                    // Create a single default category
                    allCategories = [{
                        name: 'default',
                        label: 'Artículos VIP',
                        items: data.items
                    }];
                    
                    // Setup categories dropdown
                    $('#category').empty();
                    $('#category').append(`<option value="default">Artículos VIP</option>`);
                    
                    // Display items
                    currentCategory = 'default';
                    displayCategoryItems(allCategories[0]);
                }
            }
            
            // Show the container
            $('#zk-vip-container').show();
        }
        
        if (data.type === "closeVipShop") {
            $('#zk-vip-container').hide();
        }
        
        if (data.type === "updateCategory") {
            // Find and display the selected category
            $.each(allCategories, function(index, category) {
                if (category.name === data.category) {
                    currentCategory = category.name;
                    displayCategoryItems(category);
                    return false; // break the loop
                }
            });
        }
    });
    
    // Display items for a category
    function displayCategoryItems(category) {
        // Clear item list
        $('#item-list').empty();
        
        // Safety check if category or items are undefined
        if (!category || !category.items || !Array.isArray(category.items)) {
            console.error('Invalid category or items:', category);
            $('#item-list').html('<div class="error-message">No hay artículos disponibles</div>');
            return;
        }
        
        // Handle empty category
        if (category.items.length === 0) {
            $('#item-list').html('<div class="error-message">No hay artículos en esta categoría</div>');
            return;
        }
        
        console.log(`Displaying ${category.items.length} items for category: ${category.name}`);
        
        // Add all items from this category
        $.each(category.items, function(index, item) {
            // Default values in case some properties are missing
            const name = item.name || 'unknown';
            const label = item.label || 'Item desconocido';
            const price = item.price || 0;
            const imageUrl = item.image ? item.image : "https://img.icons8.com/dusk/50/ghost--v1.png";
            
            const card = $('<div class="vip-card">').html(`
                <img src="${imageUrl}" alt="${label}">
                <h3>${label}</h3>
                <p>💎 ${price}</p>
                <button data-item="${name}">Comprar</button>
            `);
            
            $('#item-list').append(card);
        });
    }
    
    // Category change handler
    $('#category').change(function() {
        const selectedCategory = $(this).val();
        
        // Post to client to handle category change
        $.post('https://' + GetParentResourceName() + '/selectCategory', JSON.stringify({
            category: selectedCategory
        }));
    });
    
    // Buy button click handler
    $(document).on('click', '.vip-card button', function() {
        const itemName = $(this).data('item');
        $.post('https://' + GetParentResourceName() + '/buyItem', JSON.stringify({
            item: itemName
        }));
    });
    
    // Close button handler
    $('#close-btn').click(function() {
        $.post('https://' + GetParentResourceName() + '/close', JSON.stringify({}));
    });
});
