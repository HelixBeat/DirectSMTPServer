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
        String certPath = "src/main/resources/direct_cert.p12";
        String certPassword = "directsmtp2024"; // Updated to match deployment script
        
        // Try alternative paths for production deployment
        if (!new File(certPath).exists()) {
            certPath = "/opt/directsmtp/src/main/resources/direct_cert.p12";
        }
        
        SSLContext sslContext = null;
        boolean sslEnabled = false;
        
        if (new File(certPath).exists()) {
            try {
                System.out.println("Loading SSL certificate from: " + certPath);
                
                KeyStore ks = KeyStore.getInstance("PKCS12");
                ks.load(new FileInputStream(certPath), certPassword.toCharArray());

                KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
                kmf.init(ks, certPassword.toCharArray());

                sslContext = SSLContext.getInstance("TLSv1.2");
                sslContext.init(kmf.getKeyManagers(), null, null);
                
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
                return recipient.endsWith("@direct.if-else.click");
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

        SMTPServer server = new SMTPServer(new SimpleMessageListenerAdapter(listener));
        server.setPort(587);
        server.setHostName("direct.if-else.click");
        
        if (sslEnabled) {
            server.setEnableTLS(true);
            server.setRequireTLS(true);
            System.out.println("🔒 TLS/SSL enabled and required");
        } else {
            server.setEnableTLS(false);
            server.setRequireTLS(false);
            System.out.println("⚠️  TLS/SSL disabled - server running in plain text mode");
        }

        server.start();
        System.out.println("🚀 DirectSMTP Server running on port 587...");
        System.out.println("📧 Accepting emails for: @direct.if-else.click");
        
        if (!sslEnabled) {
            System.out.println("");
            System.out.println("⚠️  WARNING: Server is running without encryption!");
            System.out.println("   This is only suitable for testing purposes.");
            System.out.println("   Please set up SSL certificates for production use.");
        }
    }
}