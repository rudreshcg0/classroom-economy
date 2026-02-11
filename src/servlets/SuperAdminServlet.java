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
        
        if (user == null || !user.getRole().equals("platform_root")) {
            response.sendRedirect("login.html");
            return;
        }

        String action = request.getParameter("action");

        try (Connection conn = DBConnection.getConnection()) {
            if ("createSchool".equals(action)) {
                String name = request.getParameter("schoolName");
                try (PreparedStatement pst = conn.prepareStatement("INSERT INTO schools (school_name) VALUES (?)")) {
                    pst.setString(1, name);
                    pst.executeUpdate();
                }
            } else if ("createSchoolAdmin".equals(action)) {
                String adminUser = request.getParameter("adminUser");
                String adminPass = request.getParameter("adminPass");
                int schoolId = Integer.parseInt(request.getParameter("schoolId"));
                
                try (PreparedStatement pst = conn.prepareStatement("INSERT INTO users (username, password, role, school_id) VALUES (?, ?, 'school_admin', ?)")) {
                    pst.setString(1, adminUser);
                    pst.setString(2, adminPass);
                    pst.setInt(3, schoolId);
                    pst.executeUpdate();
                }
            } else if ("editSchool".equals(action)) {
                int schoolId = Integer.parseInt(request.getParameter("schoolId"));
                String newName = request.getParameter("newName");
                try (PreparedStatement pst = conn.prepareStatement("UPDATE schools SET school_name = ? WHERE school_id = ?")) {
                    pst.setString(1, newName);
                    pst.setInt(2, schoolId);
                    pst.executeUpdate();
                }
            } else if ("deleteSchool".equals(action)) {
                int schoolId = Integer.parseInt(request.getParameter("schoolId"));
                try (PreparedStatement pst = conn.prepareStatement("DELETE FROM schools WHERE school_id = ?")) {
                    pst.setInt(1, schoolId);
                    pst.executeUpdate();
                }
            } else if ("deleteAdmin".equals(action)) {
                int adminId = Integer.parseInt(request.getParameter("adminId"));
                try (PreparedStatement pst = conn.prepareStatement("DELETE FROM users WHERE user_id = ? AND role = 'school_admin'")) {
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