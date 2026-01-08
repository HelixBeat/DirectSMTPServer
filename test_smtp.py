#!/usr/bin/env python3
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def test_smtp_server():
    # Server configuration
    smtp_server = "localhost"
    port = 587
    
    # Email content
    sender_email = "test@example.com"
    receiver_email = "recipient@direct.if-else.com"  # Must end with @direct.if-else.com
    
    message = MIMEMultipart()
    message["From"] = sender_email
    message["To"] = receiver_email
    message["Subject"] = "Test DirectSMTP Server"
    
    body = "This is a test message for the DirectSMTP Server"
    message.attach(MIMEText(body, "plain"))
    
    try:
        # Create SMTP session
        server = smtplib.SMTP(smtp_server, port)
        server.set_debuglevel(1)  # Enable debug output
        
        # Enable security
        server.starttls(context=ssl.create_default_context())
        
        # Send email
        text = message.as_string()
        server.sendmail(sender_email, receiver_email, text)
        server.quit()
        
        print("Email sent successfully!")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_smtp_server()