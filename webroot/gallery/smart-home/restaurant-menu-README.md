# 🍽️ Smart Restaurant Menu Webhook

Transform your restaurant experience with interactive QR code menus! This Node.js webhook provides detailed dish information, allergen alerts, and personalized dining experiences through AllCodeRelay.

## Features

- 🍽️ **Interactive Menus**: Detailed dish information with ingredients and nutrition
- 🏷️ **QR Code Types**: Table menus, individual dishes, categories, and specials
- 🌶️ **Allergen Alerts**: Clear allergen and dietary information
- 🥗 **Nutritional Info**: Calories, macros, and dietary classifications
- 🌍 **Multilingual Ready**: Easy to extend for multiple languages
- ⭐ **Daily Specials**: Dynamic special offers and promotions
- 👨‍🍳 **Server Integration**: Table assignments and service information
- 📱 **Mobile Optimized**: Perfect for smartphone scanning

## Quick Start

### 1. Installation

```bash
# Clone or download the files
cd restaurant-menu-webhook

# Install dependencies
npm install

# Copy environment configuration
cp .env.example .env
```

### 2. Configuration

Edit `.env` file with your settings:

```env
PORT=3001
RESTAURANT_NAME="Your Restaurant Name"
CURRENCY=USD
TIMEZONE=America/New_York
```

### 3. Customize Menu Data

Edit `menu-data.json` and `restaurant-config.json` with your actual menu items, or let the system create sample data on first run.

### 4. Start the Server

```bash
# Production
npm start

# Development (with auto-reload)
npm run dev
```

### 5. Generate QR Codes

Create QR codes for your restaurant using these formats:

- `TABLE_01` - Table 1 menu
- `DISH_001` - Specific dish details
- `CAT_APPETIZERS` - Category menu
- `SPECIAL_001` - Special offer

Use the [AllCodeRelay configuration tool](../../webhook_config.php) to generate QR codes.

## QR Code Types

### Table Codes: `TABLE_XX`

Show table-specific welcome and menu overview:

```
🍽️ Bella Vista Restaurant
📍 Table 5

Welcome to Bella Vista! Scan dish QR codes for detailed information.

⭐ Today's Specials:
• Happy Hour Special - $15.99

📱 Scan dish QR codes for details
🔔 Call server: Press button on table
💳 Payment: Card/Cash/Mobile

👨‍🍳 Your server: Sarah
```

### Dish Codes: `DISH_XXX`

Detailed dish information:

```
🍽️ Grilled Salmon

💰 Price: $24.99
⏱️ Prep time: 20-25 min

📝 Fresh Atlantic salmon with seasonal vegetables

🥘 Ingredients:
Salmon, Asparagus, Lemon, Herbs

⚠️ Allergens: Fish

📊 Nutrition (per serving):
• Calories: 420
• Protein: 35g
• Carbs: 8g
• Fat: 28g

🏷️ Dietary: 🚫🌾 gluten-free 🥑 keto

✅ Available now
```

### Category Codes: `CAT_XXXXX`

Category menu listings:

```
📋 Appetizers

Start your meal with our delicious appetizers

✅ Bruschetta Trio - $12.99
   Three varieties of our signature bruschetta

✅ Calamari Rings - $14.99
   Crispy squid rings with marinara sauce

📱 Scan individual dish QR codes for full details
```

### Special Codes: `SPECIAL_XXX`

Special offers and promotions:

```
⭐ Happy Hour Special

💰 Special Price: $15.99 (Save $7.00!)

📝 Any appetizer + drink combo

⏰ Valid until: 2024-12-31
📋 Conditions: Available 4-6 PM weekdays

🍽️ Includes:
• Choice of appetizer
• House wine or beer
```

## Menu Data Structure

### Dish Object

```json
{
  "id": "001",
  "name": "Grilled Salmon",
  "price": "24.99",
  "description": "Fresh Atlantic salmon with seasonal vegetables",
  "ingredients": ["Salmon", "Asparagus", "Lemon", "Herbs"],
  "allergens": ["Fish"],
  "prepTime": "20-25",
  "available": true,
  "dietary": ["gluten-free", "keto"],
  "spiceLevel": 0,
  "nutrition": {
    "calories": 420,
    "protein": 35,
    "carbs": 8,
    "fat": 28
  },
  "recommendedWith": ["House Salad", "Garlic Bread"]
}
```

### Category Structure

```json
{
  "appetizers": {
    "name": "Appetizers",
    "description": "Start your meal with our delicious appetizers",
    "dishes": [...]
  }
}
```

### Special Offers

```json
{
  "001": {
    "name": "Happy Hour Special",
    "price": "15.99",
    "originalPrice": "22.99",
    "description": "Any appetizer + drink combo",
    "validUntil": "2024-12-31",
    "conditions": "Available 4-6 PM weekdays",
    "includes": ["Choice of appetizer", "House wine or beer"]
  }
}
```

## Dietary Classifications

The system supports these dietary indicators:

