package servlets;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;
// Use a library like jBCrypt (org.mindrot.jbcrypt)
import org.mindrot.jbcrypt.BCrypt;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String userParam = request.getParameter("username");
        String passParam = request.getParameter("password");

        // Basic null check for input
        if (userParam == null || passParam == null) {
            response.sendRedirect("login.jsp?error=invalid");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            // SECURITY UPDATE: We no longer check the password in the SQL query.
            // We only fetch the record by username and then verify the hash in Java.
            String sql = "SELECT user_id, username, password, role, school_id, roll_no, must_change_password, full_name, email, birthdate FROM users WHERE username = ?";
            
            PreparedStatement pst = conn.prepareStatement(sql);
            pst.setString(1, userParam);

            ResultSet rs = pst.executeQuery();

            if (rs.next()) {
                String storedHash = rs.getString("password");

                // SECURITY UPDATE: Verify the plain-text password against the stored BCrypt hash
                if (BCrypt.checkpw(passParam, storedHash)) {
                    
                    Object schoolIdObj = rs.getObject("school_id");
                    Integer schoolId = (schoolIdObj != null) ? (Integer) schoolIdObj : null;

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
                    
                    // SECURITY UPDATE: Session Fixation Protection
                    // Invalidate old session if it exists and create a brand new one
                    HttpSession oldSession = request.getSession(false);
                    if (oldSession != null) {
                        oldSession.invalidate();
                    }
                    HttpSession session = request.getSession(true);
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
                    // Password does not match hash
                    response.sendRedirect("login.jsp?error=invalid");
                }
            } else {
                // User not found
                response.sendRedirect("login.jsp?error=invalid");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("login.jsp?error=database");
        }
    }
}