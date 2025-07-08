#!/usr/bin/env python3
"""
AllCodeRelay Event Check-in Webhook

A Flask-based webhook for managing event attendee check-ins via QR code scanning.

Features:
- Attendee registration and check-in
- Real-time attendance tracking
- Access level management
- Event statistics
- Multiple event support

Setup Instructions:
1. Install dependencies: pip install flask sqlite3 qrcode[pil] python-dotenv
2. Configure environment variables (see .env.example)
3. Initialize database: python event-checkin-webhook.py --init-db
4. Start server: python event-checkin-webhook.py
"""

from flask import Flask, request, jsonify, render_template_string
import sqlite3
import json
import datetime
import hashlib
import qrcode
import io
import base64
import os
from dotenv import load_dotenv
import logging

# Load environment variables
load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'your-secret-key-here')

# Database configuration
DB_PATH = os.getenv('DB_PATH', 'events.db')

# Logging setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def init_database():
    """Initialize the SQLite database with required tables."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Events table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            start_date DATETIME NOT NULL,
            end_date DATETIME NOT NULL,
            location TEXT,
            max_attendees INTEGER,
            is_active BOOLEAN DEFAULT 1,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Attendees table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS attendees (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_id INTEGER NOT NULL,
            qr_code TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            email TEXT,
            phone TEXT,
            access_level TEXT DEFAULT 'general',
            registration_date DATETIME DEFAULT CURRENT_TIMESTAMP,
            check_in_time DATETIME,
            is_checked_in BOOLEAN DEFAULT 0,
            notes TEXT,
            FOREIGN KEY (event_id) REFERENCES events (id)
        )
    ''')
    
    # Check-in logs table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS checkin_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            attendee_id INTEGER NOT NULL,
            action TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            ip_address TEXT,
            user_agent TEXT,
            FOREIGN KEY (attendee_id) REFERENCES attendees (id)
        )
    ''')
    
    conn.commit()
    conn.close()
    logger.info("Database initialized successfully")

def get_db_connection():
    """Get database connection with row factory."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def generate_qr_code(attendee_id):
    """Generate a unique QR code for an attendee."""
    # Create a unique hash based on attendee ID and timestamp
    timestamp = datetime.datetime.now().isoformat()
    data = f"{attendee_id}:{timestamp}"
    qr_hash = hashlib.sha256(data.encode()).hexdigest()[:16]
    return f"EVENT_CHECKIN_{qr_hash.upper()}"