- 🥬 **Vegetarian** - No meat or fish
- 🌱 **Vegan** - No animal products
- 🚫🌾 **Gluten-Free** - No gluten-containing ingredients
- 🚫🥛 **Dairy-Free** - No dairy products
- 🥑 **Keto** - Low-carb, high-fat
- 🥗 **Low-Carb** - Reduced carbohydrate content

## Spice Level System

Rate dishes from 1-5 chili peppers:
- 🌶️ (1) - Mild
- 🌶️🌶️ (2) - Medium
- 🌶️🌶️🌶️ (3) - Hot
- 🌶️🌶️🌶️🌶️ (4) - Very Hot
- 🌶️🌶️🌶️🌶️🌶️ (5) - Extremely Hot

## Advanced Features

### Dynamic Menu Updates

Update menu items in real-time:

```javascript
// Update dish availability
app.post('/admin/dish/:id/availability', (req, res) => {
    const { available } = req.body;
    updateDishAvailability(req.params.id, available);
    res.json({ status: 'updated' });
});

// Update prices
app.post('/admin/dish/:id/price', (req, res) => {
    const { price } = req.body;
    updateDishPrice(req.params.id, price);
    res.json({ status: 'updated' });
});
```

### Multilingual Support

Extend for multiple languages:

```json
{
  "name": {
    "en": "Grilled Salmon",
    "es": "Salmón a la Parrilla",
    "fr": "Saumon Grillé"
  },
  "description": {
    "en": "Fresh Atlantic salmon with seasonal vegetables",
    "es": "Salmón atlántico fresco con verduras de temporada",
    "fr": "Saumon atlantique frais avec légumes de saison"
  }
}
```

### Integration with POS Systems

Connect with restaurant POS systems:

```javascript
// Send order to POS
app.post('/order', async (req, res) => {
    const { tableNumber, items } = req.body;
    
    // Send to POS system
    const orderResult = await sendToPOS({
        table: tableNumber,
        items: items,
        timestamp: new Date()
    });
    
    res.json(orderResult);
});
```

### Analytics and Insights

Track popular dishes and scanning patterns:

```javascript
// Log dish views
function logDishView(dishId, tableNumber) {
    const analytics = {
        dishId,
        tableNumber,
        timestamp: new Date(),
        action: 'view'
    };
    
    // Save to analytics database
    saveAnalytics(analytics);
}

// Generate reports
app.get('/admin/analytics/popular-dishes', (req, res) => {
    const popularDishes = getPopularDishes(req.query.period);
    res.json(popularDishes);
});
```

## API Endpoints

### Webhook Endpoint
- **POST** `/webhook` - Main AllCodeRelay webhook
- **Body**: `{"code": "TABLE_01"}`

### Admin Endpoints
- **GET** `/admin/menu` - Get complete menu data
- **POST** `/admin/menu/reload` - Reload menu from files

### Utility Endpoints
- **GET** `/health` - Health check and status

## Deployment

### Production Setup

```bash
# Install PM2 for process management
npm install -g pm2

# Start with PM2
pm2 start restaurant-menu-webhook.js --name "restaurant-menu"

# Set up auto-restart
pm2 startup
pm2 save
```

### Docker Deployment

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3001
CMD ["npm", "start"]
```

### Environment Variables

```env
PORT=3001
RESTAURANT_NAME="Your Restaurant Name"
CURRENCY=USD
TIMEZONE=America/New_York
ADMIN_PASSWORD=your_admin_password
```

## Customization Examples

### Adding Wine Pairing

```json
{
  "winePairing": {
    "wine": "Chardonnay",
    "description": "Crisp white wine that complements the salmon perfectly",
    "price": "8.99"
  }
}
```

### Chef's Recommendations

```json
{
  "chefNote": "Chef recommends cooking medium-rare for best flavor",
  "preparationStyle": ["Grilled", "Pan-seared", "Baked"]
}
```

### Seasonal Availability

```json
{
  "seasonal": true,
  "availableMonths": [3, 4, 5, 6, 7, 8, 9],
  "seasonalNote": "Available spring through fall"
}
```

## Security Considerations

1. **Input Validation**: All QR codes are validated and sanitized
2. **Rate Limiting**: Prevent abuse of menu endpoints
3. **Admin Authentication**: Secure admin endpoints
4. **Data Privacy**: No personal information stored

## Troubleshooting

### Common Issues

1. **Menu Data Not Loading**
   - Check if menu-data.json exists and is valid JSON
   - Verify file permissions
   - Check server logs for parsing errors

2. **QR Code Not Recognized**
   - Ensure QR code follows correct format
   - Check if dish/table exists in menu data
   - Verify case sensitivity

3. **Server Not Starting**
   - Check if port is already in use
   - Verify Node.js version compatibility
   - Check for missing dependencies

### Debug Mode

Enable detailed logging:

```env
NODE_ENV=development
DEBUG=restaurant:*
```

## License

This example is provided as-is for educational and commercial use.
