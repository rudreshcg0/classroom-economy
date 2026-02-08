package servlets;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/login")
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
                // 1. Create User object
                User loggedInUser = new User(
                    rs.getInt("user_id"),
                    rs.getString("username"),
                    rs.getString("role"),
                    rs.getInt("school_id")
                );
                
                // 2. Start a Session and save the User object
                HttpSession session = request.getSession();
                session.setAttribute("user", loggedInUser);

                // 3. Updated Redirect Logic for all roles
                String role = loggedInUser.getRole().toLowerCase();

                if (role.equals("teacher")) {
                    response.sendRedirect("teacherDashboard"); 
                } else if (role.equals("student")) {
                    response.sendRedirect("studentDashboard");
                } else if (role.equals("super_admin")) {
                    response.sendRedirect("adminDashboard");
                } else {
                    // If role is school_admin or something else we haven't built yet
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