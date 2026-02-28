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
            // UPDATED SQL: Selecting profile fields along with credentials
            String sql = "SELECT user_id, username, role, school_id, roll_no, must_change_password, full_name, email, birthdate FROM users WHERE username = ? AND password = ?";
            
            PreparedStatement pst = conn.prepareStatement(sql);
            pst.setString(1, userParam);
            pst.setString(2, passParam);

            ResultSet rs = pst.executeQuery();

            if (rs.next()) {
                Object schoolIdObj = rs.getObject("school_id");
                Integer schoolId = (schoolIdObj != null) ? (Integer) schoolIdObj : null;

                // Creating User object using the FULL CONSTRUCTOR
                // Note: Balance is initialized here as 0.0; studentDashboard/adminDashboard servlets 
                // will update the specific wallet/allowance balances in the session later.
                User loggedInUser = new User(
                    rs.getInt("user_id"),
                    rs.getString("username"),
                    rs.getString("role"),
                    schoolId,
                    0.0, 
                    rs.getString("roll_no"),
                    rs.getString("full_name"),
                    rs.getString("email"),
                    rs.getString("birthdate")
                );
                
                HttpSession session = request.getSession();
                session.setAttribute("user", loggedInUser);

                String role = loggedInUser.getRole().toLowerCase();
                boolean mustChange = rs.getBoolean("must_change_password");

                // --- STEP 1: PASSWORD CHANGE INTERCEPTION ---
                if (mustChange && !role.equals("platform_root")) {
                    response.sendRedirect("change_password.jsp");
                    return; 
                }

                // --- STEP 2: ROLE-BASED DASHBOARD REDIRECTS ---
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