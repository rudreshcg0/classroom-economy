package servlets;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/superAdminAction")
public class SuperAdminServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        // Security: Only allow platform_root or super_admin
        if (user == null || (!user.getRole().equals("platform_root") && !user.getRole().equals("super_admin"))) {
            response.sendRedirect("login.html");
            return;
        }

        String action = request.getParameter("action");

        try (Connection conn = DBConnection.getConnection()) {
            if ("createSchool".equals(action)) {
                String name = request.getParameter("schoolName");
                String sql = "INSERT INTO schools (school_name) VALUES (?)";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setString(1, name);
                    pst.executeUpdate();
                }
            } else if ("createSchoolAdmin".equals(action)) {
                String adminUser = request.getParameter("adminUser");
                String adminPass = request.getParameter("adminPass");
                int schoolId = Integer.parseInt(request.getParameter("schoolId"));
                
                String sql = "INSERT INTO users (username, password, role, school_id) VALUES (?, ?, 'school_admin', ?)";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setString(1, adminUser);
                    pst.setString(2, adminPass);
                    pst.setInt(3, schoolId);
                    pst.executeUpdate();
                }
            } else if ("deleteSchool".equals(action)) {
                int schoolId = Integer.parseInt(request.getParameter("schoolId"));
                // This triggers the ON DELETE CASCADE set in the DB
                String sql = "DELETE FROM schools WHERE school_id = ?";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setInt(1, schoolId);
                    pst.executeUpdate();
                }
            } else if ("deleteAdmin".equals(action)) {
                int adminId = Integer.parseInt(request.getParameter("adminId"));
                // Specific delete for the admin user only
                String sql = "DELETE FROM users WHERE user_id = ? AND role = 'school_admin'";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setInt(1, adminId);
                    pst.executeUpdate();
                }
            }
            response.sendRedirect("super_dashboard.jsp?success=1");
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("super_dashboard.jsp?error=db");
        }
    }
}