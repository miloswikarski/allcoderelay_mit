# 💰 Expense Tracking n8n Workflow

Automatically track expenses by scanning receipts and invoices with AllCodeRelay! This n8n workflow uses AI to parse receipt data and logs expenses to Google Sheets with Slack notifications.

## Features

- 🧾 **Receipt Recognition**: Automatically detects receipt URLs and QR codes
- 🤖 **AI-Powered Parsing**: Uses OpenAI to extract expense details
- 📊 **Google Sheets Integration**: Automatically logs expenses to spreadsheet
- 💬 **Slack Notifications**: Real-time expense alerts
- ✅ **Data Validation**: Ensures expense data quality
- 🔄 **Error Handling**: Graceful handling of invalid receipts

## Quick Start

### 1. Import Workflow

1. Download `expense-tracker.json`
2. Open your n8n instance
3. Go to **Workflows** → **Import from File**
4. Select the downloaded JSON file
5. Click **Import**

### 2. Configure Credentials

Set up the required service connections:

#### OpenAI API
1. Go to **Credentials** → **Add Credential**
2. Select **OpenAI**
3. Enter your OpenAI API key
4. Name it "OpenAI API"

#### Google Sheets
1. Go to **Credentials** → **Add Credential**
2. Select **Google Sheets OAuth2 API**
3. Follow OAuth setup process
4. Name it "Google Sheets"

#### Slack (Optional)
1. Go to **Credentials** → **Add Credential**
2. Select **Slack OAuth2 API**
3. Set up Slack app and OAuth
4. Name it "Slack"

### 3. Configure Google Sheets

1. Create a new Google Spreadsheet
2. Name the first sheet "Expenses"
3. Add these column headers in row 1:
   - Date
   - Merchant
   - Amount
   - Currency
   - Category
   - Items
   - Tax
   - Payment Method
   - Scan Time
   - Original Code

4. Copy the spreadsheet ID from the URL
5. Update the "Log to Google Sheets" node with your spreadsheet ID

### 4. Activate Workflow

1. Click **Active** toggle to enable the workflow
2. Note the webhook URL from the "Expense Webhook" node
3. Configure AllCodeRelay with this webhook URL

## How It Works

### Workflow Steps

1. **Webhook Receives Scan**: AllCodeRelay sends scanned code
2. **Data Extraction**: Extracts code and timestamp
3. **Receipt Detection**: Checks if code looks like a receipt/invoice
4. **Data Fetching**: Downloads receipt data if it's a URL
5. **AI Parsing**: OpenAI extracts structured expense data
6. **Validation**: Ensures required fields are present
7. **Logging**: Saves to Google Sheets and sends Slack notification
8. **Response**: Returns formatted response to AllCodeRelay

### Supported Receipt Types

- **QR Codes**: Receipt QR codes with embedded data
- **URLs**: Links to digital receipts
- **Invoice Links**: Online invoice pages
- **Receipt Apps**: Links from receipt scanning apps

## Usage Examples

### Scanning a Receipt QR Code

When you scan a receipt QR code:

```
💰 Expense Logged!

🏪 Starbucks Coffee
💵 $12.45 USD
📅 2024-12-15
🏷️ Food & Beverages

✅ Added to expense tracker
```

### Invalid Receipt

For non-receipt codes:

```
❓ Not a Receipt

This doesn't appear to be a receipt or invoice.

Please scan:
• Receipt QR codes
• Invoice URLs
• Digital receipt links
```

### Processing Error

If AI can't parse the receipt:

```
❌ Invalid Receipt

Missing required fields: merchant, amount

Please scan a valid receipt or invoice.
```

## Configuration Options

### AI Model Settings

In the "AI Receipt Parser" node, you can adjust:

```json
{
  "model": "gpt-4o-mini",
  "temperature": 0.1,
  "max_tokens": 1000
}
```

### Expense Categories

The AI automatically categorizes expenses, but you can customize categories by modifying the prompt:

```
Common categories:
- Food & Beverages
- Transportation
- Office Supplies
- Entertainment
- Travel
- Utilities
- Healthcare
- Shopping
```

### Slack Channel

Update the Slack notification node to post to your preferred channel:

```json
{
  "channel": "#expenses",
  "text": "Custom message format..."
}
```

## Google Sheets Output

The workflow creates entries with these fields:

| Field | Description | Example |
|-------|-------------|---------|
| Date | Transaction date | 2024-12-15 |
| Merchant | Store/vendor name | Starbucks Coffee |
| Amount | Total amount | 12.45 |
| Currency | Currency code | USD |
| Category | Expense category | Food & Beverages |
| Items | Purchased items | Coffee, Muffin |
| Tax | Tax amount | 1.12 |
| Payment Method | How paid | Credit Card |
| Scan Time | When scanned | 2024-12-15T14:30:00Z |
| Original Code | Raw scanned data | https://receipt.url |

## Advanced Features

### Custom Receipt Parsing

Modify the AI prompt to extract additional fields:

```
Extract these additional fields:
- "tip_amount": "tip amount as number"
- "receipt_number": "receipt/transaction ID"
- "cashier": "cashier name if available"
```

### Expense Approval Workflow

Extend the workflow to add approval steps:

1. Add "Set" node to mark expenses as "Pending"
2. Send approval request via email/Slack
3. Add webhook for approval responses
4. Update status in Google Sheets

### Budget Tracking

Add budget monitoring:

```javascript
// In a Code node after logging expense
const monthlyBudget = 1000;
const currentMonth = new Date().getMonth();

// Query Google Sheets for current month total
// Compare against budget
// Send alert if over budget
```

### Receipt Image Storage

Store receipt images in Google Drive:

1. Add "Google Drive" node
2. Upload receipt images
3. Add Drive link to Google Sheets

## Troubleshooting

### Common Issues

1. **OpenAI API Errors**
   - Check API key validity
   - Verify sufficient credits
   - Monitor rate limits

2. **Google Sheets Permission Denied**
   - Ensure OAuth credentials are valid
   - Check spreadsheet sharing permissions
   - Verify spreadsheet ID is correct

3. **Receipt Not Recognized**
   - Ensure receipt contains structured data
   - Check if URL is accessible
   - Verify receipt format is supported

4. **Slack Notifications Not Working**
   - Check Slack app permissions
   - Verify channel exists
   - Ensure bot is added to channel

### Debug Mode

Enable debug mode in n8n:

1. Go to **Settings** → **Log Level**
2. Set to "debug"
3. Check execution logs for detailed information

### Testing Without Receipts

Test the workflow with sample data:

```json
{
  "code": "https://example.com/sample-receipt"
}
```

## Integration Examples

### Expense Report Generation

Create monthly expense reports:

1. Add scheduled trigger (monthly)
2. Query Google Sheets for current month
3. Generate PDF report
4. Email to accounting team

### Multi-Currency Support

Handle international expenses:

1. Add currency conversion API
2. Convert all amounts to base currency
3. Store both original and converted amounts

### Tax Calculation

Automatically calculate tax deductions:

1. Categorize business vs personal expenses
2. Calculate deductible amounts
3. Generate tax summary reports

## Security Considerations

1. **API Keys**: Store securely in n8n credentials
2. **Data Privacy**: Ensure receipt data is handled securely
3. **Access Control**: Limit Google Sheets access
4. **Audit Trail**: Log all expense modifications

## Performance Optimization

1. **Batch Processing**: Group multiple receipts
2. **Caching**: Cache merchant categorizations
3. **Rate Limiting**: Respect API limits
4. **Error Retry**: Implement retry logic

## License

This workflow is provided as-is for educational and commercial use.
