package servlets;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;
import org.mindrot.jbcrypt.BCrypt; // Required for secure password hashing

@WebServlet("/superAdminAction")
public class SuperAdminServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // --- SECURITY: Strict Role & Session Validation ---
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        
        // Ensure only the top-level 'platform_root' can access these actions
        if (user == null || !"platform_root".equals(user.getRole())) {
            response.sendRedirect("login.jsp?error=unauthorized");
            return;
        }

        String action = request.getParameter("action");

        try (Connection conn = DBConnection.getConnection()) {
            // --- ACTION: Create New School ---
            if ("createSchool".equals(action)) {
                String name = request.getParameter("schoolName");
                try (PreparedStatement pst = conn.prepareStatement("INSERT INTO schools (school_name) VALUES (?)")) {
                    pst.setString(1, name);
                    pst.executeUpdate();
                }
            } 
            
            // --- ACTION: Create School Administrator ---
            else if ("createSchoolAdmin".equals(action)) {
                String adminUser = request.getParameter("adminUser");
                String adminPass = request.getParameter("adminPass");
                int schoolId = Integer.parseInt(request.getParameter("schoolId"));
                
                // SECURITY: Hash the password with BCrypt before saving to DB
                String hashedPass = BCrypt.hashpw(adminPass, BCrypt.gensalt());
                
                String sql = "INSERT INTO users (username, password, role, school_id, must_change_password) VALUES (?, ?, 'school_admin', ?, TRUE)";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setString(1, adminUser);
                    pst.setString(2, hashedPass); // Save hash, not plain text
                    pst.setInt(3, schoolId);
                    pst.executeUpdate();
                }
            } 
            
            // --- ACTION: Edit School Details ---
            else if ("editSchool".equals(action)) {
                int schoolId = Integer.parseInt(request.getParameter("schoolId"));
                String newName = request.getParameter("newName");
                try (PreparedStatement pst = conn.prepareStatement("UPDATE schools SET school_name = ? WHERE school_id = ?")) {
                    pst.setString(1, newName);
                    pst.setInt(2, schoolId);
                    pst.executeUpdate();
                }
            } 
            
            // --- ACTION: Delete School ---
            else if ("deleteSchool".equals(action)) {
                int schoolId = Integer.parseInt(request.getParameter("schoolId"));
                // Note: Ensure your schema has ON DELETE CASCADE for related tables
                try (PreparedStatement pst = conn.prepareStatement("DELETE FROM schools WHERE school_id = ?")) {
                    pst.setInt(1, schoolId);
                    pst.executeUpdate();
                }
            } 
            
            // --- ACTION: Delete Administrator ---
            else if ("deleteAdmin".equals(action)) {
                int adminId = Integer.parseInt(request.getParameter("adminId"));
                // SECURITY: Explicitly ensure only school_admin accounts are targeted here
                try (PreparedStatement pst = conn.prepareStatement("DELETE FROM users WHERE user_id = ? AND role = 'school_admin'")) {
                    pst.setInt(1, adminId);
                    pst.executeUpdate();
                }
            }
            
            response.sendRedirect("super_dashboard.jsp?success=1");
            
        } catch (SQLException e) {
            e.printStackTrace(); // Consider using a logger in production
            response.sendRedirect("super_dashboard.jsp?error=db");
        }
    }
}