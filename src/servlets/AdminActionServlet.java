package servlets;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/adminAction")
public class AdminActionServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User admin = (User) session.getAttribute("user");
        String action = request.getParameter("action");

        // Basic Security Check
        if (admin == null || admin.getSchoolId() == null) {
            response.sendRedirect("login.html");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            if ("addTeacher".equals(action)) {
                String user = request.getParameter("username");
                String pass = request.getParameter("password");
                String sql = "INSERT INTO users (username, password, role, school_id) VALUES (?, ?, 'teacher', ?)";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setString(1, user);
                    pst.setString(2, pass);
                    pst.setInt(3, admin.getSchoolId());
                    pst.executeUpdate();
                }
            } 
            else if ("addClass".equals(action)) {
                String className = request.getParameter("className");
                double pay = Double.parseDouble(request.getParameter("payRate"));
                String sql = "INSERT INTO classes (class_name, pay_per_session, school_id) VALUES (?, ?, ?)";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setString(1, className);
                    pst.setDouble(2, pay);
                    pst.setInt(3, admin.getSchoolId());
                    pst.executeUpdate();
                }
            } 
            else if ("assignTeacher".equals(action)) {
                int classId = Integer.parseInt(request.getParameter("classId"));
                int teacherId = Integer.parseInt(request.getParameter("teacherId"));
                String sql = "UPDATE classes SET teacher_id = ? WHERE class_id = ? AND school_id = ?";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setInt(1, teacherId);
                    pst.setInt(2, classId);
                    pst.setInt(3, admin.getSchoolId());
                    pst.executeUpdate();
                }
            } 
            else if ("deleteUser".equals(action)) {
                int targetId = Integer.parseInt(request.getParameter("id"));
                // Cannot delete self, only users in same school
                String sql = "DELETE FROM users WHERE user_id = ? AND school_id = ? AND role != 'school_admin'";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setInt(1, targetId);
                    pst.setInt(2, admin.getSchoolId());
                    pst.executeUpdate();
                }
            } 
            else if ("deleteClass".equals(action)) {
                int classId = Integer.parseInt(request.getParameter("id"));
                String sql = "DELETE FROM classes WHERE class_id = ? AND school_id = ?";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setInt(1, classId);
                    pst.setInt(2, admin.getSchoolId());
                    pst.executeUpdate();
                }
            }
            // Redirect back to dashboard to see changes
            response.sendRedirect("adminDashboard?success=1");
            
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("adminDashboard?error=db");
        }
    }
}