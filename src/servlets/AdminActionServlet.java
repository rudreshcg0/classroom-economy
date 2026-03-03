package servlets;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;
import org.mindrot.jbcrypt.BCrypt;

@WebServlet("/adminAction")
public class AdminActionServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User admin = (session != null) ? (User) session.getAttribute("user") : null;
        String action = request.getParameter("action");

        // --- SECURITY: Strict Role & Session Validation ---
        // We check for both 'super_admin' and 'school_admin' roles explicitly
        if (admin == null || admin.getSchoolId() == null) {
            response.sendRedirect("login.jsp?error=unauthorized");
            return;
        }
        
        String role = admin.getRole().toLowerCase();
        if (!role.equals("super_admin") && !role.equals("school_admin")) {
            response.sendRedirect("login.jsp?error=unauthorized");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            // --- ACTION: Register Staff (Teacher) ---
            if ("addTeacher".equals(action)) {
                String user = request.getParameter("username");
                String pass = request.getParameter("password");
                
                // SECURITY: Hash password before saving to DB
                String hashedPass = BCrypt.hashpw(pass, BCrypt.gensalt(12));

                String sql = "INSERT INTO users (username, password, role, school_id, must_change_password) VALUES (?, ?, 'teacher', ?, TRUE)";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setString(1, user);
                    pst.setString(2, hashedPass); 
                    pst.setInt(3, admin.getSchoolId());
                    pst.executeUpdate();
                }
            } 
            
            // --- ACTION: Create New Class ---
            else if ("addClass".equals(action)) {
                String className = request.getParameter("className");
                String payStr = request.getParameter("payRate");
                double pay = (payStr != null) ? Double.parseDouble(payStr) : 10.00;
                
                String sql = "INSERT INTO classes (class_name, pay_per_session, school_id) VALUES (?, ?, ?)";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setString(1, className);
                    pst.setDouble(2, pay);
                    pst.setInt(3, admin.getSchoolId());
                    pst.executeUpdate();
                }
            } 
            
            // --- ACTION: Assign Teacher to Class ---
            else if ("assignTeacher".equals(action)) {
                int classId = Integer.parseInt(request.getParameter("classId"));
                int teacherId = Integer.parseInt(request.getParameter("teacherId"));
                
                // SECURITY: Verify the class belongs to this admin's school
                String sql = (teacherId == 0) ? 
                    "UPDATE classes SET teacher_id = NULL WHERE class_id = ? AND school_id = ?" :
                    "UPDATE classes SET teacher_id = ? WHERE class_id = ? AND school_id = ?";
                
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
            
            // --- ACTION: Terminate Accounts ---
            else if ("deleteUser".equals(action)) {
                String[] ids = request.getParameterValues("id"); 
                if (ids != null) {
                    // SECURITY: Cannot delete themselves or other admins
                    String sql = "DELETE FROM users WHERE user_id = ? AND school_id = ? AND role NOT IN ('school_admin', 'super_admin')";
                    try (PreparedStatement pst = conn.prepareStatement(sql)) {
                        for (String idStr : ids) {
                            pst.setInt(1, Integer.parseInt(idStr));
                            pst.setInt(2, admin.getSchoolId());
                            pst.addBatch();
                        }
                        pst.executeBatch();
                    }
                }
            }

            // DYNAMIC REDIRECT
            String redirectView = request.getParameter("view") != null ? request.getParameter("view") : "management";
            response.sendRedirect("adminDashboard?view=" + redirectView + "&success=1");
            
        } catch (SQLException | NumberFormatException e) {
            e.printStackTrace();
            response.sendRedirect("adminDashboard?error=db");
        }
    }
}