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
            // We fetch school_id and roll_no to build a complete User object
            String sql = "SELECT user_id, username, role, school_id, roll_no FROM users WHERE username = ? AND password = ?";
            PreparedStatement pst = conn.prepareStatement(sql);
            pst.setString(1, userParam);
            pst.setString(2, passParam);

            ResultSet rs = pst.executeQuery();

            if (rs.next()) {
                // FIX: Retrieve school_id as an Object to handle NULL safely
                Object schoolIdObj = rs.getObject("school_id");
                Integer schoolId = (schoolIdObj != null) ? (Integer) schoolIdObj : null;

                User loggedInUser = new User(
                    rs.getInt("user_id"),
                    rs.getString("username"),
                    rs.getString("role"),
                    schoolId,
                    0.0, // Balance is usually fetched separately in dashboards
                    rs.getString("roll_no")
                );
                
                HttpSession session = request.getSession();
                session.setAttribute("user", loggedInUser);

                String role = loggedInUser.getRole().toLowerCase();

                // REDIRECT LOGIC
                if (role.equals("platform_root")) {
                    response.sendRedirect("super_dashboard.jsp"); 
                } else if (role.equals("super_admin") || role.equals("school_admin")) {
                    response.sendRedirect("adminDashboard");
                } else if (role.equals("teacher")) {
                    response.sendRedirect("teacherDashboard"); 
                } else if (role.equals("student")) {
                    response.sendRedirect("studentDashboard");
                } else {
                    response.sendRedirect("login.html?error=unauthorized");
                }

            } else {
                response.sendRedirect("login.html?error=invalid");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("login.html?error=database");
        }
    }
}