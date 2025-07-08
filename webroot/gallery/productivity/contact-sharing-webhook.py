#!/usr/bin/env python3
"""
AllCodeRelay Contact Sharing Webhook

A Flask-based webhook for sharing contact information via QR code scanning.

Features:
- vCard generation and parsing
- Contact validation and formatting
- Multiple contact formats support
- Bulk contact import
- Contact history tracking
- QR code generation for contacts

Setup Instructions:
1. Install dependencies: pip install flask qrcode[pil] vobject python-dotenv
2. Configure environment variables (see .env.example)
3. Start server: python contact-sharing-webhook.py
"""

from flask import Flask, request, jsonify, send_file
import json
import re
import io
import base64
import qrcode
import vobject
from datetime import datetime
import os
from dotenv import load_dotenv
import logging

# Load environment variables
load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'your-secret-key-here')

# Logging setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

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

        scanned_code = data['code'].strip()
        logger.info(f"Received contact code: {scanned_code}")

        # Determine the type of contact data
        contact_info = parse_contact_code(scanned_code)
        
        if not contact_info:
            return jsonify({
                'code': scanned_code,
                'codevalue': '❓ Unknown Contact Format\n\nThis QR code is not recognized as a contact.\n\nSupported formats:\n• vCard (BEGIN:VCARD)\n• Contact URLs\n• JSON contact data'
            })

        # Generate response based on contact type
        if contact_info['type'] == 'vcard':
            response = process_vcard(contact_info['data'], scanned_code)
        elif contact_info['type'] == 'json':
            response = process_json_contact(contact_info['data'], scanned_code)
        elif contact_info['type'] == 'url':
            response = process_contact_url(contact_info['data'], scanned_code)
        else:
            response = {
                'code': scanned_code,
                'codevalue': '❌ Unsupported contact format'
            }

        return jsonify(response)

    except Exception as e:
        logger.error(f"Webhook error: {str(e)}")
        return jsonify({
            'code': request.json.get('code', 'ERROR') if request.json else 'ERROR',
            'codevalue': '❌ Error processing contact.\n\nPlease try again or check the QR code format.'
        }), 500

def parse_contact_code(code):
    """Parse different types of contact codes."""
    
    # vCard format
    if code.startswith('BEGIN:VCARD'):
        return {
            'type': 'vcard',
            'data': code
        }
    
    # JSON format
    if code.startswith('{') and code.endswith('}'):
        try:
            contact_data = json.loads(code)
            return {
                'type': 'json',
                'data': contact_data
            }
        except json.JSONDecodeError:
            return None
    
    # URL format (contact sharing URLs)
    if code.startswith('http') and ('contact' in code.lower() or 'vcard' in code.lower()):
        return {
            'type': 'url',
            'data': code
        }
    
    # Simple contact format: NAME|PHONE|EMAIL
    if '|' in code:
        parts = code.split('|')
        if len(parts) >= 2:
            contact_data = {
                'name': parts[0],
                'phone': parts[1] if len(parts) > 1 else '',
                'email': parts[2] if len(parts) > 2 else '',
                'company': parts[3] if len(parts) > 3 else ''
            }
            return {
                'type': 'json',
                'data': contact_data
            }
    
    return None

def process_vcard(vcard_data, original_code):
    """Process vCard format contact data."""
    try:
        # Parse vCard
        vcard = vobject.readOne(vcard_data)
        
        # Extract contact information
        contact = extract_vcard_info(vcard)
        
        # Format response
        response_text = format_contact_response(contact)
        
        # Log the contact scan
        log_contact_scan(contact, 'vcard', original_code)
        
        return {
            'code': original_code,
            'codevalue': response_text
        }
        
    except Exception as e:
        logger.error(f"vCard parsing error: {str(e)}")
        return {
            'code': original_code,
            'codevalue': '❌ Invalid vCard format\n\nPlease check the QR code and try again.'
        }

def process_json_contact(contact_data, original_code):
    """Process JSON format contact data."""
    try:
        # Validate and normalize contact data
        contact = normalize_contact_data(contact_data)
        
        # Format response
        response_text = format_contact_response(contact)
        
        # Log the contact scan
        log_contact_scan(contact, 'json', original_code)
        
        return {
            'code': original_code,
            'codevalue': response_text
        }
        
    except Exception as e:
        logger.error(f"JSON contact processing error: {str(e)}")
        return {
            'code': original_code,
            'codevalue': '❌ Invalid contact data format\n\nPlease check the contact information and try again.'
        }

