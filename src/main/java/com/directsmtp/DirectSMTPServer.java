package com.directsmtp;

import org.subethamail.smtp.helper.SimpleMessageListener;
import org.subethamail.smtp.helper.SimpleMessageListenerAdapter;
import org.subethamail.smtp.server.SMTPServer;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import java.io.FileInputStream;
import java.io.InputStream;
import java.security.KeyStore;

public class DirectSMTPServer {

    public static void main(String[] args) throws Exception {

        KeyStore ks = KeyStore.getInstance("PKCS12");
        ks.load(new FileInputStream("src/main/resources/direct_cert.p12"), "password".toCharArray());

        KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
        kmf.init(ks, "password".toCharArray());

        SSLContext sslContext = SSLContext.getInstance("TLSv1.2");
        sslContext.init(kmf.getKeyManagers(), null, null);

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
        server.setEnableTLS(true);
        server.setRequireTLS(true);

        server.start();
        System.out.println("Direct SMTP Server running on port 587...");
    }
}