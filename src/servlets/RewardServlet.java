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

    // Helper to load standard dashboard data to prevent JSP errors on reload
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
            
            // Load Teacher's custom blocks for the Management Modal
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
            double amount = rsR.getDouble("amount");
            conn.setAutoCommit(false);
            for (String sId : studentIds) {
                PreparedStatement upW = conn.prepareStatement("UPDATE wallets SET balance = balance + ? WHERE student_id = ?");
                upW.setDouble(1, amount);
                upW.setInt(2, Integer.parseInt(sId));
                upW.executeUpdate();
                
                PreparedStatement log = conn.prepareStatement("INSERT INTO transactions (sender_id, receiver_id, amount, type, description, school_id) VALUES (?, ?, ?, 'REWARD', ?, ?)");
                log.setInt(1, teacher.getId());
                log.setInt(2, Integer.parseInt(sId));
                log.setDouble(3, Math.abs(amount));
                log.setString(4, (amount >= 0 ? "Award: " : "Deduct: ") + rsR.getString("name"));
                log.setInt(5, teacher.getSchoolId());
                log.executeUpdate();
            }
            conn.commit();
        }
        response.sendRedirect("teacherDashboard?tab=overview&success=1");
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