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

        // Security: Ensure only super_admins can enter
        if (admin == null || !admin.getRole().equalsIgnoreCase("super_admin")) {
            response.sendRedirect("login.html");
            return;
        }

        List<User> allUsers = new ArrayList<>();
        List<Map<String, Object>> schoolStats = new ArrayList<>();

        try (Connection conn = DBConnection.getConnection()) {
            // 1. Get Teacher count per school (Your logic)
            String sqlStats = "SELECT s.school_name, COUNT(u.user_id) as teacher_count " +
                              "FROM schools s LEFT JOIN users u ON s.school_id = u.school_id " +
                              "AND u.role = 'teacher' GROUP BY s.school_id, s.school_name";
            PreparedStatement pst1 = conn.prepareStatement(sqlStats);
            ResultSet rs1 = pst1.executeQuery();
            while (rs1.next()) {
                Map<String, Object> stat = new HashMap<>();
                stat.put("name", rs1.getString("school_name"));
                stat.put("count", rs1.getInt("teacher_count"));
                schoolStats.add(stat);
            }

            // 2. Get All Users (Teachers and Students) for the global list
            String sqlUsers = "SELECT user_id, username, role, school_id FROM users WHERE role != 'super_admin'";
            PreparedStatement pst2 = conn.prepareStatement(sqlUsers);
            ResultSet rs2 = pst2.executeQuery();
            while (rs2.next()) {
                allUsers.add(new User(
                    rs2.getInt("user_id"),
                    rs2.getString("username"),
                    rs2.getString("role"),
                    rs2.getInt("school_id")
                ));
            }

            // 3. Send data to JSP
            request.setAttribute("schoolStats", schoolStats);
            request.setAttribute("allUsers", allUsers);
            request.getRequestDispatcher("admin_dashboard.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            response.getWriter().println("Admin DB Error: " + e.getMessage());
        }
    }
}