package servlets;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/teacherDashboard")
public class TeacherDashboardServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User teacher = (User) session.getAttribute("user");

        // Security Guard
        if (teacher == null || !teacher.getRole().equalsIgnoreCase("teacher")) {
            response.sendRedirect("login.html");
            return;
        }

        List<Map<String, Object>> classesList = new ArrayList<>();
        double currentAllowance = 0.0;

        try (Connection conn = DBConnection.getConnection()) {
            // 1. Get Teacher's current budget balance
            String sqlAllowance = "SELECT current_balance FROM teacher_allowance WHERE teacher_id = ?";
            try (PreparedStatement pst1 = conn.prepareStatement(sqlAllowance)) {
                pst1.setInt(1, teacher.getId());
                ResultSet rs1 = pst1.executeQuery();
                if (rs1.next()) {
                    currentAllowance = rs1.getDouble("current_balance");
                }
            }

            // 2. Get only the Classes assigned specifically to this teacher
            String sqlClasses = "SELECT class_id, class_name, pay_per_session FROM classes WHERE teacher_id = ?";
            try (PreparedStatement pstClasses = conn.prepareStatement(sqlClasses)) {
                pstClasses.setInt(1, teacher.getId());
                ResultSet rsClasses = pstClasses.executeQuery();
                while (rsClasses.next()) {
                    Map<String, Object> classMap = new HashMap<>();
                    classMap.put("id", rsClasses.getInt("class_id"));
                    classMap.put("name", rsClasses.getString("class_name"));
                    classMap.put("pay", rsClasses.getDouble("pay_per_session"));
                    classesList.add(classMap);
                }
            }

            // Set data for the JSP
            request.setAttribute("allowance", currentAllowance);
            request.setAttribute("classes", classesList);
            
            // Forward to the dashboard UI
            request.getRequestDispatcher("teacher_dashboard.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            response.getWriter().println("Teacher Dashboard Error: " + e.getMessage());
        }
    }
}