#!/usr/bin/env python3
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def test_domain_acceptance(recipient_email, should_accept=True):
    """Test email sending to a specific email address"""
    try:
        print(f"\n=== Testing {recipient_email} ===")
        
        server = smtplib.SMTP("direct.if-else.click", 587)
        server.set_debuglevel(1)  # Show SMTP conversation
        
        # Use compatible SSL context
        context = ssl.create_default_context()
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        
        server.starttls(context=context)
        
        # Create test email
        msg = MIMEMultipart()
        msg['From'] = "test@if-else.click"
        msg['To'] = recipient_email
        msg['Subject'] = f"Test Email to {recipient_email}"
        
        body = f"This email was sent to test {recipient_email} acceptance!"
        msg.attach(MIMEText(body, 'plain'))
        
        # Send email
        server.sendmail("test@if-else.click", recipient_email, msg.as_string())
        server.quit()
        
        if should_accept:
            print(f"✅ Email sent successfully to {recipient_email} (as expected)!")
            return True
        else:
            print(f"⚠️  Email sent to {recipient_email} but should have been rejected!")
            return False
        
    except Exception as e:
        if should_accept:
            print(f"❌ Email sending to {recipient_email} failed unexpectedly: {e}")
            return False
        else:
            print(f"✅ Email to {recipient_email} was correctly rejected: {e}")
            return True

if __name__ == "__main__":
    print("=== Testing Domain Filtering ===")
    
    # Test cases: (email, should_accept)
    test_cases = [
        ("user@direct.if-else.click", True),
        ("admin@if-else.click", True),
        ("test@gmail.com", False),
        ("user@example.com", False),
        ("test@subdomain.if-else.click", False),  # Should be rejected - not exact match
    ]
    
    results = {}
    for email, should_accept in test_cases:
        results[email] = test_domain_acceptance(email, should_accept)
    
    print("\n=== Test Summary ===")
    for email, success in results.items():
        status = "✅ CORRECT" if success else "❌ INCORRECT"
        print(f"{email}: {status}")
    
    if all(results.values()):
        print("\n🎉 Domain filtering is working correctly!")
    else:
        print("\n⚠️  Some tests failed - check server configuration")