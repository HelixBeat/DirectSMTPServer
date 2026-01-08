#!/usr/bin/env python3
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def test_port_587():
    """Test port 587 which should be working"""
    try:
        print("=== Testing Port 587 (Mail Submission) ===")
        
        server = smtplib.SMTP("direct.if-else.click", 587)
        server.set_debuglevel(1)  # Show full SMTP conversation
        
        print("✅ Connected to direct.if-else.click:587")
        
        # Use compatible SSL context
        context = ssl.create_default_context()
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        
        server.starttls(context=context)
        print("✅ STARTTLS successful")
        
        # Create test email
        msg = MIMEMultipart()
        msg['From'] = "test@if-else.click"
        msg['To'] = "recipient@direct.if-else.click"
        msg['Subject'] = "Test Email via Port 587"
        
        body = "This email was sent via port 587 (mail submission port)!"
        msg.attach(MIMEText(body, 'plain'))
        
        # Send email
        server.sendmail("test@if-else.click", "recipient@direct.if-else.click", msg.as_string())
        server.quit()
        
        print("✅ Email sent successfully via port 587!")
        return True
        
    except Exception as e:
        print(f"❌ Port 587 failed: {e}")
        return False

if __name__ == "__main__":
    print("=== Testing DirectSMTP Server Port 587 ===")
    
    success = test_port_587()
    
    if success:
        print("\n🎉 Port 587 is working correctly!")
        print("📧 Port 587: Mail submission (TLS required)")
        print("\nNote: Port 25 may be blocked by AWS/ISP policies.")
        print("Port 587 is the standard mail submission port and should work for most clients.")
    else:
        print("\n⚠️  Port 587 failed - check server configuration")