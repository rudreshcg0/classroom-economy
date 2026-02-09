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

        if (teacher == null || !teacher.getRole().equalsIgnoreCase("teacher")) {
            response.sendRedirect("login.html");
            return;
        }

        List<User> studentList = new ArrayList<>();
        List<Map<String, Object>> classesList = new ArrayList<>();
        double currentAllowance = 0.0;

        try (Connection conn = DBConnection.getConnection()) {
            // 1. Get Teacher's Allowance
            String sqlAllowance = "SELECT current_balance FROM teacher_allowance WHERE teacher_id = ?";
            PreparedStatement pst1 = conn.prepareStatement(sqlAllowance);
            pst1.setInt(1, teacher.getId());
            ResultSet rs1 = pst1.executeQuery();
            if (rs1.next()) {
                currentAllowance = rs1.getDouble("current_balance");
            }

            // 2. Get Classes assigned to this teacher
            String sqlClasses = "SELECT class_id, class_name, pay_per_session FROM classes WHERE teacher_id = ?";
            PreparedStatement pstClasses = conn.prepareStatement(sqlClasses);
            pstClasses.setInt(1, teacher.getId());
            ResultSet rsClasses = pstClasses.executeQuery();
            while (rsClasses.next()) {
                Map<String, Object> classMap = new HashMap<>();
                classMap.put("id", rsClasses.getInt("class_id"));
                classMap.put("name", rsClasses.getString("class_name"));
                classMap.put("pay", rsClasses.getDouble("pay_per_session"));
                classesList.add(classMap);
            }

            // 3. Get Students + Balances + Roll Numbers (Sorted by Roll No)
            String sqlStudents = "SELECT u.user_id, u.username, u.roll_no, w.balance FROM users u " +
                                 "JOIN wallets w ON u.user_id = w.student_id " +
                                 "WHERE u.school_id = ? AND u.role = 'student' " +
                                 "ORDER BY u.roll_no ASC"; 
            PreparedStatement pst2 = conn.prepareStatement(sqlStudents);
            pst2.setInt(1, teacher.getSchoolId());
            ResultSet rs2 = pst2.executeQuery();

            while (rs2.next()) {
                // Using the updated constructor: (id, username, role, schoolId, balance, rollNo)
                studentList.add(new User(
                    rs2.getInt("user_id"),
                    rs2.getString("username"),
                    "student",
                    teacher.getSchoolId(),
                    rs2.getDouble("balance"),
                    rs2.getString("roll_no")
                ));
            }

            request.setAttribute("allowance", currentAllowance);
            request.setAttribute("classes", classesList);
            request.setAttribute("students", studentList);
            
            request.getRequestDispatcher("teacher_dashboard.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            response.getWriter().println("Database error: " + e.getMessage());
        }
    }
}