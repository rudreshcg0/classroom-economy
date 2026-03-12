package utils;

import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

public class EmailUtil {
    public static void sendOTP(String toEmail, String otp) throws Exception {
        // 1. Setup the API URL and your Key
        String apiKey = DBConnection.getBrevoApiKey();
        URL url = new URL("https://api.brevo.com/v3/smtp/email");
        
        // 2. Open Connection
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("api-key", apiKey);
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setDoOutput(true);

        // 3. Create the JSON payload
        String jsonInputString = "{"
            + "\"sender\":{\"name\":\"VCES System\",\"email\":\"vces.system.noreply@gmail.com\"},"
            + "\"to\":[{\"email\":\"" + toEmail + "\"}],"
            + "\"subject\":\"Your Security Code\","
            + "\"textContent\":\"Your OTP is: " + otp + "\""
            + "}";

        // 4. Send the Request
        try(OutputStream os = conn.getOutputStream()) {
            byte[] input = jsonInputString.getBytes(StandardCharsets.UTF_8);
            os.write(input, 0, input.length);			
        }

        // 5. Check Response
        int code = conn.getResponseCode();
        if (code >= 200 && code <= 299) {
            System.out.println("DEBUG: Email sent via API successfully!");
        } else {
            System.out.println("DEBUG: API Error Code: " + code);
            throw new Exception("Email API failed with code: " + code);
        }
    }
}
