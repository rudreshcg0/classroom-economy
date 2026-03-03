package servlets;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;
import org.mindrot.jbcrypt.BCrypt; // Required for secure password hashing

@WebServlet("/adminAction")
public class AdminActionServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User admin = (session != null) ? (User) session.getAttribute("user") : null;
        String action = request.getParameter("action");

        // --- SECURITY: Strict Role & Session Validation ---
        // Prevents unauthorized users or non-admins from hitting this endpoint
        if (admin == null || admin.getSchoolId() == null || !admin.isAdmin()) {
            response.sendRedirect("login.jsp?error=unauthorized");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            // --- ACTION: Register Staff (Teacher) ---
            if ("addTeacher".equals(action)) {
                String user = request.getParameter("username");
                String pass = request.getParameter("password");
                
                // SECURITY: Hash password with BCrypt before saving to DB
                String hashedPass = BCrypt.hashpw(pass, BCrypt.gensalt());

                String sql = "INSERT INTO users (username, password, role, school_id, must_change_password) VALUES (?, ?, 'teacher', ?, TRUE)";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setString(1, user);
                    pst.setString(2, hashedPass); // Save hash, not plain text
                    pst.setInt(3, admin.getSchoolId()); // Forced data isolation
                    pst.executeUpdate();
                }
            } 
            
            // --- ACTION: Create New Class ---
            else if ("addClass".equals(action)) {
                String className = request.getParameter("className");
                double pay = Double.parseDouble(request.getParameter("payRate"));
                
                String sql = "INSERT INTO classes (class_name, pay_per_session, school_id) VALUES (?, ?, ?)";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setString(1, className);
                    pst.setDouble(2, pay);
                    pst.setInt(3, admin.getSchoolId()); // Data isolation
                    pst.executeUpdate();
                }
            } 
            
            // --- ACTION: Assign Teacher to Class ---
            else if ("assignTeacher".equals(action)) {
                int classId = Integer.parseInt(request.getParameter("classId"));
                int teacherId = Integer.parseInt(request.getParameter("teacherId"));
                
                // SECURITY: Verify the class belongs to this admin's school before updating
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
                    // SECURITY: Ensure admin cannot delete themselves or users outside their school
                    String sql = "DELETE FROM users WHERE user_id = ? AND school_id = ? AND role != 'school_admin' AND role != 'super_admin'";
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
            
            // --- ACTION: Set Teacher Daily Limit ---
            else if ("setDailyLimit".equals(action)) {
                int teacherId = Integer.parseInt(request.getParameter("teacherId"));
                double limit = Double.parseDouble(request.getParameter("dailyLimit"));
                
                // SECURITY: UPSERT logic with school_id check for isolation
                String sql = "INSERT INTO teacher_allowance (teacher_id, daily_limit, temp_extension, school_id) " +
                             "VALUES (?, ?, 0, ?) ON CONFLICT (teacher_id) " +
                             "DO UPDATE SET daily_limit = EXCLUDED.daily_limit WHERE teacher_allowance.school_id = ?";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setInt(1, teacherId);
                    pst.setDouble(2, limit);
                    pst.setInt(3, admin.getSchoolId());
                    pst.setInt(4, admin.getSchoolId());
                    pst.executeUpdate();
                }
            }
            
            // --- ACTION: Handle Extension Requests ---
            else if ("handleLimitRequest".equals(action)) {
                int requestId = Integer.parseInt(request.getParameter("requestId"));
                String status = request.getParameter("status"); 
                
                conn.setAutoCommit(false);
                try {
                    // SECURITY: Verify the request belongs to this school via a JOIN or school_id check
                    String sqlUpdate = "UPDATE limit_requests SET status = ? WHERE request_id = ? AND school_id = ? RETURNING teacher_id, requested_amount";
                    try (PreparedStatement pst = conn.prepareStatement(sqlUpdate)) {
                        pst.setString(1, status);
                        pst.setInt(2, requestId);
                        pst.setInt(3, admin.getSchoolId());
                        ResultSet rs = pst.executeQuery();
                        
                        if ("APPROVED".equals(status) && rs.next()) {
                            int tId = rs.getInt("teacher_id");
                            double amount = rs.getDouble("requested_amount");
                            
                            String sqlExt = "UPDATE teacher_allowance SET temp_extension = temp_extension + ? WHERE teacher_id = ? AND school_id = ?";
                            try (PreparedStatement pstExt = conn.prepareStatement(sqlExt)) {
                                pstExt.setDouble(1, amount);
                                pstExt.setInt(2, tId);
                                pstExt.setInt(3, admin.getSchoolId());
                                pstExt.executeUpdate();
                            }
                        }
                    }
                    conn.commit();
                } catch (Exception e) { conn.rollback(); throw e; }
            }

            // DYNAMIC REDIRECT
            String redirectView = request.getParameter("view") != null ? request.getParameter("view") : "management";
            String activeTab = request.getParameter("activeTab") != null ? "&activeTab=" + request.getParameter("activeTab") : "";
            response.sendRedirect("adminDashboard?view=" + redirectView + activeTab + "&success=1");
            
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("adminDashboard?error=db");
        }
    }
}