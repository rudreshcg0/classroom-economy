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

        double currentAllowance = 0.0;
        List<Map<String, Object>> classesList = new ArrayList<>();
        List<MarketplaceItem> myItems = new ArrayList<>();
        List<Map<String, Object>> pendingOrders = new ArrayList<>();

        try (Connection conn = DBConnection.getConnection()) {
            
            // 1. Get Teacher's current budget balance
            String sqlAllowance = "SELECT current_balance FROM teacher_allowance WHERE teacher_id = ?";
            try (PreparedStatement pst1 = conn.prepareStatement(sqlAllowance)) {
                pst1.setInt(1, teacher.getId());
                ResultSet rs1 = pst1.executeQuery();
                if (rs1.next()) {
                    currentAllowance = rs1.getDouble("current_balance");
                }
            }

            // 2. Get Classes assigned to this teacher
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

            // 3. Fetch Marketplace Items created by this teacher
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

            // 4. Fetch Pending Orders for Bulk Approval
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

            // Set all data for JSP
            request.setAttribute("allowance", currentAllowance);
            request.setAttribute("classes", classesList);
            request.setAttribute("myItems", myItems);
            request.setAttribute("marketplaceOrders", pendingOrders);
            
            request.getRequestDispatcher("teacher_dashboard.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            response.getWriter().println("Teacher Dashboard Data Error: " + e.getMessage());
        }
    }
}