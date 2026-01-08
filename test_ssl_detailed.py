#!/usr/bin/env python3
import smtplib
import ssl
import socket
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def test_ssl_versions():
    """Test different SSL/TLS versions"""
    server_host = "direct.if-else.click"
    port = 587
    
    versions = [
        ("TLS (default)", ssl.create_default_context()),
        ("TLS 1.2", ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)),
        ("TLS 1.3", ssl.SSLContext(ssl.PROTOCOL_TLS)),
    ]
    
    for version_name, context in versions:
        try:
            print(f"\n=== Testing {version_name} ===")
            
            # Disable certificate verification for testing
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
            
            server = smtplib.SMTP(server_host, port)
            server.set_debuglevel(0)  # Reduce noise
            
            print(f"✅ Connected to {server_host}:{port}")
            
            # Try STARTTLS
            server.starttls(context=context)
            print(f"✅ STARTTLS successful with {version_name}")
            
            # Test EHLO after STARTTLS
            server.ehlo()
            print(f"✅ EHLO after STARTTLS successful")
            
            server.quit()
            print(f"✅ {version_name} - ALL TESTS PASSED")
            return True
            
        except Exception as e:
            print(f"❌ {version_name} failed: {e}")
            try:
                server.quit()
            except:
                pass
    
    return False

def test_certificate_details():
    """Get certificate details"""
    try:
        print("\n=== Certificate Details ===")
        
        # Create SSL context
        context = ssl.create_default_context()
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        
        # Connect and get certificate
        with socket.create_connection(("direct.if-else.click", 587)) as sock:
            # Send EHLO and STARTTLS
            sock.send(b"EHLO test\r\n")
            response = sock.recv(1024)
            print(f"EHLO Response: {response.decode().strip()}")
            
            sock.send(b"STARTTLS\r\n")
            response = sock.recv(1024)
            print(f"STARTTLS Response: {response.decode().strip()}")
            
            # Wrap with SSL
            with context.wrap_socket(sock, server_hostname="direct.if-else.click") as ssock:
                cert = ssock.getpeercert()
                print(f"✅ Certificate Subject: {cert.get('subject')}")
                print(f"✅ Certificate Issuer: {cert.get('issuer')}")
                print(f"✅ Certificate Valid Until: {cert.get('notAfter')}")
                
                # Check if it's Let's Encrypt
                issuer_str = str(cert.get('issuer', ''))
                if 'Let\'s Encrypt' in issuer_str or 'ISRG' in issuer_str:
                    print("✅ This is a Let's Encrypt certificate!")
                else:
                    print("⚠️  This might be a self-signed certificate")
                
    except Exception as e:
        print(f"❌ Certificate check failed: {e}")

def test_smtp_with_working_ssl():
    """Test SMTP with the working SSL version"""
    try:
        print("\n=== Testing Email Sending ===")
        
        server = smtplib.SMTP("direct.if-else.click", 587)
        server.set_debuglevel(1)
        
        # Use the most compatible SSL context
        context = ssl.SSLContext(ssl.PROTOCOL_TLS)
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        
        server.starttls(context=context)
        
        # Create test email
        msg = MIMEMultipart()
        msg['From'] = "test@if-else.click"
        msg['To'] = "recipient@direct.if-else.click"
        msg['Subject'] = "Test Email with Let's Encrypt SSL"
        
        body = "This email was sent using Let's Encrypt SSL certificate!"
        msg.attach(MIMEText(body, 'plain'))
        
        # Send email
        server.sendmail("test@if-else.click", "recipient@direct.if-else.click", msg.as_string())
        server.quit()
        
        print("✅ Email sent successfully with SSL!")
        
    except Exception as e:
        print(f"❌ Email sending failed: {e}")

if __name__ == "__main__":
    print("=== DirectSMTP SSL Troubleshooting ===")
    
    # Test different SSL versions
    ssl_working = test_ssl_versions()
    
    # Get certificate details
    test_certificate_details()
    
    # Test email sending if SSL is working
    if ssl_working:
        test_smtp_with_working_ssl()
    else:
        print("\n❌ SSL handshake failed with all versions")
        print("This suggests a server-side SSL configuration issue")