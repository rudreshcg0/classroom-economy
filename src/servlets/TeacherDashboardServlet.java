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

        // Security check: If not logged in or not a teacher, kick back to login
        if (teacher == null || !teacher.getRole().equalsIgnoreCase("teacher")) {
            response.sendRedirect("login.html");
            return;
        }

        List<User> studentList = new ArrayList<>();
        double currentAllowance = 0.0;

        try (Connection conn = DBConnection.getConnection()) {
            // 1. Get the Teacher's current budget from the allowance table
            String sqlAllowance = "SELECT current_balance FROM teacher_allowance WHERE teacher_id = ?";
            PreparedStatement pst1 = conn.prepareStatement(sqlAllowance);
            pst1.setInt(1, teacher.getId());
            ResultSet rs1 = pst1.executeQuery();
            if (rs1.next()) {
                currentAllowance = rs1.getDouble("current_balance");
            }

            // 2. Get all Students in this teacher's school + their wallet balances
            // We JOIN the users table with the wallets table
            String sqlStudents = "SELECT u.user_id, u.username, w.balance FROM users u " +
                                 "JOIN wallets w ON u.user_id = w.student_id " +
                                 "WHERE u.school_id = ? AND u.role = 'student'";
            PreparedStatement pst2 = conn.prepareStatement(sqlStudents);
            pst2.setInt(1, teacher.getSchoolId());
            ResultSet rs2 = pst2.executeQuery();

            while (rs2.next()) {
                studentList.add(new User(
                    rs2.getInt("user_id"),
                    rs2.getString("username"),
                    "student",
                    teacher.getSchoolId(),
                    rs2.getDouble("balance")
                ));
            }

            // 3. Attach the data to the request and forward to the JSP "View"
            request.setAttribute("allowance", currentAllowance);
            request.setAttribute("students", studentList);
            request.getRequestDispatcher("teacher_dashboard.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            response.getWriter().println("Database error: " + e.getMessage());
        }
    }
}