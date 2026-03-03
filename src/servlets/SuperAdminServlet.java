package servlets;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;
import org.mindrot.jbcrypt.BCrypt;

@WebServlet("/superAdminAction")
public class SuperAdminServlet extends HttpServlet {

    /**
     * GET handles data retrieval for the dashboard
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;

        if (user == null || !"platform_root".equals(user.getRole())) {
            response.sendRedirect("login.jsp?error=unauthorized");
            return;
        }

        List<Map<String, Object>> schoolList = new ArrayList<>();
        List<Map<String, Object>> simpleSchoolList = new ArrayList<>();

        try (Connection conn = DBConnection.getConnection()) {
            // 1. Fetch Schools with their assigned Admins
            String sql = "SELECT s.school_id, s.school_name, u.username AS admin_name, u.user_id AS admin_id " +
                         "FROM schools s LEFT JOIN users u ON s.school_id = u.school_id AND u.role = 'school_admin' " +
                         "ORDER BY s.school_id";
            
            try (Statement st = conn.createStatement(); ResultSet rs = st.executeQuery(sql)) {
                while (rs.next()) {
                    Map<String, Object> school = new HashMap<>();
                    school.put("school_id", rs.getInt("school_id"));
                    school.put("school_name", rs.getString("school_name"));
                    school.put("admin_name", rs.getString("admin_name"));
                    school.put("admin_id", rs.getObject("admin_id")); // getObject handles possible nulls
                    schoolList.add(school);
                    
                    // Also populate a simple list for the dropdown
                    Map<String, Object> simple = new HashMap<>();
                    simple.put("school_id", rs.getInt("school_id"));
                    simple.put("school_name", rs.getString("school_name"));
                    simpleSchoolList.add(simple);
                }
            }

            request.setAttribute("schoolList", schoolList);
            request.setAttribute("simpleSchoolList", simpleSchoolList);
            request.getRequestDispatcher("super_dashboard.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("login.jsp?error=database");
        }
    }

    /**
     * POST handles administrative actions (Create, Update, Delete)
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        
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
                
                // SECURITY: Hash password before saving
                String hashedPass = BCrypt.hashpw(adminPass, BCrypt.gensalt(12));
                
                String sql = "INSERT INTO users (username, password, role, school_id, must_change_password) VALUES (?, ?, 'school_admin', ?, TRUE)";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setString(1, adminUser);
                    pst.setString(2, hashedPass);
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
                try (PreparedStatement pst = conn.prepareStatement("DELETE FROM schools WHERE school_id = ?")) {
                    pst.setInt(1, schoolId);
                    pst.executeUpdate();
                }
            } 
            
            // --- ACTION: Delete Administrator ---
            else if ("deleteAdmin".equals(action)) {
                int adminId = Integer.parseInt(request.getParameter("adminId"));
                try (PreparedStatement pst = conn.prepareStatement("DELETE FROM users WHERE user_id = ? AND role = 'school_admin'")) {
                    pst.setInt(1, adminId);
                    pst.executeUpdate();
                }
            }
            
            // SECURITY: Use doGet to refresh the data after a post action
            response.sendRedirect("superAdminAction?success=1");
            
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("superAdminAction?error=db");
        }
    }
}