#!/usr/bin/env python3
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def test_port(ip, port, require_tls=False):
    """Test email sending to a specific IP and port"""
    try:
        print(f"\n=== Testing {ip}:{port} ===")
        
        server = smtplib.SMTP(ip, port)
        server.set_debuglevel(1)  # Show SMTP conversation
        
        print(f"✅ Connected to {ip}:{port}")
        
        # Check EHLO response
        ehlo_response = server.ehlo()
        print(f"EHLO Response: {ehlo_response}")
        
        # Check if STARTTLS is available
        if server.has_extn('STARTTLS'):
            print("✅ STARTTLS is available")
            
            # Use compatible SSL context
            context = ssl.create_default_context()
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
            
            server.starttls(context=context)
            print("✅ STARTTLS successful")
            
            # Re-EHLO after STARTTLS
            server.ehlo()
        else:
            print("⚠️  STARTTLS not available")
            if require_tls:
                print("❌ TLS required but not available")
                server.quit()
                return False
        
        # Create test email
        msg = MIMEMultipart()
        msg['From'] = "test@if-else.click"
        msg['To'] = "recipient@direct.if-else.click"
        msg['Subject'] = f"Test Email via {ip}:{port}"
        
        body = f"This email was sent via {ip}:{port}!"
        msg.attach(MIMEText(body, 'plain'))
        
        # Send email
        server.sendmail("test@if-else.click", "recipient@direct.if-else.click", msg.as_string())
        server.quit()
        
        print(f"✅ Email sent successfully via {ip}:{port}!")
        return True
        
    except Exception as e:
        print(f"❌ {ip}:{port} failed: {e}")
        return False

if __name__ == "__main__":
    print("=== Testing DirectSMTP Server Direct IP ===")
    
    server_ip = "3.231.115.127"
    
    # Test both ports
    ports_to_test = [
        (25, False),   # Port 25: TLS optional
        (587, True),   # Port 587: TLS required
    ]
    
    results = {}
    for port, require_tls in ports_to_test:
        results[port] = test_port(server_ip, port, require_tls)
    
    print("\n=== Test Summary ===")
    for port, success in results.items():
        status = "✅ WORKING" if success else "❌ FAILED"
        tls_info = "(TLS required)" if port == 587 else "(TLS optional)"
        print(f"Port {port} {tls_info}: {status}")
    
    if all(results.values()):
        print(f"\n🎉 Both ports are working correctly on {server_ip}!")
        print("📧 Port 25: Standard SMTP (TLS optional)")
        print("📧 Port 587: Mail submission (TLS required)")
        print("\nNote: DNS caching may cause issues with domain name resolution.")
        print("Use the direct IP address if needed.")
    else:
        print("\n⚠️  Some ports failed - check server configuration")