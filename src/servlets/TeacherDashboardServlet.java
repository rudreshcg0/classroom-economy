package servlets;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;
import models.MarketplaceItem;

@WebServlet("/teacherDashboard")
public class TeacherDashboardServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User teacher = (User) session.getAttribute("user");

        if (teacher == null || !teacher.getRole().equalsIgnoreCase("teacher")) {
            response.sendRedirect("login.html");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            // 1. Get Teacher's Reward Budget Balance
            double currentAllowance = 0.0;
            String sqlAllowance = "SELECT current_balance FROM teacher_allowance WHERE teacher_id = ?";
            try (PreparedStatement pst1 = conn.prepareStatement(sqlAllowance)) {
                pst1.setInt(1, teacher.getId());
                ResultSet rs1 = pst1.executeQuery();
                if (rs1.next()) currentAllowance = rs1.getDouble("current_balance");
            }

            // 2. Get Classes Assigned to this Teacher (for Attendance tab)
            List<Map<String, Object>> classesList = new ArrayList<>();
            String sqlClasses = "SELECT class_id, class_name, pay_per_session FROM classes WHERE teacher_id = ?";
            try (PreparedStatement pstClasses = conn.prepareStatement(sqlClasses)) {
                pstClasses.setInt(1, teacher.getId());
                ResultSet rsClasses = pstClasses.executeQuery();
                while (rsClasses.next()) {
                    Map<String, Object> classMap = new HashMap<>();
                    classMap.put("id", rsClasses.getInt("class_id"));
                    classMap.put("name", rsClasses.getString("class_name"));
                    classMap.put("pay", rsClasses.getDouble("pay_per_session"));
                    classesList.add(classMap);
                }
            }

            // 3. Fetch Teacher's Own Marketplace Inventory
            List<MarketplaceItem> myItems = new ArrayList<>();
            String sqlI = "SELECT * FROM marketplace_items WHERE teacher_id = ?";
            try (PreparedStatement pstI = conn.prepareStatement(sqlI)) {
                pstI.setInt(1, teacher.getId());
                ResultSet rsI = pstI.executeQuery();
                while(rsI.next()) {
                    myItems.add(new MarketplaceItem(
                        rsI.getInt("item_id"), 
                        rsI.getString("item_name"), 
                        rsI.getString("item_description"), 
                        rsI.getDouble("price"), 
                        rsI.getInt("stock")
                    ));
                }
            }

            // 4. Fetch Pending Fulfillment Orders (Marketplace Management Tab)
            List<Map<String, Object>> pendingOrders = new ArrayList<>();
            String sqlO = "SELECT o.order_id, o.item_name, o.purchased_at, u.username FROM marketplace_orders o " +
                          "JOIN users u ON o.student_id = u.user_id " +
                          "WHERE o.status = 'PENDING_TEACHER' AND u.school_id = ?";
            try (PreparedStatement pstO = conn.prepareStatement(sqlO)) {
                pstO.setInt(1, teacher.getSchoolId());
                ResultSet rsO = pstO.executeQuery();
                while(rsO.next()) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("id", rsO.getInt("order_id"));
                    map.put("student", rsO.getString("username"));
                    map.put("item", rsO.getString("item_name"));
                    map.put("date", rsO.getTimestamp("purchased_at"));
                    pendingOrders.add(map);
                }
            }

            // 5. Fetch Full School Audit History (COMPLETED or REJECTED statuses)
            List<Map<String, Object>> fullAudit = new ArrayList<>();
            String sqlAudit = "SELECT o.*, u.username FROM marketplace_orders o " +
                              "JOIN users u ON o.student_id = u.user_id " +
                              "WHERE u.school_id = ? AND o.status IN ('COMPLETED', 'REJECTED') " +
                              "ORDER BY purchased_at DESC";
            try (PreparedStatement pstA = conn.prepareStatement(sqlAudit)) {
                pstA.setInt(1, teacher.getSchoolId());
                ResultSet rsA = pstA.executeQuery();
                while(rsA.next()){
                    Map<String, Object> a = new HashMap<>();
                    a.put("student", rsA.getString("username"));
                    a.put("item", rsA.getString("item_name"));
                    a.put("price", rsA.getDouble("price"));
                    a.put("status", rsA.getString("status"));
                    a.put("date", rsA.getTimestamp("purchased_at"));
                    fullAudit.add(a);
                }
            }

            // 6. Fetch Teacher-specific Reward Blocks for the management modal
            List<Map<String, Object>> teacherRewards = new ArrayList<>();
            String sqlRewards = "SELECT * FROM reward_types WHERE teacher_id = ? OR teacher_id IS NULL ORDER BY name ASC";
            try (PreparedStatement pstRewards = conn.prepareStatement(sqlRewards)) {
                pstRewards.setInt(1, teacher.getId());
                ResultSet rsRewards = pstRewards.executeQuery();
                while (rsRewards.next()) {
                    Map<String, Object> r = new HashMap<>();
                    r.put("id", rsRewards.getInt("id"));
                    r.put("name", rsRewards.getString("name"));
                    r.put("amount", rsRewards.getDouble("amount"));
                    r.put("icon", rsRewards.getString("icon"));
                    teacherRewards.add(r);
                }
            }

            // Set all data for JSP handling
            request.setAttribute("allowance", currentAllowance);
            request.setAttribute("classes", classesList);
            request.setAttribute("myItems", myItems);
            request.setAttribute("marketplaceOrders", pendingOrders);
            request.setAttribute("fullAudit", fullAudit);
            request.setAttribute("teacherRewardTypes", teacherRewards);
            
            request.getRequestDispatcher("teacher_dashboard.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            response.sendError(500, "Internal Server Error during Teacher Dashboard data retrieval.");
        }
    }
}