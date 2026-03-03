package servlets;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/updateProfile")
public class UpdateProfileServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // SECURITY: Use false to avoid creating a new session if one doesn't exist
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        
        if (user == null) {
            response.sendRedirect("login.jsp?error=unauthorized");
            return;
        }

        // Validate birthdate input
        String birthdate = request.getParameter("birthdate");
        if (birthdate == null || birthdate.trim().isEmpty()) {
            redirectByRole(user, response, "error=invalid_date");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            // SECURITY: Explicitly target only the birthdate and the specific logged-in user ID
            String sql = "UPDATE users SET birthdate = ?::DATE WHERE user_id = ? AND school_id = ?";
            try (PreparedStatement pst = conn.prepareStatement(sql)) {
                pst.setString(1, birthdate);
                pst.setInt(2, user.getId());
                pst.setInt(3, user.getSchoolId()); // Added school isolation
                
                int rowsUpdated = pst.executeUpdate();
                
                if (rowsUpdated > 0) {
                    // Update session object immediately for UI consistency
                    user.setBirthdate(birthdate);
                    session.setAttribute("user", user);
                    redirectByRole(user, response, "profileUpdated=1");
                } else {
                    redirectByRole(user, response, "error=update_failed");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            redirectByRole(user, response, "error=system");
        }
    }

    /**
     * Helper to ensure users are sent back to the correct dashboard after updating profile
     */
    private void redirectByRole(User user, HttpServletResponse response, String params) throws IOException {
        String role = user.getRole().toLowerCase();
        String target = "login.jsp";

        if (role.equals("student")) {
            target = "studentDashboard";
        } else if (role.equals("teacher")) {
            target = "teacherDashboard";
        } else if (role.equals("school_admin") || role.equals("super_admin")) {
            target = "adminDashboard";
        } else if (role.equals("platform_root")) {
            target = "superAdminAction";
        }

        response.sendRedirect(target + "?" + params);
    }
}