# 🎫 Event Check-in Webhook

A comprehensive Python Flask webhook for managing event attendee check-ins via QR code scanning with AllCodeRelay.

## Features

- ✅ **Real-time Check-in**: Instant attendee verification and check-in
- 🎫 **QR Code Management**: Unique QR codes for each attendee
- 📊 **Live Statistics**: Real-time attendance tracking and analytics
- 🔐 **Access Control**: Multiple access levels (General, VIP, Speaker)
- 📱 **Mobile-Friendly**: Optimized for mobile scanning workflows
- 🕒 **Event Timing**: Automatic event start/end time validation
- 📈 **Admin Dashboard**: Web-based event management interface
- 🔍 **Audit Trail**: Complete check-in activity logging

## Quick Start

### 1. Installation

```bash
# Clone or download the files
cd event-checkin-webhook

# Install Python dependencies
pip install -r requirements.txt

# Copy environment configuration
cp .env.example .env
```

### 2. Database Setup

```bash
# Initialize the database
python event-checkin-webhook.py --init-db

# (Optional) Add sample data for testing
python sample_data.py
```

### 3. Configuration

Edit `.env` file with your settings:

```env
FLASK_ENV=development
SECRET_KEY=your-super-secret-key
PORT=5000
DB_PATH=events.db
```

### 4. Start the Server

```bash
# Development mode
python event-checkin-webhook.py

# Production mode with Gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 event-checkin-webhook:app
```

### 5. Configure AllCodeRelay

Use the [configuration tool](../../webhook_config.php) to generate a QR code with your webhook URL:
`http://your-server:5000/webhook`

## Usage Examples

### Successful Check-in

When scanning a valid event QR code:

```
🎉 Welcome!

👤 John Smith
🎫 Tech Conference 2024
📍 Convention Center, Hall A
⏰ Checked in: 14:30
🎯 Access: General

Enjoy the event! 🎊
```

### Already Checked In

For attendees who scan again:

```
✅ Already Checked In

👤 John Smith
🎫 Tech Conference 2024
📍 Convention Center, Hall A
⏰ Checked in: 14:30 on Dec 15
🎯 Access: General
```

### Event Not Started

For early arrivals:

```
⏰ Event Not Started

Tech Conference 2024

Event starts in 3 hours.
Please return at the scheduled time.
```

## Database Schema

### Events Table

- `id` - Unique event identifier
- `name` - Event name
- `start_date` / `end_date` - Event timing
- `location` - Event venue
- `max_attendees` - Capacity limit
- `is_active` - Event status

### Attendees Table

- `qr_code` - Unique QR code identifier
- `name` / `email` / `phone` - Contact information
- `access_level` - Permission level
- `is_checked_in` - Check-in status
- `check_in_time` - Timestamp of check-in

### Check-in Logs Table

- `attendee_id` - Reference to attendee
- `action` - Type of action performed
- `timestamp` - When action occurred
- `ip_address` - Source IP for audit

## API Endpoints

### Webhook Endpoint

- **POST** `/webhook` - Main AllCodeRelay webhook
- **Body**: `{"code": "EVENT_CHECKIN_XXXXXXXX"}`

### Admin Endpoints

- **GET** `/admin/events` - List all events with statistics
- **GET** `/admin/event/<id>/attendees` - List attendees for event
- **GET** `/admin/stats/<id>` - Real-time event statistics

### Utility Endpoints

- **GET** `/health` - Health check and database status

## Access Levels

### General Access

- Standard event attendee
- Basic event access
- Default level for most attendees

### VIP Access

- Premium attendee status
- Special privileges and areas
- Priority support

### Speaker Access

- Event presenters and speakers
- Backstage and speaker areas
- Technical support access

## Event Management

### Creating Events

Add events directly to the database or extend the webhook with admin endpoints:

```sql
INSERT INTO events (name, description, start_date, end_date, location, max_attendees)
VALUES ('My Event', 'Event description', '2024-12-20 09:00:00', '2024-12-20 17:00:00', 'Venue Name', 100);
```

### Registering Attendees

```sql
INSERT INTO attendees (event_id, qr_code, name, email, access_level)
VALUES (1, 'EVENT_CHECKIN_ABC123', 'John Doe', 'john@email.com', 'general');
```

### QR Code Generation

The system automatically generates unique QR codes using the format:
`EVENT_CHECKIN_[16-character-hash]`

## Real-time Statistics

### Event Dashboard Data

```json
{
  "total_registered": 150,
  "total_checked_in": 89,
  "check_in_rate": 59.3,
  "vip_count": 12,
  "speaker_count": 8,
  "hourly_checkins": [
    { "hour": "09", "count": 25 },
    { "hour": "10", "count": 34 },
    { "hour": "11", "count": 30 }
  ]
}
```

### Live Monitoring

Monitor check-ins in real-time by polling the stats endpoint or implementing WebSocket connections for instant updates.

## Advanced Features

### Email Notifications

Configure SMTP settings in `.env` to send check-in confirmations:

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

### Slack Integration

Get real-time notifications in Slack:

```env
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

### Custom Access Levels

Extend the system with custom access levels:

```python
# Add to the webhook code
CUSTOM_ACCESS_LEVELS = {
    'staff': {'name': 'Staff', 'icon': '👨‍💼'},
    'media': {'name': 'Media', 'icon': '📸'},
    'vendor': {'name': 'Vendor', 'icon': '🏪'}
}
```

## Security Considerations

1. **Database Security**: Use strong passwords and limit access
2. **HTTPS**: Always use HTTPS in production
3. **Rate Limiting**: Implement rate limiting to prevent abuse
4. **Input Validation**: All inputs are validated and sanitized
5. **Audit Logging**: Complete activity trail for security review

## Troubleshooting

### Common Issues

1. **Database Connection Failed**

   - Check if `events.db` exists and is writable
   - Run `python event-checkin-webhook.py --init-db`

2. **QR Code Not Recognized**

   - Ensure QR code starts with `EVENT_CHECKIN_`
   - Check if attendee exists in database
   - Verify event is active

3. **Event Timing Issues**
   - Check system timezone settings
   - Verify event start/end dates in database
   - Consider timezone differences

### Debug Mode

Enable Flask debug mode for detailed error messages:

```env
FLASK_ENV=development
```

### Testing

Test the webhook without AllCodeRelay:

```bash
curl -X POST http://localhost:5000/webhook \
  -H "Content-Type: application/json" \
  -d '{"code": "EVENT_CHECKIN_ABC123"}'
```

## Deployment

### Production Deployment

```bash
# Install production server
pip install gunicorn

# Run with Gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 event-checkin-webhook:app

# Or use systemd service
sudo systemctl start event-checkin-webhook
```

### Docker Deployment

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "event-checkin-webhook:app"]
```

### Environment Variables for Production

```env
FLASK_ENV=production
SECRET_KEY=your-production-secret-key
DB_PATH=/data/events.db
PORT=5000
```

## Integration Examples

### Event Registration System

Integrate with existing registration systems by importing attendee data:

```python
# Import from CSV
import csv
with open('attendees.csv', 'r') as file:
    reader = csv.DictReader(file)
    for row in reader:
        # Create attendee with generated QR code
        create_attendee(row['name'], row['email'], event_id)
```

### Payment Integration

Link with payment systems to automatically register paid attendees:

```python
# Webhook from payment processor
@app.route('/payment-webhook', methods=['POST'])
def payment_webhook():
    # Verify payment and create attendee
    if payment_verified:
        create_attendee_from_payment(payment_data)
```

## License

This example is provided as-is for educational and commercial use.
