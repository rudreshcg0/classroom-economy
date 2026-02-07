package servlets;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

public class LoginServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String user = request.getParameter("username");
        String pass = request.getParameter("password");

        try (Connection conn = DBConnection.getConnection()) {
            // Query to verify user and get their role/school
            String sql = "SELECT * FROM users WHERE username = ? AND password = ?";
            PreparedStatement pst = conn.prepareStatement(sql);
            pst.setString(1, user);
            pst.setString(2, pass);

            ResultSet rs = pst.executeQuery();

            if (rs.next()) {
                // User found! Store their info in a Session
                User loggedInUser = new User(
                    rs.getInt("user_id"),
                    rs.getString("username"),
                    rs.getString("role"),
                    rs.getInt("school_id")
                );
                
                HttpSession session = request.getSession();
                session.setAttribute("user", loggedInUser);

                // Redirect based on Role (RBAC)
                if (loggedInUser.getRole().equals("teacher")) {
                    response.sendRedirect("teacher_dashboard.jsp");
                } else {
                    response.sendRedirect("student_dashboard.jsp");
                }
            } else {
                response.sendRedirect("login.html?error=invalid");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}