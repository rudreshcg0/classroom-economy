package utils;

import java.util.Properties;
import jakarta.mail.*;
import jakarta.mail.internet.*;
import jakarta.activation.*; // Ensure the angus-activation JAR is available

public class EmailUtil {
    public static void sendOTP(String toEmail, String otp) throws MessagingException {
        // Manually register handlers to avoid ClassNotFoundException in JDK 25
        MailcapCommandMap mc = (MailcapCommandMap) CommandMap.getDefaultCommandMap();
        mc.addMailcap("text/plain;; x-java-content-handler=org.eclipse.angus.activation.handlers.TextPlainHandler");
        CommandMap.setDefaultCommandMap(mc);

        final String from = "vces.system.noreply@gmail.com"; 
        final String password = "rbemfasonakubsgg"; 

        Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", "smtp.gmail.com");
        props.put("mail.smtp.port", "587");

        Session session = Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(from, password);
            }
        });

        Message message = new MimeMessage(session);
        message.setFrom(new InternetAddress(from));
        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
        message.setSubject("VCES Security: Reset Code");
        message.setText("Your reset code is: " + otp);

        System.out.println("DEBUG: Attempting to send email to " + toEmail);
        Transport.send(message);
        System.out.println("DEBUG: Email sent successfully!");
    }
}