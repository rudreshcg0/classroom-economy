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
            response.sendRedirect("login.jsp"); // Updated to .jsp
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            if ("addTeacher".equals(action)) {
                String user = request.getParameter("username");
                String pass = request.getParameter("password");
                
                // UPDATED SQL: Explicitly set must_change_password to TRUE for new teachers
                String sql = "INSERT INTO users (username, password, role, school_id, must_change_password) VALUES (?, ?, 'teacher', ?, TRUE)";
                
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setString(1, user);
                    pst.setString(2, pass);
                    pst.setInt(3, admin.getSchoolId());
                    pst.executeUpdate();
                }
            } 
            // ... (rest of the existing logic for addClass, assignTeacher, deleteUser, etc.)
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
                
                String sql;
                if (teacherId == 0) {
                    sql = "UPDATE classes SET teacher_id = NULL WHERE class_id = ? AND school_id = ?";
                } else {
                    sql = "UPDATE classes SET teacher_id = ? WHERE class_id = ? AND school_id = ?";
                }
                
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    if (teacherId == 0) {
                        pst.setInt(1, classId);
                        pst.setInt(2, admin.getSchoolId());
                    } else {
                        pst.setInt(1, teacherId);
                        pst.setInt(2, classId);
                        pst.setInt(3, admin.getSchoolId());
                    }
                    pst.executeUpdate();
                }
            } 
            else if ("deleteUser".equals(action)) {
                String[] ids = request.getParameterValues("id"); 
                if (ids != null && ids.length > 0) {
                    String sql = "DELETE FROM users WHERE user_id = ? AND school_id = ? AND role != 'school_admin'";
                    try (PreparedStatement pst = conn.prepareStatement(sql)) {
                        for (String idStr : ids) {
                            try {
                                pst.setInt(1, Integer.parseInt(idStr));
                                pst.setInt(2, admin.getSchoolId());
                                pst.addBatch();
                            } catch (NumberFormatException e) {
                                continue; 
                            }
                        }
                        pst.executeBatch();
                    }
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
            
            String redirectView = request.getParameter("view") != null ? request.getParameter("view") : "management";
            response.sendRedirect("adminDashboard?view=" + redirectView + "&success=1");
            
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("adminDashboard?error=db");
        }
    }
}