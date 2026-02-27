package servlets;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/changePassword")
public class ChangePasswordServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;

        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String newPass = request.getParameter("newPassword");
        String confirmPass = request.getParameter("confirmPassword");

        if (newPass == null || !newPass.equals(confirmPass)) {
            response.sendRedirect("change_password.jsp?error=mismatch");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            // Update password and flip the flag to FALSE
            String sql = "UPDATE users SET password = ?, must_change_password = FALSE WHERE user_id = ?";
            PreparedStatement pst = conn.prepareStatement(sql);
            pst.setString(1, newPass);
            // Updated to use the correct getter from your User model
            pst.setInt(2, user.getId()); 

            int updated = pst.executeUpdate();

            if (updated > 0) {
                // Password changed successfully, redirect to appropriate dashboard
                String role = user.getRole().toLowerCase();
                if (role.equals("super_admin") || role.equals("school_admin")) {
                    response.sendRedirect("adminDashboard");
                } else if (role.equals("teacher")) {
                    response.sendRedirect("teacherDashboard");
                } else {
                    response.sendRedirect("studentDashboard");
                }
            } else {
                response.sendRedirect("change_password.jsp?error=update_failed");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("change_password.jsp?error=database");
        }
    }
}