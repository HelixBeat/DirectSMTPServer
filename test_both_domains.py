#!/usr/bin/env python3
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def test_domain(recipient_domain):
    """Test email sending to a specific domain"""
    try:
        print(f"\n=== Testing {recipient_domain} ===")
        
        server = smtplib.SMTP("direct.if-else.click", 587)
        server.set_debuglevel(0)  # Reduce noise
        
        # Use compatible SSL context
        context = ssl.create_default_context()
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        
        server.starttls(context=context)
        
        # Create test email
        msg = MIMEMultipart()
        msg['From'] = "test@if-else.click"
        msg['To'] = f"recipient@{recipient_domain}"
        msg['Subject'] = f"Test Email to {recipient_domain}"
        
        body = f"This email was sent to test {recipient_domain} domain acceptance!"
        msg.attach(MIMEText(body, 'plain'))
        
        # Send email
        server.sendmail("test@if-else.click", f"recipient@{recipient_domain}", msg.as_string())
        server.quit()
        
        print(f"✅ Email sent successfully to {recipient_domain}!")
        return True
        
    except Exception as e:
        print(f"❌ Email sending to {recipient_domain} failed: {e}")
        return False

if __name__ == "__main__":
    print("=== Testing Both Domain Acceptance ===")
    
    # Test both domains
    domains_to_test = [
        "direct.if-else.click",
        "if-else.click"
    ]
    
    results = {}
    for domain in domains_to_test:
        results[domain] = test_domain(domain)
    
    print("\n=== Test Summary ===")
    for domain, success in results.items():
        status = "✅ ACCEPTED" if success else "❌ REJECTED"
        print(f"{domain}: {status}")
    
    if all(results.values()):
        print("\n🎉 Both domains are working correctly!")
    else:
        print("\n⚠️  Some domains failed - check server configuration")