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
        String userParam = request.getParameter("username");
        String passParam = request.getParameter("password");

        try (Connection conn = DBConnection.getConnection()) {
            // Fetching credentials and the 'must_change_password' flag
            String sql = "SELECT user_id, username, role, school_id, roll_no, must_change_password FROM users WHERE username = ? AND password = ?";
            PreparedStatement pst = conn.prepareStatement(sql);
            pst.setString(1, userParam);
            pst.setString(2, passParam);

            ResultSet rs = pst.executeQuery();

            if (rs.next()) {
                Object schoolIdObj = rs.getObject("school_id");
                Integer schoolId = (schoolIdObj != null) ? (Integer) schoolIdObj : null;

                // Create User object for the session
                User loggedInUser = new User(
                    rs.getInt("user_id"),
                    rs.getString("username"),
                    rs.getString("role"),
                    schoolId,
                    0.0,
                    rs.getString("roll_no")
                );
                
                HttpSession session = request.getSession();
                session.setAttribute("user", loggedInUser);

                String role = loggedInUser.getRole().toLowerCase();
                boolean mustChange = rs.getBoolean("must_change_password");

                // --- STEP 1: THE INTERCEPTION ---
                // If flag is TRUE and user is NOT platform_root, force them to change password
                if (mustChange && !role.equals("platform_root")) {
                    response.sendRedirect("change_password.jsp");
                    return; // Crucial: Stop execution so they don't hit the dashboard redirects below
                }

                // --- STEP 2: DASHBOARD REDIRECTS ---
                if (role.equals("platform_root")) {
                    response.sendRedirect("super_dashboard.jsp"); 
                } else if (role.equals("super_admin") || role.equals("school_admin")) {
                    response.sendRedirect("adminDashboard");
                } else if (role.equals("teacher")) {
                    response.sendRedirect("teacherDashboard"); 
                } else if (role.equals("student")) {
                    response.sendRedirect("studentDashboard");
                } else {
                    response.sendRedirect("login.jsp?error=unauthorized");
                }

            } else {
                // Wrong username or password
                response.sendRedirect("login.jsp?error=invalid");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("login.jsp?error=database");
        }
    }
}