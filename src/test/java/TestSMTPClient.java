import javax.mail.*;
import javax.mail.internet.*;
import java.util.Properties;

public class TestSMTPClient {
    public static void main(String[] args) {
        // SMTP server configuration
        String host = "localhost";
        String port = "587";
        
        // Email details
        String from = "test@example.com";
        String to = "recipient@direct.if-else.com"; // Must end with @direct.if-else.com
        String subject = "Test DirectSMTP Server";
        String body = "This is a test message for the DirectSMTP Server";
        
        // Set properties
        Properties props = new Properties();
        props.put("mail.smtp.host", host);
        props.put("mail.smtp.port", port);
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.auth", "false"); // No authentication required
        
        try {
            // Create session
            Session session = Session.getInstance(props);
            session.setDebug(true); // Enable debug output
            
            // Create message
            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(from));
            message.addRecipient(Message.RecipientType.TO, new InternetAddress(to));
            message.setSubject(subject);
            message.setText(body);
            
            // Send message
            Transport.send(message);
            System.out.println("Message sent successfully!");
            
        } catch (MessagingException e) {
            e.printStackTrace();
        }
    }
}