package servlets;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/studentDashboard")
public class StudentDashboardServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User student = (User) session.getAttribute("user");
        if (student == null) { response.sendRedirect("login.html"); return; }

        try (Connection conn = DBConnection.getConnection()) {
            // 1. Fetch Balance & Roll No
            String sqlB = "SELECT w.balance, u.roll_no FROM wallets w JOIN users u ON w.student_id = u.user_id WHERE u.user_id = ?";
            try (PreparedStatement pstB = conn.prepareStatement(sqlB)) {
                pstB.setInt(1, student.getId());
                ResultSet rsB = pstB.executeQuery();
                if(rsB.next()) {
                    request.setAttribute("balance", rsB.getDouble("balance"));
                    request.setAttribute("rollNo", rsB.getString("roll_no"));
                }
            }

            // 2. Fetch Transaction History
            List<Map<String, Object>> history = new ArrayList<>();
            String sqlH = "SELECT * FROM transactions WHERE sender_id = ? OR receiver_id = ? ORDER BY created_at DESC LIMIT 20";
            try (PreparedStatement pstH = conn.prepareStatement(sqlH)) {
                pstH.setInt(1, student.getId()); pstH.setInt(2, student.getId());
                ResultSet rsH = pstH.executeQuery();
                while(rsH.next()){
                    Map<String, Object> m = new HashMap<>();
                    m.put("amount", rsH.getDouble("amount"));
                    m.put("desc", rsH.getString("description"));
                    m.put("date", rsH.getTimestamp("created_at").toString());
                    m.put("isCredit", rsH.getInt("receiver_id") == student.getId());
                    history.add(m);
                }
            }
            request.setAttribute("history", history);

            // 3. Fetch Pending Requests (UPI style)
            List<Map<String, Object>> reqs = new ArrayList<>();
            String sqlQ = "SELECT r.request_id, r.amount, r.note, u.username FROM payment_requests r " +
                          "JOIN users u ON r.sender_id = u.user_id " +
                          "WHERE r.receiver_id = ? AND r.status = 'PENDING'";
            try (PreparedStatement pstQ = conn.prepareStatement(sqlQ)) {
                pstQ.setInt(1, student.getId());
                ResultSet rsQ = pstQ.executeQuery();
                while(rsQ.next()){
                    Map<String, Object> r = new HashMap<>();
                    r.put("id", rsQ.getInt("request_id"));
                    r.put("from", rsQ.getString("username"));
                    r.put("amt", rsQ.getDouble("amount"));
                    r.put("note", rsQ.getString("note"));
                    reqs.add(r);
                }
            }
            request.setAttribute("pendingRequests", reqs);

            // 4. Fetch Dynamic Marketplace Items
            List<Map<String, Object>> shopItems = new ArrayList<>();
            String sqlShop = "SELECT * FROM marketplace_items WHERE school_id = ? AND (stock > 0 OR stock = -1) ORDER BY created_at DESC";
            try (PreparedStatement pstS = conn.prepareStatement(sqlShop)) {
                pstS.setInt(1, student.getSchoolId());
                ResultSet rsS = pstS.executeQuery();
                while(rsS.next()) {
                    Map<String, Object> item = new HashMap<>();
                    item.put("id", rsS.getInt("item_id"));
                    item.put("name", rsS.getString("item_name"));
                    item.put("price", rsS.getDouble("price"));
                    item.put("stock", rsS.getInt("stock"));
                    item.put("desc", rsS.getString("item_description"));
                    shopItems.add(item);
                }
            }
            request.setAttribute("availableItems", shopItems);

            request.getRequestDispatcher("student_dashboard.jsp").forward(request, response);
        } catch (Exception e) { 
            e.printStackTrace(); 
            response.getWriter().println("Dashboard Error: " + e.getMessage()); 
        }
    }
}