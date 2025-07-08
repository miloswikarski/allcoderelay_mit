#!/usr/bin/env python3
"""
Sample Data Generator for Event Check-in System

This script creates sample events and attendees for testing the event check-in webhook.
Run this after initializing the database to populate it with test data.

Usage:
    python sample_data.py
"""

import sqlite3
import datetime
import hashlib
import random

DB_PATH = 'events.db'

def generate_qr_code(attendee_id):
    """Generate a unique QR code for an attendee."""
    timestamp = datetime.datetime.now().isoformat()
    data = f"{attendee_id}:{timestamp}:{random.randint(1000, 9999)}"
    qr_hash = hashlib.sha256(data.encode()).hexdigest()[:16]
    return f"EVENT_CHECKIN_{qr_hash.upper()}"

def create_sample_data():
    """Create sample events and attendees."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Sample events
    events = [
        {
            'name': 'Tech Conference 2024',
            'description': 'Annual technology conference featuring the latest innovations',
            'start_date': (datetime.datetime.now() + datetime.timedelta(days=1)).isoformat(),
            'end_date': (datetime.datetime.now() + datetime.timedelta(days=2)).isoformat(),
            'location': 'Convention Center, Hall A',
            'max_attendees': 500,
            'is_active': 1
        },
        {
            'name': 'Startup Networking Event',
            'description': 'Connect with entrepreneurs and investors',
            'start_date': (datetime.datetime.now() + datetime.timedelta(days=7)).isoformat(),
            'end_date': (datetime.datetime.now() + datetime.timedelta(days=7, hours=4)).isoformat(),
            'location': 'Innovation Hub, Room 101',
            'max_attendees': 100,
            'is_active': 1
        },
        {
            'name': 'Workshop: AI & Machine Learning',
            'description': 'Hands-on workshop on AI and ML fundamentals',
            'start_date': (datetime.datetime.now() + datetime.timedelta(days=14)).isoformat(),
            'end_date': (datetime.datetime.now() + datetime.timedelta(days=14, hours=6)).isoformat(),
            'location': 'Tech Campus, Lab 3',
            'max_attendees': 50,
            'is_active': 1
        },
        {
            'name': 'Past Event - Demo',
            'description': 'This event has already ended (for testing)',
            'start_date': (datetime.datetime.now() - datetime.timedelta(days=7)).isoformat(),
            'end_date': (datetime.datetime.now() - datetime.timedelta(days=6)).isoformat(),
            'location': 'Demo Venue',
            'max_attendees': 200,
            'is_active': 0
        }
    ]

    # Insert events
    event_ids = []
    for event in events:
        cursor.execute('''
            INSERT INTO events (name, description, start_date, end_date, location, max_attendees, is_active)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (event['name'], event['description'], event['start_date'], 
              event['end_date'], event['location'], event['max_attendees'], event['is_active']))
        event_ids.append(cursor.lastrowid)

    # Sample attendees for each event
    attendee_templates = [
        {'name': 'John Smith', 'email': 'john.smith@email.com', 'phone': '+1234567890', 'access_level': 'general'},
        {'name': 'Sarah Johnson', 'email': 'sarah.j@email.com', 'phone': '+1234567891', 'access_level': 'vip'},
        {'name': 'Mike Chen', 'email': 'mike.chen@email.com', 'phone': '+1234567892', 'access_level': 'speaker'},
        {'name': 'Emily Davis', 'email': 'emily.davis@email.com', 'phone': '+1234567893', 'access_level': 'general'},
        {'name': 'David Wilson', 'email': 'david.w@email.com', 'phone': '+1234567894', 'access_level': 'general'},
        {'name': 'Lisa Brown', 'email': 'lisa.brown@email.com', 'phone': '+1234567895', 'access_level': 'vip'},
        {'name': 'Tom Anderson', 'email': 'tom.anderson@email.com', 'phone': '+1234567896', 'access_level': 'general'},
        {'name': 'Anna Martinez', 'email': 'anna.m@email.com', 'phone': '+1234567897', 'access_level': 'speaker'},
        {'name': 'Chris Taylor', 'email': 'chris.taylor@email.com', 'phone': '+1234567898', 'access_level': 'general'},
        {'name': 'Jessica Lee', 'email': 'jessica.lee@email.com', 'phone': '+1234567899', 'access_level': 'general'}
    ]

    # Create attendees for each event
    for i, event_id in enumerate(event_ids):
        # Number of attendees varies by event
        num_attendees = [25, 15, 12, 8][i] if i < 4 else 10
        
        for j in range(num_attendees):
            attendee = attendee_templates[j % len(attendee_templates)].copy()
            # Make names unique by adding event suffix
            attendee['name'] = f"{attendee['name']} (Event {i+1})"
            attendee['email'] = f"event{i+1}.{attendee['email']}"
            
            # Insert attendee first to get ID
            cursor.execute('''
                INSERT INTO attendees (event_id, qr_code, name, email, phone, access_level)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (event_id, 'TEMP', attendee['name'], attendee['email'], 
                  attendee['phone'], attendee['access_level']))
            
            attendee_id = cursor.lastrowid
            qr_code = generate_qr_code(attendee_id)
            
            # Update with actual QR code
            cursor.execute('''
                UPDATE attendees SET qr_code = ? WHERE id = ?
            ''', (qr_code, attendee_id))

            # Simulate some check-ins for the past event
            if i == 3:  # Past event
                if random.random() < 0.7:  # 70% check-in rate
                    check_in_time = (datetime.datetime.now() - datetime.timedelta(days=6, hours=random.randint(1, 8))).isoformat()
                    cursor.execute('''
                        UPDATE attendees 
                        SET is_checked_in = 1, check_in_time = ?
                        WHERE id = ?
                    ''', (check_in_time, attendee_id))

    conn.commit()
    conn.close()

    print("Sample data created successfully!")
    print(f"Created {len(events)} events with attendees")
    print("\nEvent Summary:")
    
    # Display summary
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    events_summary = cursor.execute('''
        SELECT e.name, COUNT(a.id) as attendee_count
        FROM events e
        LEFT JOIN attendees a ON e.id = a.event_id
        GROUP BY e.id
        ORDER BY e.start_date
    ''').fetchall()
    
    for event_name, count in events_summary:
        print(f"  - {event_name}: {count} attendees")
    
    # Show some sample QR codes
    print("\nSample QR codes for testing:")
    sample_codes = cursor.execute('''
        SELECT a.qr_code, a.name, e.name as event_name
        FROM attendees a
        JOIN events e ON a.event_id = e.id
        WHERE e.is_active = 1
        LIMIT 5
    ''').fetchall()
    
    for qr_code, attendee_name, event_name in sample_codes:
        print(f"  - {qr_code} ({attendee_name} - {event_name})")
    
    conn.close()

if __name__ == '__main__':
    create_sample_data()
