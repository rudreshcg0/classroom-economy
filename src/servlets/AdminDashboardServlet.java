package servlets;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/adminDashboard")
public class AdminDashboardServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User admin = (User) session.getAttribute("user");
        if (admin == null || !admin.getRole().contains("admin")) { 
            response.sendRedirect("login.html"); 
            return; 
        }

        String view = request.getParameter("view");
        if (view == null) view = "management"; 
        
        String classId = request.getParameter("classId");
        String viewUserId = request.getParameter("viewUserId");

        try (Connection conn = DBConnection.getConnection()) {
            // 1. GLOBAL DATA (Always needed for dropdowns and linking)
            List<Map<String, Object>> classList = new ArrayList<>();
            PreparedStatement pstC = conn.prepareStatement(
                "SELECT c.class_id, c.class_name, u.username as teacher_name " +
                "FROM classes c LEFT JOIN users u ON c.teacher_id = u.user_id WHERE c.school_id = ?"
            );
            pstC.setInt(1, admin.getSchoolId());
            ResultSet rsC = pstC.executeQuery();
            while(rsC.next()){
                Map<String, Object> map = new HashMap<>();
                map.put("id", rsC.getInt("class_id"));
                map.put("name", rsC.getString("class_name"));
                map.put("teacher", rsC.getString("teacher_name"));
                classList.add(map);
            }
            request.setAttribute("classList", classList);

            // Fetch ALL teachers in school (for the Linking dropdown)
            List<User> schoolTeachers = new ArrayList<>();
            PreparedStatement pstAllT = conn.prepareStatement("SELECT user_id, username FROM users WHERE school_id = ? AND role = 'teacher'");
            pstAllT.setInt(1, admin.getSchoolId());
            ResultSet rsAllT = pstAllT.executeQuery();
            while(rsAllT.next()){
                schoolTeachers.add(new User(rsAllT.getInt("user_id"), rsAllT.getString("username"), "teacher", admin.getSchoolId()));
            }
            request.setAttribute("schoolTeachers", schoolTeachers);

            // 2. CLASS-SPECIFIC DATA (Fetch only if a class is selected)
            if (classId != null && !classId.isEmpty()) {
                int cid = Integer.parseInt(classId);
                
                // Fetch ONLY the teacher(s) assigned to this class
                List<User> classTeachers = new ArrayList<>();
                PreparedStatement pstT = conn.prepareStatement(
                    "SELECT u.user_id, u.username FROM users u " +
                    "JOIN classes c ON u.user_id = c.teacher_id WHERE c.class_id = ?"
                );
                pstT.setInt(1, cid);
                ResultSet rsT = pstT.executeQuery();
                while(rsT.next()) { 
                    classTeachers.add(new User(rsT.getInt("user_id"), rsT.getString("username"), "teacher", admin.getSchoolId())); 
                }

                // Fetch ONLY the students enrolled in this class
                List<User> classStudents = new ArrayList<>();
                PreparedStatement pstS = conn.prepareStatement(
                    "SELECT u.user_id, u.username, u.roll_no FROM users u " +
                    "JOIN student_classes sc ON u.user_id = sc.student_id WHERE sc.class_id = ?"
                );
                pstS.setInt(1, cid);
                ResultSet rsS = pstS.executeQuery();
                while(rsS.next()) { 
                    classStudents.add(new User(rsS.getInt("user_id"), rsS.getString("username"), "student", admin.getSchoolId(), 0.0, rsS.getString("roll_no"))); 
                }

                request.setAttribute("classTeachers", classTeachers);
                request.setAttribute("classStudents", classStudents);
                request.setAttribute("selectedClassId", classId);
            }

            // 3. AUDIT DRILL-DOWN (Fetch history for a specific person)
            if (viewUserId != null) {
                List<Map<String, Object>> history = new ArrayList<>();
                PreparedStatement pstH = conn.prepareStatement(
                    "SELECT t.*, u1.username as s_name, u2.username as r_name FROM transactions t " +
                    "LEFT JOIN users u1 ON t.sender_id = u1.user_id " +
                    "LEFT JOIN users u2 ON t.receiver_id = u2.user_id " +
                    "WHERE t.sender_id = ? OR t.receiver_id = ? ORDER BY t.created_at DESC"
                );
                int uid = Integer.parseInt(viewUserId);
                pstH.setInt(1, uid); pstH.setInt(2, uid);
                ResultSet rsH = pstH.executeQuery();
                while(rsH.next()){
                    Map<String, Object> tx = new HashMap<>();
                    tx.put("date", rsH.getTimestamp("created_at"));
                    tx.put("sender", rsH.getString("s_name") == null ? "SYSTEM" : rsH.getString("s_name"));
                    tx.put("receiver", rsH.getString("r_name"));
                    tx.put("amount", rsH.getDouble("amount"));
                    tx.put("type", rsH.getString("type"));
                    history.add(tx);
                }
                request.setAttribute("history", history);
                
                // Get name for header
                PreparedStatement pstN = conn.prepareStatement("SELECT username FROM users WHERE user_id = ?");
                pstN.setInt(1, uid);
                ResultSet rsN = pstN.executeQuery();
                if(rsN.next()) request.setAttribute("targetName", rsN.getString("username"));
            }

            request.setAttribute("currentView", view);
            request.getRequestDispatcher("admin_dashboard.jsp").forward(request, response);
        } catch (SQLException e) { e.printStackTrace(); }
    }
}