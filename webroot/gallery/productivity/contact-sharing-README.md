# 📱 Contact Sharing Webhook

Share contact information instantly with QR codes! This Python Flask webhook enables seamless contact exchange through AllCodeRelay with support for vCard, JSON, and custom formats.

## Features

- ✅ **Multiple Formats**: vCard, JSON, URL, and custom pipe-delimited formats
- ✅ **vCard Support**: Full vCard 3.0/4.0 parsing and generation
- ✅ **Contact Validation**: Automatic data validation and formatting
- ✅ **QR Code Generation**: Create QR codes for any contact
- ✅ **Rich Display**: Formatted contact information with icons
- ✅ **Activity Logging**: Track contact sharing activity
- ✅ **Privacy Focused**: No unnecessary data storage
- ✅ **Mobile Optimized**: Perfect for smartphone workflows

## Quick Start

### 1. Installation

```bash
# Clone or download the files
cd contact-sharing-webhook

# Install Python dependencies
pip install -r requirements.txt

# Copy environment configuration
cp .env.example .env
```

### 2. Configuration

Edit `.env` file with your settings:

```env
FLASK_ENV=development
SECRET_KEY=your-super-secret-key
PORT=5001
```

### 3. Start the Server

```bash
# Development mode
python contact-sharing-webhook.py

# Production mode with Gunicorn
gunicorn -w 4 -b 0.0.0.0:5001 contact-sharing-webhook:app
```

### 4. Configure AllCodeRelay

Use the [configuration tool](../../webhook_config.php) to generate a QR code with your webhook URL:
`http://your-server:5001/webhook`

## Supported Contact Formats

### 1. vCard Format

Standard vCard format (most compatible):

```
BEGIN:VCARD
VERSION:3.0
FN:John Smith
N:Smith;John;;;
ORG:Acme Corporation
TITLE:Software Engineer
TEL;TYPE=VOICE:+1-555-123-4567
EMAIL;TYPE=INTERNET:john.smith@acme.com
URL:https://johnsmith.dev
END:VCARD
```

### 2. JSON Format

Structured JSON contact data:

```json
{
  "name": "John Smith",
  "company": "Acme Corporation",
  "title": "Software Engineer",
  "phone": "+1-555-123-4567",
  "email": "john.smith@acme.com",
  "website": "https://johnsmith.dev"
}
```

### 3. Pipe-Delimited Format

Simple format: `NAME|PHONE|EMAIL|COMPANY`

```
John Smith|+1-555-123-4567|john.smith@acme.com|Acme Corporation
```

### 4. Contact URLs

Links to contact sharing services:

```
https://contacts.example.com/share/john-smith
```

## Usage Examples

### vCard Contact

When scanning a vCard QR code:

```
👤 John Smith

🏢 Software Engineer at Acme Corporation

📱 Mobile: +1-555-123-4567
📧 Email: john.smith@acme.com
🌐 Website: https://johnsmith.dev

✅ Contact information scanned successfully!
📱 Save to your contacts app
```

### JSON Contact

For JSON format contacts:

```
👤 Sarah Johnson

🏢 Marketing Director at TechCorp

📞 Phone: +1-555-987-6543
📧 Email: sarah.j@techcorp.com
📍 Address: 123 Business St, City, State

📝 Notes: Met at Tech Conference 2024

✅ Contact information scanned successfully!
📱 Save to your contacts app
```

### Simple Format

For pipe-delimited contacts:

```
👤 Mike Chen

📱 Mobile: +1-555-456-7890
📧 Email: mike.chen@startup.io

✅ Contact information scanned successfully!
📱 Save to your contacts app
```

### Unknown Format

For unrecognized QR codes:

```
❓ Unknown Contact Format

This QR code is not recognized as a contact.

Supported formats:
• vCard (BEGIN:VCARD)
• Contact URLs
• JSON contact data
```

## API Endpoints

### Webhook Endpoint

- **POST** `/webhook` - Main AllCodeRelay webhook
- **Body**: `{"code": "BEGIN:VCARD..."}`

### Utility Endpoints

- **POST** `/generate-vcard` - Generate vCard from JSON data
- **POST** `/generate-qr` - Generate QR code for contact data
- **GET** `/health` - Health check and status

### Generate vCard Example

```bash
curl -X POST http://localhost:5001/generate-vcard \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Smith",
    "phone": "+1-555-123-4567",
    "email": "john@example.com",
    "company": "Acme Corp"
  }'
```

Response:

```json
{
  "vcard": "BEGIN:VCARD\nVERSION:3.0\n...",
  "qr_code_data": "BEGIN:VCARD\nVERSION:3.0\n..."
}
```

### Generate QR Code Example

```bash
curl -X POST http://localhost:5001/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"data": "BEGIN:VCARD\nVERSION:3.0\n..."}'
```

Response:

