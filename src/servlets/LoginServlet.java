package servlets;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet; // Added for easy URL mapping
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/login") // This maps the servlet to the /login URL
public class LoginServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String user = request.getParameter("username");
        String pass = request.getParameter("password");

        try (Connection conn = DBConnection.getConnection()) {
            // Query to verify user and get their core details
            String sql = "SELECT user_id, username, role, school_id FROM users WHERE username = ? AND password = ?";
            PreparedStatement pst = conn.prepareStatement(sql);
            pst.setString(1, user);
            pst.setString(2, pass);

            ResultSet rs = pst.executeQuery();

            if (rs.next()) {
                // 1. Create User object using the 4-argument constructor
                User loggedInUser = new User(
                    rs.getInt("user_id"),
                    rs.getString("username"),
                    rs.getString("role"),
                    rs.getInt("school_id")
                );
                
                // 2. Start a Session and save the User object
                HttpSession session = request.getSession();
                session.setAttribute("user", loggedInUser);

                // 3. Phase 2 Redirect Strategy: 
                // We send them to SERVLETS (the "Kitchen") not JSPs (the "Table")
                if (loggedInUser.getRole().equalsIgnoreCase("teacher")) {
                    response.sendRedirect("teacherDashboard"); 
                } else if (loggedInUser.getRole().equalsIgnoreCase("student")) {
                    response.sendRedirect("studentDashboard");
                } else {
                    // Fallback for admins or undefined roles
                    response.sendRedirect("login.html?error=unauthorized");
                }
            } else {
                // Invalid credentials
                response.sendRedirect("login.html?error=invalid");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("login.html?error=database");
        }
    }
}