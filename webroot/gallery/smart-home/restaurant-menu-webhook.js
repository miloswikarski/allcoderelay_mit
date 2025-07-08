/**
 * AllCodeRelay Smart Restaurant Menu Webhook
 * 
 * This Node.js webhook provides interactive restaurant menu information
 * when customers scan QR codes at tables or on menu items.
 * 
 * Features:
 * - Table-specific menus and specials
 * - Dish details with ingredients and allergens
 * - Multilingual support
 * - Daily specials and promotions
 * - Nutritional information
 * - Price and availability updates
 * 
 * Setup Instructions:
 * 1. Install dependencies: npm install express fs path dotenv
 * 2. Configure environment variables (see .env.example)
 * 3. Customize menu data in menu-data.json
 * 4. Start server: node restaurant-menu-webhook.js
 */

const express = require('express');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3001;

// Middleware
app.use(express.json());
app.use(express.static('public'));

// Load menu data
let menuData = {};
let restaurantConfig = {};

try {
    menuData = JSON.parse(fs.readFileSync(path.join(__dirname, 'menu-data.json'), 'utf8'));
    restaurantConfig = JSON.parse(fs.readFileSync(path.join(__dirname, 'restaurant-config.json'), 'utf8'));
} catch (error) {
    console.error('Error loading menu data:', error);
    // Initialize with sample data if files don't exist
    initializeSampleData();
}

// Main webhook endpoint
app.post('/webhook', async (req, res) => {
    try {
        const { code } = req.body;
        
        if (!code) {
            return res.status(400).json({
                code: 'ERROR',
                codevalue: 'No code provided'
            });
        }

        console.log(`Received code: ${code}`);

        // Parse the QR code to determine what information to show
        const codeInfo = parseMenuCode(code);
        
        if (!codeInfo) {
            return res.json({
                code: code,
                codevalue: `❓ Unknown Menu Code\n\n${code}\n\nThis QR code is not recognized.\nPlease scan a valid menu or table QR code.`
            });
        }

        let response;
        
        switch (codeInfo.type) {
            case 'table':
                response = await getTableMenu(codeInfo);
                break;
            case 'dish':
                response = await getDishDetails(codeInfo);
                break;
            case 'category':
                response = await getCategoryMenu(codeInfo);
                break;
            case 'special':
                response = await getSpecialOffer(codeInfo);
                break;
            default:
                response = {
                    code: code,
                    codevalue: '❓ Unknown menu item type'
                };
        }

        res.json(response);

    } catch (error) {
        console.error('Webhook error:', error);
        res.status(500).json({
            code: req.body.code || 'ERROR',
            codevalue: '❌ An error occurred. Please try again or ask your server for assistance.'
        });
    }
});

// Parse menu QR codes
function parseMenuCode(code) {
    // Table codes: TABLE_01, TABLE_02, etc.
    if (code.match(/^TABLE_(\d+)$/)) {
        return {
            type: 'table',
            tableNumber: code.match(/^TABLE_(\d+)$/)[1]
        };
    }
    
    // Dish codes: DISH_001, DISH_002, etc.
    if (code.match(/^DISH_(\w+)$/)) {
        return {
            type: 'dish',
            dishId: code.match(/^DISH_(\w+)$/)[1]
        };
    }
    
    // Category codes: CAT_APPETIZERS, CAT_MAINS, etc.
    if (code.match(/^CAT_(\w+)$/)) {
        return {
            type: 'category',
            categoryId: code.match(/^CAT_(\w+)$/)[1]
        };
    }
    
    // Special offer codes: SPECIAL_001, SPECIAL_002, etc.
    if (code.match(/^SPECIAL_(\w+)$/)) {
        return {
            type: 'special',
            specialId: code.match(/^SPECIAL_(\w+)$/)[1]
        };
    }
    
    return null;
}

// Get table-specific menu
async function getTableMenu(codeInfo) {
    const tableNumber = codeInfo.tableNumber;
    const table = menuData.tables?.[`table_${tableNumber}`];
    
    if (!table) {
        return {
            code: `TABLE_${tableNumber}`,
            codevalue: `❓ Table ${tableNumber} not found\n\nPlease contact your server for assistance.`
        };
    }

    const todaySpecials = getTodaySpecials();
    const welcomeMessage = restaurantConfig.welcomeMessage || 'Welcome to our restaurant!';
    
    let menuText = `🍽️ ${restaurantConfig.name}\n`;
    menuText += `📍 Table ${tableNumber}\n\n`;
    menuText += `${welcomeMessage}\n\n`;
    
    if (todaySpecials.length > 0) {
        menuText += `⭐ Today's Specials:\n`;
        todaySpecials.forEach(special => {
            menuText += `• ${special.name} - $${special.price}\n`;
        });
        menuText += `\n`;
    }
    
    menuText += `📱 Scan dish QR codes for details\n`;
    menuText += `🔔 Call server: Press button on table\n`;
    menuText += `💳 Payment: Card/Cash/Mobile\n\n`;
    
    if (table.serverName) {
        menuText += `👨‍🍳 Your server: ${table.serverName}`;
    }

    return {
        code: `TABLE_${tableNumber}`,
        codevalue: menuText
    };
}

