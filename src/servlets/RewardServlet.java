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
        PreparedStatement ps = conn.prepareStatement("SELECT class_id, class_name FROM classes WHERE teacher_id = ?");
        ps.setInt(1, teacher.getId());
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
        if (teacher == null) { response.sendRedirect("login.jsp"); return; }

        String action = request.getParameter("action");

        try (Connection conn = DBConnection.getConnection()) {
            if ("getTeacherRewards".equals(action)) {
                sendRewardListJson(response, conn, teacher, request.getParameter("type"));
                return;
            }

            loadDashboardData(request, teacher, conn);
            
            List<Map<String, Object>> teacherRewards = new ArrayList<>();
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
                String sql = "SELECT u.user_id, u.username, u.roll_no, w.balance FROM users u " +
                             "JOIN student_classes sc ON u.user_id = sc.student_id " +
                             "JOIN wallets w ON u.user_id = w.student_id WHERE sc.class_id = ? ORDER BY u.roll_no ASC";
                PreparedStatement psS = conn.prepareStatement(sql);
                psS.setInt(1, Integer.parseInt(classId));
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
            request.getRequestDispatcher("teacherDashboard?tab=overview").forward(request, response);
        } catch (Exception e) { e.printStackTrace(); response.sendRedirect("teacherDashboard?error=db"); }
    }

    private void sendRewardListJson(HttpServletResponse response, Connection conn, User teacher, String type) throws Exception {
        response.setContentType("application/json");
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

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User teacher = (User) session.getAttribute("user");
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
        } catch (Exception e) { e.printStackTrace(); }
    }

    private void processBulkReward(HttpServletRequest request, HttpServletResponse response, Connection conn, User teacher) throws Exception {
        String[] studentIds = request.getParameterValues("selectedStudents");
        int rewardId = Integer.parseInt(request.getParameter("rewardId"));
        
        PreparedStatement psR = conn.prepareStatement("SELECT * FROM reward_types WHERE id = ?");
        psR.setInt(1, rewardId);
        ResultSet rsR = psR.executeQuery();

        if (rsR.next() && studentIds != null) {
            double amountPerStudent = rsR.getDouble("amount");
            String rewardName = rsR.getString("name");
            double totalRewardCost = (amountPerStudent > 0) ? (amountPerStudent * studentIds.length) : 0;

            // 1. Check Daily Velocity Limit
            if (amountPerStudent > 0) {
                double dailyLimit = 0, tempExtension = 0, spentToday = 0;
                
                PreparedStatement psL = conn.prepareStatement("SELECT daily_limit, temp_extension FROM teacher_allowance WHERE teacher_id = ?");
                psL.setInt(1, teacher.getId());
                ResultSet rsL = psL.executeQuery();
                if (rsL.next()) {
                    dailyLimit = rsL.getDouble("daily_limit");
                    tempExtension = rsL.getDouble("temp_extension");
                }

                PreparedStatement psS = conn.prepareStatement("SELECT SUM(amount) FROM transactions WHERE sender_id = ? AND type = 'REWARD_AWARD' AND created_at >= CURRENT_DATE");
                psS.setInt(1, teacher.getId());
                ResultSet rsS = psS.executeQuery();
                if (rsS.next()) spentToday = rsS.getDouble(1);

                if (spentToday + totalRewardCost > (dailyLimit + tempExtension)) {
                    response.sendRedirect("teacherDashboard?tab=overview&error=limit_exceeded");
                    return;
                }
            }

            // 2. Process Transactions
            conn.setAutoCommit(false);
            try {
                for (String sId : studentIds) {
                    int studentId = Integer.parseInt(sId);
                    
                    PreparedStatement upW = conn.prepareStatement("UPDATE wallets SET balance = balance + ? WHERE student_id = ?");
                    upW.setDouble(1, amountPerStudent);
                    upW.setInt(2, studentId);
                    upW.executeUpdate();
                    
                    int finalSender = (amountPerStudent >= 0) ? teacher.getId() : studentId;
                    int finalReceiver = (amountPerStudent >= 0) ? studentId : teacher.getId();
                    String finalType = (amountPerStudent >= 0) ? "REWARD_AWARD" : "REWARD_DEDUCT";

                    PreparedStatement log = conn.prepareStatement(
                        "INSERT INTO transactions (sender_id, receiver_id, amount, type, description, school_id) VALUES (?, ?, ?, ?, ?, ?)"
                    );
                    log.setInt(1, finalSender);
                    log.setInt(2, finalReceiver);
                    log.setDouble(3, Math.abs(amountPerStudent));
                    log.setString(4, finalType);
                    log.setString(5, (amountPerStudent >= 0 ? "Award: " : "Deduct: ") + rewardName);
                    log.setInt(6, teacher.getSchoolId());
                    log.executeUpdate();
                }
                conn.commit();
                response.sendRedirect("teacherDashboard?tab=overview&success=1");
            } catch (Exception e) {
                conn.rollback();
                throw e;
            }
        }
    }

    private void handleLimitRequest(HttpServletRequest request, HttpServletResponse response, Connection conn, User teacher) throws Exception {
        double amount = Double.parseDouble(request.getParameter("amount"));
        String reason = request.getParameter("reason");

        String sql = "INSERT INTO limit_requests (teacher_id, school_id, requested_amount, reason) VALUES (?, ?, ?, ?)";
        try (PreparedStatement pst = conn.prepareStatement(sql)) {
            pst.setInt(1, teacher.getId());
            pst.setInt(2, teacher.getSchoolId());
            pst.setDouble(3, amount);
            pst.setString(4, reason);
            pst.executeUpdate();
        }
        response.sendRedirect("teacherDashboard?tab=overview&success=request_sent");
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
}