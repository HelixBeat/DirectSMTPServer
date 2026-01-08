package com.directsmtp;

import org.subethamail.smtp.helper.SimpleMessageListener;
import org.subethamail.smtp.helper.SimpleMessageListenerAdapter;
import org.subethamail.smtp.server.SMTPServer;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import java.io.FileInputStream;
import java.io.InputStream;
import java.security.KeyStore;
import java.util.logging.Logger;
import java.util.logging.Level;

public class ProductionDirectSMTPServer {
    private static final Logger logger = Logger.getLogger(ProductionDirectSMTPServer.class.getName());
    
    public static void main(String[] args) throws Exception {
        // Configuration from environment variables
        String hostname = System.getenv().getOrDefault("SMTP_HOSTNAME", "direct.if-else.click");
        int port = Integer.parseInt(System.getenv().getOrDefault("SMTP_PORT", "587"));
        String certPath = System.getenv().getOrDefault("CERT_PATH", "src/main/resources/direct_cert.p12");
        String certPassword = System.getenv().getOrDefault("CERT_PASSWORD", "password");
        
        logger.info("Starting DirectSMTP Server...");
        logger.info("Hostname: " + hostname);
        logger.info("Port: " + port);
        
        try {
            // Load certificate
            KeyStore ks = KeyStore.getInstance("PKCS12");
            ks.load(new FileInputStream(certPath), certPassword.toCharArray());

            KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
            kmf.init(ks, certPassword.toCharArray());

            SSLContext sslContext = SSLContext.getInstance("TLSv1.2");
            sslContext.init(kmf.getKeyManagers(), null, null);

            SimpleMessageListener listener = new SimpleMessageListener() {
                @Override
                public boolean accept(String from, String recipient) {
                    boolean accepted = recipient.endsWith("@" + hostname);
                    logger.info("Message from " + from + " to " + recipient + " - " + (accepted ? "ACCEPTED" : "REJECTED"));
                    return accepted;
                }

                @Override
                public void deliver(String from, String recipient, InputStream data) {
                    try {
                        logger.info("Processing message from: " + from + " to: " + recipient);
                        boolean valid = SMIMEUtils.verifySMIME(data);
                        if(valid) {
                            logger.info("S/MIME signature verified for message from " + from);
                        } else {
                            logger.warning("Invalid S/MIME signature from " + from + ". Message rejected.");
                        }
                    } catch (Exception e) {
                        logger.log(Level.SEVERE, "Error processing message from " + from, e);
                    }
                }
            };

            SMTPServer server = new SMTPServer(new SimpleMessageListenerAdapter(listener));
            server.setPort(port);
            server.setHostName(hostname);
            server.setEnableTLS(true);
            server.setRequireTLS(true);
            
            // Bind to all interfaces for public access
            server.setBindAddress(null);

            server.start();
            logger.info("DirectSMTP Server started successfully on " + hostname + ":" + port);
            
            // Add shutdown hook
            Runtime.getRuntime().addShutdownHook(new Thread(() -> {
                logger.info("Shutting down DirectSMTP Server...");
                server.stop();
                logger.info("DirectSMTP Server stopped.");
            }));
            
            // Keep the main thread alive
            Thread.currentThread().join();
            
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Failed to start DirectSMTP Server", e);
            System.exit(1);
        }
    }
}