// Get detailed dish information
async function getDishDetails(codeInfo) {
    const dishId = codeInfo.dishId;
    const dish = findDishById(dishId);
    
    if (!dish) {
        return {
            code: `DISH_${dishId}`,
            codevalue: `❓ Dish not found\n\nDish ID: ${dishId}\n\nPlease ask your server for assistance.`
        };
    }

    let dishText = `🍽️ ${dish.name}\n\n`;
    dishText += `💰 Price: $${dish.price}\n`;
    dishText += `⏱️ Prep time: ${dish.prepTime || '15-20'} min\n\n`;
    
    if (dish.description) {
        dishText += `📝 ${dish.description}\n\n`;
    }
    
    if (dish.ingredients && dish.ingredients.length > 0) {
        dishText += `🥘 Ingredients:\n${dish.ingredients.join(', ')}\n\n`;
    }
    
    if (dish.allergens && dish.allergens.length > 0) {
        dishText += `⚠️ Allergens: ${dish.allergens.join(', ')}\n\n`;
    }
    
    if (dish.nutrition) {
        dishText += `📊 Nutrition (per serving):\n`;
        dishText += `• Calories: ${dish.nutrition.calories}\n`;
        if (dish.nutrition.protein) dishText += `• Protein: ${dish.nutrition.protein}g\n`;
        if (dish.nutrition.carbs) dishText += `• Carbs: ${dish.nutrition.carbs}g\n`;
        if (dish.nutrition.fat) dishText += `• Fat: ${dish.nutrition.fat}g\n`;
        dishText += `\n`;
    }
    
    if (dish.spiceLevel) {
        const spiceEmoji = '🌶️'.repeat(dish.spiceLevel);
        dishText += `🌶️ Spice level: ${spiceEmoji} (${dish.spiceLevel}/5)\n\n`;
    }
    
    if (dish.dietary && dish.dietary.length > 0) {
        const dietaryIcons = {
            'vegetarian': '🥬',
            'vegan': '🌱',
            'gluten-free': '🚫🌾',
            'dairy-free': '🚫🥛',
            'keto': '🥑',
            'low-carb': '🥗'
        };
        
        dishText += `🏷️ Dietary: `;
        dish.dietary.forEach(diet => {
            const icon = dietaryIcons[diet] || '✅';
            dishText += `${icon} ${diet} `;
        });
        dishText += `\n\n`;
    }
    
    if (!dish.available) {
        dishText += `❌ Currently unavailable\n`;
    } else {
        dishText += `✅ Available now\n`;
    }
    
    if (dish.recommendedWith && dish.recommendedWith.length > 0) {
        dishText += `\n💡 Pairs well with:\n`;
        dish.recommendedWith.forEach(rec => {
            dishText += `• ${rec}\n`;
        });
    }

    return {
        code: `DISH_${dishId}`,
        codevalue: dishText
    };
}

// Get category menu
async function getCategoryMenu(codeInfo) {
    const categoryId = codeInfo.categoryId.toLowerCase();
    const category = menuData.categories?.[categoryId];
    
    if (!category) {
        return {
            code: `CAT_${codeInfo.categoryId}`,
            codevalue: `❓ Category not found\n\nCategory: ${codeInfo.categoryId}\n\nPlease ask your server for assistance.`
        };
    }

    let categoryText = `📋 ${category.name}\n\n`;
    
    if (category.description) {
        categoryText += `${category.description}\n\n`;
    }
    
    if (category.dishes && category.dishes.length > 0) {
        category.dishes.forEach(dish => {
            const availableIcon = dish.available !== false ? '✅' : '❌';
            categoryText += `${availableIcon} ${dish.name} - $${dish.price}\n`;
            if (dish.shortDescription) {
                categoryText += `   ${dish.shortDescription}\n`;
            }
            categoryText += `\n`;
        });
    }
    
    categoryText += `📱 Scan individual dish QR codes for full details`;

    return {
        code: `CAT_${codeInfo.categoryId}`,
        codevalue: categoryText
    };
}

