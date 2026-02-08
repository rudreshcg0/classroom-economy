package servlets;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/studentDashboard")
public class StudentDashboardServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User student = (User) session.getAttribute("user");

        // Security check: If not logged in or not a student, redirect to login
        if (student == null || !student.getRole().equalsIgnoreCase("student")) {
            response.sendRedirect("login.html");
            return;
        }

        double balance = 0.0;

        try (Connection conn = DBConnection.getConnection()) {
            // Fetch the specific wallet balance for this student
            String sql = "SELECT balance FROM wallets WHERE student_id = ?";
            PreparedStatement pst = conn.prepareStatement(sql);
            pst.setInt(1, student.getId());
            ResultSet rs = pst.executeQuery();

            if (rs.next()) {
                balance = rs.getDouble("balance");
            }
            
            // Attach balance to request and forward to JSP
            request.setAttribute("balance", balance);
            request.getRequestDispatcher("student_dashboard.jsp").forward(request, response);
            
        } catch (SQLException e) {
            e.printStackTrace();
            response.getWriter().println("Database Error: " + e.getMessage());
        }
    }
}