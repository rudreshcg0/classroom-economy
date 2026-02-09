package servlets;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/adminDashboard")
public class AdminDashboardServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User admin = (User) session.getAttribute("user");

        // 1. SECURITY CHECK
        if (admin == null || (!admin.getRole().equalsIgnoreCase("super_admin") && !admin.getRole().equalsIgnoreCase("school_admin"))) {
            response.sendRedirect("login.html?error=unauthorized");
            return;
        }

        List<User> allUsers = new ArrayList<>();
        List<Map<String, Object>> schoolStats = new ArrayList<>();
        List<Map<String, Object>> classList = new ArrayList<>();

        try (Connection conn = DBConnection.getConnection()) {
            
            // 2. FETCH SCHOOL STATS
            String sqlStats = "SELECT s.school_name, COUNT(u.user_id) as teacher_count " +
                              "FROM schools s LEFT JOIN users u ON s.school_id = u.school_id " +
                              "AND u.role = 'teacher' WHERE s.school_id = ? " +
                              "GROUP BY s.school_id, s.school_name";
            try (PreparedStatement pst1 = conn.prepareStatement(sqlStats)) {
                pst1.setInt(1, admin.getSchoolId());
                ResultSet rs1 = pst1.executeQuery();
                if (rs1.next()) {
                    Map<String, Object> stat = new HashMap<>();
                    stat.put("name", rs1.getString("school_name"));
                    stat.put("count", rs1.getInt("teacher_count"));
                    schoolStats.add(stat);
                }
            }

            // 3. FETCH ALL REGISTERED USERS
            String sqlUsers = "SELECT user_id, username, role, school_id FROM users WHERE school_id = ? AND role NOT IN ('platform_root', 'school_admin')";
            try (PreparedStatement pst2 = conn.prepareStatement(sqlUsers)) {
                pst2.setInt(1, admin.getSchoolId());
                ResultSet rs2 = pst2.executeQuery();
                while (rs2.next()) {
                    allUsers.add(new User(rs2.getInt("user_id"), rs2.getString("username"), rs2.getString("role"), rs2.getInt("school_id")));
                }
            }

            // 4. FETCH CLASSES WITH JOINED TEACHER NAMES
            String sqlClasses = "SELECT c.class_id, c.class_name, c.pay_per_session, u.username as teacher_name " +
                                "FROM classes c " +
                                "LEFT JOIN users u ON c.teacher_id = u.user_id " +
                                "WHERE c.school_id = ?";
            try (PreparedStatement pst3 = conn.prepareStatement(sqlClasses)) {
                pst3.setInt(1, admin.getSchoolId());
                ResultSet rs3 = pst3.executeQuery();
                while (rs3.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs3.getInt("class_id"));
                    row.put("name", rs3.getString("class_name"));
                    row.put("pay", rs3.getDouble("pay_per_session"));
                    
                    String tName = rs3.getString("teacher_name");
                    row.put("teacher", (tName != null) ? tName : "Unassigned");
                    
                    classList.add(row);
                }
            }

            // 5. PASS DATA TO THE JSP
            request.setAttribute("schoolStats", schoolStats);
            request.setAttribute("allUsers", allUsers);
            request.setAttribute("classList", classList);
            request.getRequestDispatcher("admin_dashboard.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            response.getWriter().println("Admin DB Error: " + e.getMessage());
        }
    }
}