def process_contact_url(url, original_code):
    """Process contact URL (placeholder for URL fetching)."""
    # In a real implementation, you would fetch the contact data from the URL
    return {
        'code': original_code,
        'codevalue': f'🔗 Contact URL Detected\n\n{url}\n\n📱 Please visit this URL to add the contact to your device.'
    }

def extract_vcard_info(vcard):
    """Extract information from vCard object."""
    contact = {}
    
    # Name
    if hasattr(vcard, 'fn'):
        contact['name'] = str(vcard.fn.value)
    elif hasattr(vcard, 'n'):
        name_parts = vcard.n.value
        contact['name'] = f"{name_parts.given} {name_parts.family}".strip()
    
    # Phone numbers
    contact['phones'] = []
    if hasattr(vcard, 'tel_list'):
        for tel in vcard.tel_list:
            phone_type = 'Phone'
            if hasattr(tel, 'params') and 'TYPE' in tel.params:
                phone_type = tel.params['TYPE'][0].title()
            contact['phones'].append({
                'type': phone_type,
                'number': str(tel.value)
            })
    
    # Email addresses
    contact['emails'] = []
    if hasattr(vcard, 'email_list'):
        for email in vcard.email_list:
            email_type = 'Email'
            if hasattr(email, 'params') and 'TYPE' in email.params:
                email_type = email.params['TYPE'][0].title()
            contact['emails'].append({
                'type': email_type,
                'address': str(email.value)
            })
    
    # Organization
    if hasattr(vcard, 'org'):
        contact['company'] = str(vcard.org.value[0]) if vcard.org.value else ''
    
    # Title
    if hasattr(vcard, 'title'):
        contact['title'] = str(vcard.title.value)
    
    # Address
    if hasattr(vcard, 'adr_list'):
        for adr in vcard.adr_list:
            address_parts = [
                adr.value.street,
                adr.value.city,
                adr.value.region,
                adr.value.code,
                adr.value.country
            ]
            contact['address'] = ', '.join(filter(None, address_parts))
            break  # Use first address
    
    # Website
    if hasattr(vcard, 'url_list'):
        contact['website'] = str(vcard.url_list[0].value)
    
    # Notes
    if hasattr(vcard, 'note'):
        contact['notes'] = str(vcard.note.value)
    
    return contact

def normalize_contact_data(data):
    """Normalize contact data from various formats."""
    contact = {}
    
    # Name
    contact['name'] = data.get('name', data.get('full_name', data.get('fullName', '')))
    
    # Phone numbers
    contact['phones'] = []
    if 'phone' in data:
        contact['phones'].append({'type': 'Phone', 'number': data['phone']})
    if 'mobile' in data:
        contact['phones'].append({'type': 'Mobile', 'number': data['mobile']})
    if 'phones' in data:
        contact['phones'].extend(data['phones'])
    
    # Email addresses
    contact['emails'] = []
    if 'email' in data:
        contact['emails'].append({'type': 'Email', 'address': data['email']})
    if 'emails' in data:
        contact['emails'].extend(data['emails'])
    
    # Other fields
    contact['company'] = data.get('company', data.get('organization', ''))
    contact['title'] = data.get('title', data.get('job_title', ''))
    contact['address'] = data.get('address', '')
    contact['website'] = data.get('website', data.get('url', ''))
    contact['notes'] = data.get('notes', data.get('note', ''))
    
    return contact