// Get special offer details
async function getSpecialOffer(codeInfo) {
    const specialId = codeInfo.specialId;
    const special = menuData.specials?.[specialId];
    
    if (!special) {
        return {
            code: `SPECIAL_${specialId}`,
            codevalue: `❓ Special offer not found\n\nSpecial ID: ${specialId}\n\nPlease ask your server for current offers.`
        };
    }

    let specialText = `⭐ ${special.name}\n\n`;
    specialText += `💰 Special Price: $${special.price}`;
    
    if (special.originalPrice) {
        const savings = (special.originalPrice - special.price).toFixed(2);
        specialText += ` (Save $${savings}!)`;
    }
    
    specialText += `\n\n`;
    
    if (special.description) {
        specialText += `📝 ${special.description}\n\n`;
    }
    
    if (special.validUntil) {
        specialText += `⏰ Valid until: ${special.validUntil}\n`;
    }
    
    if (special.conditions) {
        specialText += `📋 Conditions: ${special.conditions}\n`;
    }
    
    if (special.includes && special.includes.length > 0) {
        specialText += `\n🍽️ Includes:\n`;
        special.includes.forEach(item => {
            specialText += `• ${item}\n`;
        });
    }

    return {
        code: `SPECIAL_${specialId}`,
        codevalue: specialText
    };
}

// Helper functions
function findDishById(dishId) {
    for (const categoryKey in menuData.categories) {
        const category = menuData.categories[categoryKey];
        if (category.dishes) {
            const dish = category.dishes.find(d => d.id === dishId);
            if (dish) return dish;
        }
    }
    return null;
}

function getTodaySpecials() {
    const today = new Date().toISOString().split('T')[0];
    const specials = [];
    
    for (const specialKey in menuData.specials) {
        const special = menuData.specials[specialKey];
        if (special.validUntil >= today) {
            specials.push(special);
        }
    }
    
    return specials;
}

function initializeSampleData() {
    // Create sample menu data
    menuData = {
        categories: {
            appetizers: {
                name: 'Appetizers',
                description: 'Start your meal with our delicious appetizers',
                dishes: [
                    {
                        id: '001',
                        name: 'Bruschetta Trio',
                        price: '12.99',
                        description: 'Three varieties of our signature bruschetta',
                        ingredients: ['Tomatoes', 'Basil', 'Mozzarella', 'Balsamic'],
                        allergens: ['Gluten', 'Dairy'],
                        prepTime: '10-15',
                        available: true,
                        dietary: ['vegetarian']
                    }
                ]
            },
            mains: {
                name: 'Main Courses',
                description: 'Our chef\'s signature main dishes',
                dishes: [
                    {
                        id: '101',
                        name: 'Grilled Salmon',
                        price: '24.99',
                        description: 'Fresh Atlantic salmon with seasonal vegetables',
                        ingredients: ['Salmon', 'Asparagus', 'Lemon', 'Herbs'],
                        allergens: ['Fish'],
                        prepTime: '20-25',
                        available: true,
                        dietary: ['gluten-free', 'keto'],
                        nutrition: {
                            calories: 420,
                            protein: 35,
                            carbs: 8,
                            fat: 28
                        }
                    }
                ]
            }
        },
        specials: {
            '001': {
                name: 'Happy Hour Special',
                price: '15.99',
                originalPrice: '22.99',
                description: 'Any appetizer + drink combo',
                validUntil: '2024-12-31',
                conditions: 'Available 4-6 PM weekdays'
            }
        },
        tables: {
            'table_1': {
                serverName: 'Sarah',
                section: 'A'
            },
            'table_2': {
                serverName: 'Mike',
                section: 'B'
            }
        }
    };

    restaurantConfig = {
        name: 'Bella Vista Restaurant',
        welcomeMessage: 'Welcome to Bella Vista! Scan dish QR codes for detailed information.',
        currency: 'USD',
        timezone: 'America/New_York'
    };

    // Save sample data
    fs.writeFileSync(path.join(__dirname, 'menu-data.json'), JSON.stringify(menuData, null, 2));
    fs.writeFileSync(path.join(__dirname, 'restaurant-config.json'), JSON.stringify(restaurantConfig, null, 2));
}

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok',
        restaurant: restaurantConfig.name,
        menuItems: Object.keys(menuData.categories || {}).length,
        timestamp: new Date().toISOString()
    });
});

// Menu management endpoints (for admin use)
app.get('/admin/menu', (req, res) => {
    res.json(menuData);
});

app.post('/admin/menu/reload', (req, res) => {
    try {
        menuData = JSON.parse(fs.readFileSync(path.join(__dirname, 'menu-data.json'), 'utf8'));
        restaurantConfig = JSON.parse(fs.readFileSync(path.join(__dirname, 'restaurant-config.json'), 'utf8'));
        res.json({ status: 'Menu reloaded successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to reload menu data' });
    }
});

// Start server
app.listen(port, () => {
    console.log(`Restaurant Menu Webhook server running on port ${port}`);
    console.log(`Webhook URL: http://localhost:${port}/webhook`);
    console.log(`Health check: http://localhost:${port}/health`);
    console.log(`Admin menu: http://localhost:${port}/admin/menu`);
});

module.exports = app;
