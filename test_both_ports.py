#!/usr/bin/env python3
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def test_port(port, require_tls=False):
    """Test email sending to a specific port"""
    try:
        print(f"\n=== Testing Port {port} ===")
        
        server = smtplib.SMTP("direct.if-else.click", port)
        server.set_debuglevel(0)  # Reduce noise
        
        print(f"✅ Connected to direct.if-else.click:{port}")
        
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
        msg['Subject'] = f"Test Email via Port {port}"
        
        body = f"This email was sent via port {port}!"
        msg.attach(MIMEText(body, 'plain'))
        
        # Send email
        server.sendmail("test@if-else.click", "recipient@direct.if-else.click", msg.as_string())
        server.quit()
        
        print(f"✅ Email sent successfully via port {port}!")
        return True
        
    except Exception as e:
        print(f"❌ Port {port} failed: {e}")
        return False

def test_external_connectivity():
    """Test if ports are accessible from external networks"""
    import socket
    
    print("\n=== Testing External Connectivity ===")
    
    ports_to_test = [25, 587]
    
    for port in ports_to_test:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex(("direct.if-else.click", port))
            sock.close()
            
            if result == 0:
                print(f"✅ Port {port}: Externally accessible")
            else:
                print(f"❌ Port {port}: Not accessible (error code: {result})")
        except Exception as e:
            print(f"❌ Port {port}: Connection test failed - {e}")

if __name__ == "__main__":
    print("=== Testing DirectSMTP Server Ports ===")
    
    # Test external connectivity first
    test_external_connectivity()
    
    # Test both ports
    ports_to_test = [
        (25, False),   # Port 25: TLS optional
        (587, True),   # Port 587: TLS required
    ]
    
    results = {}
    for port, require_tls in ports_to_test:
        results[port] = test_port(port, require_tls)
    
    print("\n=== Test Summary ===")
    for port, success in results.items():
        status = "✅ WORKING" if success else "❌ FAILED"
        tls_info = "(TLS required)" if port == 587 else "(TLS optional)"
        print(f"Port {port} {tls_info}: {status}")
    
    if all(results.values()):
        print("\n🎉 Both ports are working correctly!")
        print("📧 Port 25: Standard SMTP (TLS optional)")
        print("📧 Port 587: Mail submission (TLS required)")
    else:
        print("\n⚠️  Some ports failed - check server configuration")