package servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import models.User;
import utils.DBConnection;
import java.io.IOException;
import java.sql.*;
import java.util.*;

@WebServlet("/rewardAction")
public class RewardServlet extends HttpServlet {

    private void loadDashboardData(HttpServletRequest request, User teacher, Connection conn) throws SQLException {
        List<Map<String, Object>> classes = new ArrayList<>();
        // SECURITY: Forced isolation by school and teacher
        PreparedStatement ps = conn.prepareStatement("SELECT class_id, class_name FROM classes WHERE teacher_id = ? AND school_id = ?");
        ps.setInt(1, teacher.getId());
        ps.setInt(2, teacher.getSchoolId());
        ResultSet rs = ps.executeQuery();
        while (rs.next()) {
            Map<String, Object> c = new HashMap<>();
            c.put("id", rs.getInt("class_id"));
            c.put("name", rs.getString("class_name"));
            classes.add(c);
        }
        request.setAttribute("classes", classes);
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User teacher = (session != null) ? (User) session.getAttribute("user") : null;
        if (teacher == null || !"teacher".equalsIgnoreCase(teacher.getRole())) { 
            response.sendRedirect("login.jsp?error=unauthorized"); 
            return; 
        }

        String action = request.getParameter("action");

        try (Connection conn = DBConnection.getConnection()) {
            if ("getTeacherRewards".equals(action)) {
                sendRewardListJson(response, conn, teacher, request.getParameter("type"));
                return;
            }

            loadDashboardData(request, teacher, conn);
            
            List<Map<String, Object>> teacherRewards = new ArrayList<>();
            // SECURITY: Only fetch blocks belonging to this teacher
            PreparedStatement psT = conn.prepareStatement("SELECT * FROM reward_types WHERE teacher_id = ? ORDER BY name ASC");
            psT.setInt(1, teacher.getId());
            ResultSet rsT = psT.executeQuery();
            while (rsT.next()) {
                Map<String, Object> r = new HashMap<>();
                r.put("id", rsT.getInt("id"));
                r.put("name", rsT.getString("name"));
                r.put("amount", rsT.getDouble("amount"));
                r.put("icon", rsT.getString("icon"));
                teacherRewards.add(r);
            }
            request.setAttribute("teacherRewardTypes", teacherRewards);

            String classId = request.getParameter("classId");
            if (classId != null && !classId.isEmpty()) {
                List<User> students = new ArrayList<>();
                // SECURITY: Verify class belongs to teacher's school
                String sql = "SELECT u.user_id, u.username, u.roll_no, w.balance FROM users u " +
                             "JOIN student_classes sc ON u.user_id = sc.student_id " +
                             "JOIN wallets w ON u.user_id = w.student_id " +
                             "WHERE sc.class_id = ? AND u.school_id = ? ORDER BY u.roll_no ASC";
                PreparedStatement psS = conn.prepareStatement(sql);
                psS.setInt(1, Integer.parseInt(classId));
                psS.setInt(2, teacher.getSchoolId());
                ResultSet rsS = psS.executeQuery();
                while (rsS.next()) {
                    User s = new User();
                    s.setId(rsS.getInt("user_id"));
                    s.setUsername(rsS.getString("username"));
                    s.setRollNo(rsS.getString("roll_no"));
                    s.setBalance(rsS.getDouble("balance"));
                    students.add(s);
                }
                request.setAttribute("rewardStudents", students);
                request.setAttribute("selectedRewardClass", classId);
            }
            request.getRequestDispatcher("teacher_dashboard.jsp").forward(request, response);
        } catch (Exception e) { 
            e.printStackTrace(); 
            response.sendRedirect("teacherDashboard?error=db"); 
        }
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User teacher = (session != null) ? (User) session.getAttribute("user") : null;
        if (teacher == null || !"teacher".equalsIgnoreCase(teacher.getRole())) { 
            response.sendRedirect("login.jsp?error=unauthorized"); 
            return; 
        }

        String action = request.getParameter("action");

        try (Connection conn = DBConnection.getConnection()) {
            if ("processReward".equals(action)) {
                processBulkReward(request, response, conn, teacher);
            } else if ("addRewardType".equals(action)) {
                handleAddReward(request, response, conn, teacher);
            } else if ("deleteRewardType".equals(action)) {
                handleDeleteReward(request, response, conn, teacher);
            } else if ("requestLimitIncrease".equals(action)) {
                handleLimitRequest(request, response, conn, teacher);
            }
        } catch (Exception e) { 
            e.printStackTrace(); 
            response.sendRedirect("teacherDashboard?error=system");
        }
    }

