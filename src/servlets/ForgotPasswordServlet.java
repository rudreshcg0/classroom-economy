package servlets;

import java.io.IOException;
import java.sql.*;
import java.util.Random;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import utils.EmailUtil;

@WebServlet("/forgotPassword")
public class ForgotPasswordServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String phase = request.getParameter("phase");
        String email = request.getParameter("email");
        
        System.out.println("--- ForgotPasswordServlet Started ---");
        System.out.println("Phase: " + phase);
        System.out.println("Target Email: " + email);

        try (Connection conn = DBConnection.getConnection()) {
            System.out.println("1. Database Connected successfully.");

            if ("sendOTP".equals(phase)) {
                // 1. Check if email exists
                String checkSql = "SELECT user_id FROM users WHERE email = ?";
                PreparedStatement checkPst = conn.prepareStatement(checkSql);
                checkPst.setString(1, email);
                ResultSet rs = checkPst.executeQuery();

                if (rs.next()) {
                    System.out.println("2. Email found in database. Generating OTP...");
                    
                    // 2. Generate 6-digit OTP
                    String otp = String.format("%06d", new Random().nextInt(999999));
                    
                    // 3. Save to DB with 5-minute expiry
                    System.out.println("3. Updating database with OTP code...");
                    String updateSql = "UPDATE users SET otp_code = ?, otp_expiry = CURRENT_TIMESTAMP + INTERVAL '5 minutes' WHERE email = ?";
                    PreparedStatement updatePst = conn.prepareStatement(updateSql);
                    updatePst.setString(1, otp);
                    updatePst.setString(2, email);
                    updatePst.executeUpdate();
                    System.out.println("4. Database updated successfully.");

                    // 4. Send Email
                    System.out.println("5. Calling EmailUtil.sendOTP...");
                    EmailUtil.sendOTP(email, otp);
                    System.out.println("6. EmailUtil.sendOTP finished execution.");
                    
                    // Redirect to Step 2
                    response.sendRedirect("forgot_password.jsp?step=2&email=" + email);
                } else {
                    System.out.println("RESULT: Email not found in users table.");
                    response.sendRedirect("forgot_password.jsp?error=notfound");
                }

            } else if ("verifyOTP".equals(phase)) {
                String enteredOtp = request.getParameter("otp");
                String newPass = request.getParameter("newPassword");
                System.out.println("Phase: verifyOTP | OTP entered: " + enteredOtp);

                // Check OTP and Expiry
                String verifySql = "SELECT user_id FROM users WHERE email = ? AND otp_code = ? AND otp_expiry > CURRENT_TIMESTAMP";
                PreparedStatement verifyPst = conn.prepareStatement(verifySql);
                verifyPst.setString(1, email);
                verifyPst.setString(2, enteredOtp);
                ResultSet rs = verifyPst.executeQuery();

                if (rs.next()) {
                    System.out.println("RESULT: OTP Verified. Updating password...");
                    // Correct OTP - Update Password and Clear OTP
                    String updatePassSql = "UPDATE users SET password = ?, otp_code = NULL, otp_expiry = NULL WHERE email = ?";
                    PreparedStatement updatePassPst = conn.prepareStatement(updatePassSql);
                    updatePassPst.setString(1, newPass);
                    updatePassPst.setString(2, email);
                    updatePassPst.executeUpdate();

                    response.sendRedirect("login.jsp?resetSuccess=1");
                } else {
                    System.out.println("RESULT: Invalid or Expired OTP.");
                    response.sendRedirect("forgot_password.jsp?step=2&email=" + email + "&error=invalid");
                }
            }
        } catch (Exception e) {
            System.out.println("!!! CRASH IN SERVLET !!!");
            System.out.println("Error Message: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect("forgot_password.jsp?error=db");
        }
        System.out.println("--- ForgotPasswordServlet Finished ---");
    }
}