@app.route('/webhook', methods=['POST'])
def webhook():
    """Main webhook endpoint for AllCodeRelay."""
    try:
        data = request.get_json()
        if not data or 'code' not in data:
            return jsonify({
                'code': 'ERROR',
                'codevalue': 'Invalid request format'
            }), 400

        qr_code = data['code'].strip()
        logger.info(f"Received QR code: {qr_code}")

        # Check if this is an event check-in code
        if not qr_code.startswith('EVENT_CHECKIN_'):
            return jsonify({
                'code': qr_code,
                'codevalue': '❓ This QR code is not recognized as an event check-in code.\n\nPlease ensure you have a valid event ticket.'
            })

        # Look up attendee by QR code
        conn = get_db_connection()
        attendee = conn.execute('''
            SELECT a.*, e.name as event_name, e.location, e.start_date, e.end_date, e.is_active
            FROM attendees a
            JOIN events e ON a.event_id = e.id
            WHERE a.qr_code = ?
        ''', (qr_code,)).fetchone()

        if not attendee:
            conn.close()
            return jsonify({
                'code': qr_code,
                'codevalue': '❌ Invalid ticket!\n\nThis QR code is not registered for any event.\n\nPlease contact event organizers.'
            })

        # Check if event is active
        if not attendee['is_active']:
            conn.close()
            return jsonify({
                'code': qr_code,
                'codevalue': f'⚠️ Event Inactive\n\n{attendee["event_name"]}\n\nThis event is currently inactive.\nPlease contact organizers.'
            })

        # Check event timing
        now = datetime.datetime.now()
        start_date = datetime.datetime.fromisoformat(attendee['start_date'])
        end_date = datetime.datetime.fromisoformat(attendee['end_date'])

        if now < start_date:
            time_until = start_date - now
            hours_until = int(time_until.total_seconds() // 3600)
            conn.close()
            return jsonify({
                'code': qr_code,
                'codevalue': f'⏰ Event Not Started\n\n{attendee["event_name"]}\n\nEvent starts in {hours_until} hours.\nPlease return at the scheduled time.'
            })

        if now > end_date:
            conn.close()
            return jsonify({
                'code': qr_code,
                'codevalue': f'⏰ Event Ended\n\n{attendee["event_name"]}\n\nThis event has already ended.\nThank you for your interest!'
            })

        # Process check-in
        if attendee['is_checked_in']:
            # Already checked in
            check_in_time = datetime.datetime.fromisoformat(attendee['check_in_time'])
            formatted_time = check_in_time.strftime('%H:%M on %b %d')
            
            response_message = f"✅ Already Checked In\n\n" \
                             f"👤 {attendee['name']}\n" \
                             f"🎫 {attendee['event_name']}\n" \
                             f"📍 {attendee['location']}\n" \
                             f"⏰ Checked in: {formatted_time}\n" \
                             f"🎯 Access: {attendee['access_level'].title()}"
        else:
            # Perform check-in
            check_in_time = now.isoformat()
            conn.execute('''
                UPDATE attendees 
                SET is_checked_in = 1, check_in_time = ?
                WHERE id = ?
            ''', (check_in_time, attendee['id']))

            # Log the check-in
            conn.execute('''
                INSERT INTO checkin_logs (attendee_id, action, ip_address, user_agent)
                VALUES (?, 'check_in', ?, ?)
            ''', (attendee['id'], request.remote_addr, request.headers.get('User-Agent', '')))

            conn.commit()

            formatted_time = now.strftime('%H:%M')
            response_message = f"🎉 Welcome!\n\n" \
                             f"👤 {attendee['name']}\n" \
                             f"🎫 {attendee['event_name']}\n" \
                             f"📍 {attendee['location']}\n" \
                             f"⏰ Checked in: {formatted_time}\n" \
                             f"🎯 Access: {attendee['access_level'].title()}\n\n" \
                             f"Enjoy the event! 🎊"

        conn.close()

        return jsonify({
            'code': qr_code,
            'codevalue': response_message
        })

    except Exception as e:
        logger.error(f"Webhook error: {str(e)}")
        return jsonify({
            'code': request.json.get('code', 'ERROR') if request.json else 'ERROR',
            'codevalue': '❌ System error occurred.\n\nPlease try again or contact support.'
        }), 500

@app.route('/admin/events')
def list_events():
    """Admin endpoint to list all events."""
    conn = get_db_connection()
    events = conn.execute('''
        SELECT e.*, 
               COUNT(a.id) as total_attendees,
               COUNT(CASE WHEN a.is_checked_in = 1 THEN 1 END) as checked_in_count
        FROM events e
        LEFT JOIN attendees a ON e.id = a.event_id
        GROUP BY e.id
        ORDER BY e.start_date DESC
    ''').fetchall()
    conn.close()

    events_list = []
    for event in events:
        events_list.append({
            'id': event['id'],
            'name': event['name'],
            'start_date': event['start_date'],
            'location': event['location'],
            'total_attendees': event['total_attendees'],
            'checked_in': event['checked_in_count'],
            'is_active': bool(event['is_active'])
        })

    return jsonify(events_list)

@app.route('/admin/event/<int:event_id>/attendees')
def list_attendees(event_id):
    """Admin endpoint to list attendees for an event."""
    conn = get_db_connection()
    attendees = conn.execute('''
        SELECT * FROM attendees 
        WHERE event_id = ?
        ORDER BY registration_date DESC
    ''', (event_id,)).fetchall()
    conn.close()

    attendees_list = []
    for attendee in attendees:
        attendees_list.append({
            'id': attendee['id'],
            'name': attendee['name'],
            'email': attendee['email'],
            'qr_code': attendee['qr_code'],
            'access_level': attendee['access_level'],
            'is_checked_in': bool(attendee['is_checked_in']),
            'check_in_time': attendee['check_in_time'],
            'registration_date': attendee['registration_date']
        })

    return jsonify(attendees_list)

@app.route('/admin/stats/<int:event_id>')
def event_stats(event_id):
    """Get real-time statistics for an event."""
    conn = get_db_connection()
    
    # Basic stats
    stats = conn.execute('''
        SELECT 
            COUNT(*) as total_registered,
            COUNT(CASE WHEN is_checked_in = 1 THEN 1 END) as total_checked_in,
            COUNT(CASE WHEN access_level = 'vip' THEN 1 END) as vip_count,
            COUNT(CASE WHEN access_level = 'speaker' THEN 1 END) as speaker_count
        FROM attendees 
        WHERE event_id = ?
    ''', (event_id,)).fetchone()

    # Hourly check-in distribution
    hourly_checkins = conn.execute('''
        SELECT 
            strftime('%H', check_in_time) as hour,
            COUNT(*) as count
        FROM attendees 
        WHERE event_id = ? AND is_checked_in = 1
        GROUP BY strftime('%H', check_in_time)
        ORDER BY hour
    ''', (event_id,)).fetchall()

    conn.close()

    return jsonify({
        'total_registered': stats['total_registered'],
        'total_checked_in': stats['total_checked_in'],
        'check_in_rate': round((stats['total_checked_in'] / max(stats['total_registered'], 1)) * 100, 1),
        'vip_count': stats['vip_count'],
        'speaker_count': stats['speaker_count'],
        'hourly_checkins': [{'hour': row['hour'], 'count': row['count']} for row in hourly_checkins]
    })

@app.route('/health')
def health_check():
    """Health check endpoint."""
    try:
        conn = get_db_connection()
        conn.execute('SELECT 1').fetchone()
        conn.close()
        return jsonify({
            'status': 'healthy',
            'database': 'connected',
            'timestamp': datetime.datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': datetime.datetime.now().isoformat()
        }), 500

if __name__ == '__main__':
    import sys
    
    if '--init-db' in sys.argv:
        init_database()
        print("Database initialized successfully!")
        sys.exit(0)
    
    # Initialize database if it doesn't exist
    if not os.path.exists(DB_PATH):
        init_database()
    
    # Run the Flask app
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_ENV') == 'development'
    
    print(f"Starting Event Check-in Webhook on port {port}")
    print(f"Webhook URL: http://localhost:{port}/webhook")
    print(f"Admin panel: http://localhost:{port}/admin/events")
    
    app.run(host='0.0.0.0', port=port, debug=debug)
