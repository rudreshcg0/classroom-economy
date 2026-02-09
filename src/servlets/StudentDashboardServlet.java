package servlets;

import java.io.IOException;
import java.sql.*;
import java.util.*;
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

        if (student == null || !student.getRole().equalsIgnoreCase("student")) {
            response.sendRedirect("login.html");
            return;
        }

        double currentBalance = 0.0;
        String userRollNo = "";
        List<Map<String, Object>> history = new ArrayList<>();

        try (Connection conn = DBConnection.getConnection()) {
            // 1. Fetch Balance and Roll No for the current student
            String sqlData = "SELECT w.balance, u.roll_no FROM wallets w " +
                             "JOIN users u ON w.student_id = u.user_id " +
                             "WHERE u.user_id = ?";
            PreparedStatement pstData = conn.prepareStatement(sqlData);
            pstData.setInt(1, student.getId());
            ResultSet rsData = pstData.executeQuery();
            
            if (rsData.next()) {
                currentBalance = rsData.getDouble("balance");
                userRollNo = rsData.getString("roll_no");
            }

            // 2. Fetch Transaction History
            String sqlHist = "SELECT amount, type, description, created_at FROM transactions " +
                             "WHERE receiver_id = ? OR sender_id = ? " +
                             "ORDER BY created_at DESC LIMIT 10";
            PreparedStatement pstHist = conn.prepareStatement(sqlHist);
            pstHist.setInt(1, student.getId());
            pstHist.setInt(2, student.getId());
            ResultSet rsHist = pstHist.executeQuery();

            while (rsHist.next()) {
                Map<String, Object> trans = new HashMap<>();
                trans.put("amount", rsHist.getDouble("amount"));
                trans.put("type", rsHist.getString("type"));
                trans.put("desc", rsHist.getString("description"));
                trans.put("date", rsHist.getTimestamp("created_at"));
                history.add(trans);
            }

            // Update session object if needed or just pass attributes
            request.setAttribute("balance", currentBalance);
            request.setAttribute("rollNo", userRollNo);
            request.setAttribute("history", history);
            
            request.getRequestDispatcher("student_dashboard.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            response.getWriter().println("Error loading dashboard data.");
        }
    }
}