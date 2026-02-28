package servlets;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/updateProfile")
public class UpdateProfileServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String birthdate = request.getParameter("birthdate");

        try (Connection conn = DBConnection.getConnection()) {
            String sql = "UPDATE users SET birthdate = ?::DATE WHERE user_id = ?";
            try (PreparedStatement pst = conn.prepareStatement(sql)) {
                pst.setString(1, birthdate);
                pst.setInt(2, user.getId());
                pst.executeUpdate();
            }
            
            // Update the session object so the UI reflects the change immediately
            user.setBirthdate(birthdate);
            session.setAttribute("user", user);
            
            response.sendRedirect("studentDashboard?profileUpdated=1");
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("studentDashboard?error=1");
        }
    }
}