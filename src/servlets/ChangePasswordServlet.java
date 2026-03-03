package servlets;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;
import org.mindrot.jbcrypt.BCrypt;

@WebServlet("/changePassword")
public class ChangePasswordServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;

        // Security check: Ensure the user is actually in a session
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String newPass = request.getParameter("newPassword");
        String confirmPass = request.getParameter("confirmPassword");

        // Validate that passwords match and aren't empty
        if (newPass == null || newPass.trim().isEmpty() || !newPass.equals(confirmPass)) {
            response.sendRedirect("change_password.jsp?error=mismatch");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            // SECURITY UPDATE: Hash the new password before storing it
            // We use BCrypt to ensure it matches the security level of LoginServlet
            String hashedPass = BCrypt.hashpw(newPass, BCrypt.gensalt(12));

            // Update password and flip the 'must_change_password' flag to FALSE
            String sql = "UPDATE users SET password = ?, must_change_password = FALSE WHERE user_id = ?";
            
            try (PreparedStatement pst = conn.prepareStatement(sql)) {
                pst.setString(1, hashedPass);
                pst.setInt(2, user.getId()); 

                int updated = pst.executeUpdate();

                if (updated > 0) {
                    // Password changed successfully, redirect to appropriate dashboard
                    String role = user.getRole().toLowerCase();
                    if (role.equals("super_admin") || role.equals("school_admin")) {
                        response.sendRedirect("adminDashboard?success=1");
                    } else if (role.equals("teacher")) {
                        response.sendRedirect("teacherDashboard?success=1");
                    } else if (role.equals("student")) {
                        response.sendRedirect("studentDashboard?success=1");
                    } else {
                        response.sendRedirect("login.jsp");
                    }
                } else {
                    response.sendRedirect("change_password.jsp?error=update_failed");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("change_password.jsp?error=database");
        }
    }
}