    private void processBulkReward(HttpServletRequest request, HttpServletResponse response, Connection conn, User teacher) throws Exception {
        String[] studentIds = request.getParameterValues("selectedStudents");
        String rewardIdStr = request.getParameter("rewardId");
        
        if (studentIds == null || rewardIdStr == null) {
            response.sendRedirect("teacherDashboard?error=no_selection");
            return;
        }

        // SECURITY: Verify reward block belongs to this teacher
        PreparedStatement psR = conn.prepareStatement("SELECT name, amount FROM reward_types WHERE id = ? AND teacher_id = ?");
        psR.setInt(1, Integer.parseInt(rewardIdStr));
        psR.setInt(2, teacher.getId());
        ResultSet rsR = psR.executeQuery();

        if (rsR.next()) {
            double amountPerStudent = rsR.getDouble("amount");
            String rewardName = rsR.getString("name");
            double totalRewardCost = (amountPerStudent > 0) ? (amountPerStudent * studentIds.length) : 0;

            // 1. Velocity Check (Daily Budget)
            if (amountPerStudent > 0) {
                double dailyLimit = 0, tempExtension = 0, spentToday = 0;
                
                PreparedStatement psL = conn.prepareStatement("SELECT monthly_budget, temp_extension FROM teacher_allowance WHERE teacher_id = ?");
                psL.setInt(1, teacher.getId());
                ResultSet rsL = psL.executeQuery();
                if (rsL.next()) {
                    dailyLimit = rsL.getDouble("monthly_budget"); // Schema naming check
                    tempExtension = rsL.getDouble("temp_extension");
                }

                PreparedStatement psS = conn.prepareStatement("SELECT SUM(amount) FROM transactions WHERE sender_id = ? AND type = 'REWARD_AWARD' AND created_at >= CURRENT_DATE");
                psS.setInt(1, teacher.getId());
                ResultSet rsS = psS.executeQuery();
                if (rsS.next()) spentToday = rsS.getDouble(1);

                if (spentToday + totalRewardCost > (dailyLimit + tempExtension)) {
                    response.sendRedirect("teacherDashboard?error=limit_exceeded");
                    return;
                }
            }

            // 2. Transactional Update
            conn.setAutoCommit(false);
            try {
                PreparedStatement upW = conn.prepareStatement("UPDATE wallets SET balance = balance + ? WHERE student_id = ? AND school_id = ?");
                PreparedStatement log = conn.prepareStatement(
                    "INSERT INTO transactions (sender_id, receiver_id, amount, type, description, school_id) VALUES (?, ?, ?, ?, ?, ?)"
                );

                for (String sId : studentIds) {
                    int studentId = Integer.parseInt(sId);
                    
                    upW.setDouble(1, amountPerStudent);
                    upW.setInt(2, studentId);
                    upW.setInt(3, teacher.getSchoolId());
                    upW.addBatch();
                    
                    int finalSender = (amountPerStudent >= 0) ? teacher.getId() : studentId;
                    int finalReceiver = (amountPerStudent >= 0) ? studentId : teacher.getId();
                    String finalType = (amountPerStudent >= 0) ? "REWARD_AWARD" : "REWARD_DEDUCT";

                    log.setInt(1, finalSender);
                    log.setInt(2, finalReceiver);
                    log.setDouble(3, Math.abs(amountPerStudent));
                    log.setString(4, finalType);
                    log.setString(5, (amountPerStudent >= 0 ? "Award: " : "Deduct: ") + rewardName);
                    log.setInt(6, teacher.getSchoolId());
                    log.addBatch();
                }
                upW.executeBatch();
                log.executeBatch();
                conn.commit();
                response.sendRedirect("teacherDashboard?success=reward_processed");
            } catch (Exception e) {
                conn.rollback();
                throw e;
            }
        }
    }

    private void handleAddReward(HttpServletRequest request, HttpServletResponse response, Connection conn, User teacher) throws Exception {
        PreparedStatement ps = conn.prepareStatement("INSERT INTO reward_types (teacher_id, name, amount, icon, is_positive) VALUES (?, ?, ?, ?, ?) RETURNING id");
        ps.setInt(1, teacher.getId());
        ps.setString(2, request.getParameter("name"));
        double amt = Double.parseDouble(request.getParameter("amount"));
        ps.setDouble(3, amt);
        ps.setString(4, request.getParameter("icon"));
        ps.setBoolean(5, amt >= 0);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            response.setContentType("application/json");
            response.getWriter().write("{\"status\":\"success\", \"id\":" + rs.getInt("id") + "}");
        }
    }

    private void handleDeleteReward(HttpServletRequest request, HttpServletResponse response, Connection conn, User teacher) throws Exception {
        PreparedStatement ps = conn.prepareStatement("DELETE FROM reward_types WHERE id = ? AND teacher_id = ?");
        ps.setInt(1, Integer.parseInt(request.getParameter("rewardId")));
        ps.setInt(2, teacher.getId());
        ps.executeUpdate();
        response.setContentType("application/json");
        response.getWriter().write("{\"status\":\"success\"}");
    }

    private void handleLimitRequest(HttpServletRequest request, HttpServletResponse response, Connection conn, User teacher) throws Exception {
        // SECURITY: Ensure request is logged to valid table
        String sql = "INSERT INTO limit_requests (teacher_id, school_id, requested_amount, reason) VALUES (?, ?, ?, ?)";
        try (PreparedStatement pst = conn.prepareStatement(sql)) {
            pst.setInt(1, teacher.getId());
            pst.setInt(2, teacher.getSchoolId());
            pst.setDouble(3, Double.parseDouble(request.getParameter("amount")));
            pst.setString(4, request.getParameter("reason"));
            pst.executeUpdate();
        }
        response.sendRedirect("teacherDashboard?success=request_sent");
    }

    private void sendRewardListJson(HttpServletResponse response, Connection conn, User teacher, String type) throws Exception {
        response.setContentType("application/json");
        // SECURITY: Added parentheses for logical separation in OR query
        String sql = "SELECT * FROM reward_types WHERE (teacher_id = ? OR teacher_id IS NULL)";
        if ("award".equals(type)) sql += " AND amount > 0";
        else if ("deduct".equals(type)) sql += " AND amount < 0";
        sql += " ORDER BY is_positive DESC, name ASC";

        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setInt(1, teacher.getId());
        ResultSet rs = ps.executeQuery();
        
        List<String> jsonItems = new ArrayList<>();
        while (rs.next()) {
            jsonItems.add(String.format("{\"id\":%d,\"name\":\"%s\",\"amount\":%.2f,\"icon\":\"%s\",\"isPositive\":%b}",
                rs.getInt("id"), rs.getString("name"), rs.getDouble("amount"), rs.getString("icon"), rs.getBoolean("is_positive")));
        }
        response.getWriter().write("{\"rewards\":[" + String.join(",", jsonItems) + "]}");
    }
}