```json
{
  "qr_code": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA..."
}
```

## Contact Data Structure

### Complete Contact Object

```python
contact = {
    'name': 'John Smith',
    'phones': [
        {'type': 'Mobile', 'number': '+1-555-123-4567'},
        {'type': 'Work', 'number': '+1-555-987-6543'}
    ],
    'emails': [
        {'type': 'Personal', 'address': 'john@personal.com'},
        {'type': 'Work', 'address': 'john@company.com'}
    ],
    'company': 'Acme Corporation',
    'title': 'Software Engineer',
    'address': '123 Main St, City, State 12345',
    'website': 'https://johnsmith.dev',
    'notes': 'Met at Tech Conference 2024'
}
```

### Supported Phone Types

- Mobile/Cell
- Work
- Home
- Fax
- Pager

### Supported Email Types

- Personal
- Work
- Home
- Other

## Advanced Features

### Bulk Contact Import

Process multiple contacts from a single QR code:

```json
{
  "contacts": [
    {
      "name": "John Smith",
      "phone": "+1-555-123-4567",
      "email": "john@company.com"
    },
    {
      "name": "Jane Doe",
      "phone": "+1-555-987-6543",
      "email": "jane@company.com"
    }
  ]
}
```

### Contact Validation

The webhook automatically validates:

- Phone number formats
- Email address syntax
- Required fields (name, phone or email)
- Data size limits

### Privacy Features

- **No Storage**: Contacts are not stored by default
- **Anonymized Logs**: Personal data can be excluded from logs
- **Secure Processing**: All data is processed in memory only

### Integration Examples

#### CRM Integration

```python
def sync_to_crm(contact):
    """Sync contact to CRM system."""
    crm_data = {
        'first_name': contact['name'].split()[0],
        'last_name': ' '.join(contact['name'].split()[1:]),
        'email': contact['emails'][0]['address'] if contact['emails'] else '',
        'phone': contact['phones'][0]['number'] if contact['phones'] else '',
        'company': contact.get('company', ''),
        'title': contact.get('title', '')
    }

    # Send to CRM API
    response = requests.post(
        f"{CRM_API_URL}/contacts",
        headers={'Authorization': f'Bearer {CRM_API_KEY}'},
        json=crm_data
    )

    return response.json()
```

#### Email List Subscription

```python
def add_to_mailing_list(contact):
    """Add contact to email marketing list."""
    if contact.get('emails'):
        email = contact['emails'][0]['address']

        # Add to mailing list
        mailchimp_data = {
            'email_address': email,
            'status': 'subscribed',
            'merge_fields': {
                'FNAME': contact['name'].split()[0],
                'LNAME': ' '.join(contact['name'].split()[1:]),
                'COMPANY': contact.get('company', '')
            }
        }

        # Send to Mailchimp API
        # ... implementation
```

## Security Considerations

1. **Input Validation**: All contact data is validated and sanitized
2. **Rate Limiting**: Prevent abuse with configurable rate limits
3. **Data Privacy**: No unnecessary data storage or logging
4. **HTTPS Only**: Use HTTPS in production environments
5. **Access Control**: Optional authentication for admin endpoints

## Troubleshooting

### Common Issues

1. **vCard Parsing Failed**

   - Check vCard format syntax
   - Ensure proper line endings (CRLF)
   - Verify vCard version compatibility

2. **JSON Format Error**

   - Validate JSON syntax
   - Check for required fields
   - Ensure proper encoding

3. **QR Code Generation Failed**
   - Check data size limits
   - Verify image dependencies
   - Ensure sufficient memory

### Debug Mode

Enable detailed logging:

```env
FLASK_ENV=development
LOG_LEVEL=DEBUG
```

### Testing

Test the webhook without AllCodeRelay:

```bash
# Test vCard
curl -X POST http://localhost:5001/webhook \
  -H "Content-Type: application/json" \
  -d '{"code": "BEGIN:VCARD\nVERSION:3.0\nFN:Test User\nEND:VCARD"}'

# Test JSON
curl -X POST http://localhost:5001/webhook \
  -H "Content-Type: application/json" \
  -d '{"code": "{\"name\":\"Test User\",\"phone\":\"+1-555-123-4567\"}"}'
```

## Deployment

### Production Setup

```bash
# Install production server
pip install gunicorn

# Run with Gunicorn
gunicorn -w 4 -b 0.0.0.0:5001 contact-sharing-webhook:app

# Or use systemd service
sudo systemctl start contact-sharing-webhook
```

### Docker Deployment

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5001
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5001", "contact-sharing-webhook:app"]
```

### Environment Variables for Production

```env
FLASK_ENV=production
SECRET_KEY=your-production-secret-key
PORT=5001
LOG_LEVEL=INFO
ANONYMIZE_LOGS=true
```

## License

This example is provided as-is for educational and commercial use.