def format_contact_response(contact):
    """Format contact information for display."""
    response_lines = []
    
    # Header
    if contact.get('name'):
        response_lines.append(f"👤 {contact['name']}")
    else:
        response_lines.append("👤 Contact Information")
    
    response_lines.append("")
    
    # Company and title
    if contact.get('company') or contact.get('title'):
        company_line = ""
        if contact.get('title'):
            company_line += contact['title']
        if contact.get('company'):
            if company_line:
                company_line += f" at {contact['company']}"
            else:
                company_line = contact['company']
        response_lines.append(f"🏢 {company_line}")
        response_lines.append("")
    
    # Phone numbers
    if contact.get('phones'):
        for phone in contact['phones']:
            phone_icon = "📱" if phone['type'].lower() in ['mobile', 'cell'] else "📞"
            response_lines.append(f"{phone_icon} {phone['type']}: {phone['number']}")
    
    # Email addresses
    if contact.get('emails'):
        for email in contact['emails']:
            response_lines.append(f"📧 {email['type']}: {email['address']}")
    
    # Website
    if contact.get('website'):
        response_lines.append(f"🌐 Website: {contact['website']}")
    
    # Address
    if contact.get('address'):
        response_lines.append(f"📍 Address: {contact['address']}")
    
    # Notes
    if contact.get('notes'):
        response_lines.append("")
        response_lines.append(f"📝 Notes: {contact['notes']}")
    
    # Footer
    response_lines.append("")
    response_lines.append("✅ Contact information scanned successfully!")
    response_lines.append("📱 Save to your contacts app")
    
    return "\n".join(response_lines)

def log_contact_scan(contact, format_type, original_code):
    """Log contact scanning activity."""
    try:
        log_entry = {
            'timestamp': datetime.now().isoformat(),
            'contact_name': contact.get('name', 'Unknown'),
            'format_type': format_type,
            'ip_address': request.remote_addr,
            'user_agent': request.headers.get('User-Agent', ''),
            'original_code_length': len(original_code)
        }
        
        # In a real implementation, save to database or log file
        logger.info(f"Contact scan logged: {log_entry}")
        
    except Exception as e:
        logger.error(f"Failed to log contact scan: {str(e)}")

@app.route('/generate-vcard', methods=['POST'])
def generate_vcard():
    """Generate a vCard from contact data."""
    try:
        data = request.get_json()
        
        # Create vCard
        vcard = vobject.vCard()
        
        # Add name
        if data.get('name'):
            vcard.add('fn')
            vcard.fn.value = data['name']
            
            # Split name for structured name field
            name_parts = data['name'].split(' ', 1)
            vcard.add('n')
            vcard.n.value = vobject.vcard.Name(
                family=name_parts[1] if len(name_parts) > 1 else '',
                given=name_parts[0]
            )
        
        # Add phone
        if data.get('phone'):
            vcard.add('tel')
            vcard.tel.value = data['phone']
            vcard.tel.type_param = ['VOICE']
        
        # Add email
        if data.get('email'):
            vcard.add('email')
            vcard.email.value = data['email']
            vcard.email.type_param = ['INTERNET']
        
        # Add organization
        if data.get('company'):
            vcard.add('org')
            vcard.org.value = [data['company']]
        
        # Add title
        if data.get('title'):
            vcard.add('title')
            vcard.title.value = data['title']
        
        # Add URL
        if data.get('website'):
            vcard.add('url')
            vcard.url.value = data['website']
        
        vcard_string = vcard.serialize()
        
        return jsonify({
            'vcard': vcard_string,
            'qr_code_data': vcard_string
        })
        
    except Exception as e:
        logger.error(f"vCard generation error: {str(e)}")
        return jsonify({'error': 'Failed to generate vCard'}), 500

@app.route('/generate-qr', methods=['POST'])
def generate_qr():
    """Generate QR code for contact data."""
    try:
        data = request.get_json()
        qr_data = data.get('data', '')
        
        if not qr_data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Generate QR code
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=10,
            border=4,
        )
        qr.add_data(qr_data)
        qr.make(fit=True)
        
        # Create image
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Convert to base64
        img_buffer = io.BytesIO()
        img.save(img_buffer, format='PNG')
        img_buffer.seek(0)
        img_base64 = base64.b64encode(img_buffer.getvalue()).decode()
        
        return jsonify({
            'qr_code': f"data:image/png;base64,{img_base64}"
        })
        
    except Exception as e:
        logger.error(f"QR code generation error: {str(e)}")
        return jsonify({'error': 'Failed to generate QR code'}), 500

@app.route('/health')
def health_check():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'service': 'Contact Sharing Webhook',
        'timestamp': datetime.now().isoformat()
    })

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5001))
    debug = os.getenv('FLASK_ENV') == 'development'
    
    print(f"Starting Contact Sharing Webhook on port {port}")
    print(f"Webhook URL: http://localhost:{port}/webhook")
    print(f"Health check: http://localhost:{port}/health")
    
    app.run(host='0.0.0.0', port=port, debug=debug)
