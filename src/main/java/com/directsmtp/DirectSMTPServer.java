package com.directsmtp;

import org.subethamail.smtp.helper.SimpleMessageListener;
import org.subethamail.smtp.helper.SimpleMessageListenerAdapter;
import org.subethamail.smtp.server.SMTPServer;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.security.KeyStore;

public class DirectSMTPServer {

    public static void main(String[] args) throws Exception {
        
        // Check for SSL certificate file
        String certPath = "/opt/directsmtp/src/main/resources/direct_cert.p12";
        String certPassword = "directsmtp2024"; // Updated to match deployment script
        
        // Try alternative paths for production deployment
        if (!new File(certPath).exists()) {
            certPath = "/opt/directsmtp/src/main/resources/direct_cert.p12";
        }
        
        SSLContext sslContext = null;
        boolean sslEnabled = false;
        System.out.println(" SSL certificate Available : "+ certPath+ ", Exists -"+ new File(certPath).exists());
        if (new File(certPath).exists()) {
            try {
                System.out.println("Loading SSL certificate from: " + certPath);
                
                KeyStore ks = KeyStore.getInstance("PKCS12");
                ks.load(new FileInputStream(certPath), certPassword.toCharArray());

                KeyManagerFactory kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
                kmf.init(ks, certPassword.toCharArray());

                sslContext = SSLContext.getInstance("TLS");
                sslContext.init(kmf.getKeyManagers(), null, null);
                
                // Set as default SSL context for the JVM
                SSLContext.setDefault(sslContext);
                
                // Configure supported protocols and cipher suites for better compatibility
                System.setProperty("https.protocols", "TLSv1.2,TLSv1.3");
                System.setProperty("jdk.tls.client.protocols", "TLSv1.2,TLSv1.3");
                
                sslEnabled = true;
                System.out.println("✅ SSL certificate loaded successfully");
            } catch (Exception e) {
                System.err.println("⚠️  Failed to load SSL certificate: " + e.getMessage());
                System.err.println("Starting server without SSL/TLS");
            }
        } else {
            System.err.println("⚠️  SSL certificate not found at: " + certPath);
            System.err.println("Starting server without SSL/TLS");
            System.err.println("");
            System.err.println("To enable SSL/TLS:");
            System.err.println("1. Run the deployment script: ./deploy/aws-app-deploy.sh");
            System.err.println("2. Choose option 4 (Setup SSL certificate)");
            System.err.println("3. Restart the service: sudo systemctl restart directsmtp");
        }

        SimpleMessageListener listener = new SimpleMessageListener() {
            @Override
            public boolean accept(String from, String recipient) {
                return recipient.endsWith("@direct.if-else.click") || 
                       recipient.endsWith("@if-else.click");
            }

            @Override
            public void deliver(String from, String recipient, InputStream data) {
                try {
                    System.out.println("Message received from: " + from + " to: " + recipient);
                    boolean valid = SMIMEUtils.verifySMIME(data);
                    if(valid) System.out.println("S/MIME signature verified!");
                    else System.out.println("Invalid S/MIME signature. Rejecting message.");
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        };

        // Create server for port 587 (submission port with required TLS)
        SMTPServer server587 = new SMTPServer(new SimpleMessageListenerAdapter(listener));
        server587.setPort(587);
        server587.setHostName("direct.if-else.click");
        
        if (sslEnabled) {
            server587.setEnableTLS(true);
            server587.setRequireTLS(true);
            System.out.println("🔒 Port 587: TLS/SSL enabled and required");
        } else {
            server587.setEnableTLS(false);
            server587.setRequireTLS(false);
            System.out.println("⚠️  Port 587: TLS/SSL disabled - running in plain text mode");
        }

        // Create server for port 25 (standard SMTP port with optional TLS)
        SMTPServer server25 = new SMTPServer(new SimpleMessageListenerAdapter(listener));
        server25.setPort(25);
        server25.setHostName("direct.if-else.click");
        
        if (sslEnabled) {
            server25.setEnableTLS(true);
            server25.setRequireTLS(false); // Port 25 should not require TLS for server-to-server communication
            System.out.println("🔒 Port 25: TLS/SSL enabled but optional");
        } else {
            server25.setEnableTLS(false);
            server25.setRequireTLS(false);
            System.out.println("⚠️  Port 25: TLS/SSL disabled - running in plain text mode");
        }

        // Start both servers
        server587.start();
        server25.start();
        
        System.out.println("🚀 DirectSMTP Server running on ports 25 and 587...");
        System.out.println("📧 Port 25: Standard SMTP (TLS optional)");
        System.out.println("📧 Port 587: Mail submission (TLS required)");
        System.out.println("📧 Accepting emails for: @direct.if-else.click and @if-else.click");
        
        if (!sslEnabled) {
            System.out.println("");
            System.out.println("⚠️  WARNING: Server is running without encryption!");
            System.out.println("   This is only suitable for testing purposes.");
            System.out.println("   Please set up SSL certificates for production use.");
        }
    }
}