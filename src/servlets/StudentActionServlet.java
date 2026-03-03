package servlets;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/studentAction")
public class StudentActionServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User student = (session != null) ? (User) session.getAttribute("user") : null;
        String action = request.getParameter("action");

        // Basic Security: Ensure session exists
        if (student == null) { 
            response.sendRedirect("login.jsp"); 
            return; 
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false); // Transactions are critical for money safety

            if ("sendMoney".equals(action)) {
                String receiverUser = request.getParameter("receiverUsername");
                double amount = Double.parseDouble(request.getParameter("amount"));
                String note = request.getParameter("note");
                String reqIdParam = request.getParameter("requestId");

                // SECURITY: Prevent negative transfers (cheating)
                if (amount <= 0) {
                    response.sendRedirect("studentDashboard?error=invalid_amount");
                    return;
                }

                int receiverId = -1;
                String findUserSql = "SELECT user_id FROM users WHERE username = ? AND school_id = ?";
                try (PreparedStatement pstR = conn.prepareStatement(findUserSql)) {
                    pstR.setString(1, receiverUser);
                    pstR.setInt(2, student.getSchoolId());
                    ResultSet rsR = pstR.executeQuery();
                    if (rsR.next()) receiverId = rsR.getInt("user_id");
                }

                if (receiverId != -1 && receiverId != student.getId()) {
                    // Lock the sender's wallet to prevent "double spending"
                    String lockSql = "SELECT balance FROM wallets WHERE student_id = ? FOR UPDATE";
                    try (PreparedStatement pstB = conn.prepareStatement(lockSql)) {
                        pstB.setInt(1, student.getId());
                        ResultSet rsB = pstB.executeQuery();
                        
                        if (rsB.next() && rsB.getDouble("balance") >= amount) {
                            // SECURITY: Use PreparedStatements for all updates (No string concatenation)
                            String deductSql = "UPDATE wallets SET balance = balance - ? WHERE student_id = ?";
                            try (PreparedStatement pstD = conn.prepareStatement(deductSql)) {
                                pstD.setDouble(1, amount);
                                pstD.setInt(2, student.getId());
                                pstD.executeUpdate();
                            }

                            String addSql = "UPDATE wallets SET balance = balance + ? WHERE student_id = ?";
                            try (PreparedStatement pstA = conn.prepareStatement(addSql)) {
                                pstA.setDouble(1, amount);
                                pstA.setInt(2, receiverId);
                                pstA.executeUpdate();
                            }

                            // Log the transaction
                            String logSql = "INSERT INTO transactions (sender_id, receiver_id, amount, type, description, school_id) VALUES (?, ?, ?, 'TRANSFER', ?, ?)";
                            try (PreparedStatement log = conn.prepareStatement(logSql)) {
                                log.setInt(1, student.getId());
                                log.setInt(2, receiverId);
                                log.setDouble(3, amount);
                                log.setString(4, (note == null || note.trim().isEmpty()) ? "Peer Transfer" : note);
                                log.setInt(5, student.getSchoolId());
                                log.executeUpdate();
                            }

                            // Update payment request status if applicable
                            if (reqIdParam != null && !reqIdParam.isEmpty()) {
                                String updateReq = "UPDATE payment_requests SET status = 'APPROVED' WHERE request_id = ? AND receiver_id = ?";
                                try (PreparedStatement pstReq = conn.prepareStatement(updateReq)) {
                                    pstReq.setInt(1, Integer.parseInt(reqIdParam));
                                    pstReq.setInt(2, student.getId());
                                    pstReq.executeUpdate();
                                }
                            }
                            
                            conn.commit();
                            response.sendRedirect("studentDashboard?success=1");
                            return;
                        } else {
                            response.sendRedirect("studentDashboard?error=balance");
                            return;
                        }
                    }
                }
            }
            else if ("buyItem".equals(action)) {
                int itemId = Integer.parseInt(request.getParameter("itemId"));

                // SECURITY: Fetch the price from the DATABASE, not the request parameter
                // This prevents students from changing the price in the browser.
                double actualPrice = 0;
                String itemName = "";
                String itemSql = "SELECT item_name, price, stock FROM marketplace_items WHERE item_id = ? AND school_id = ?";
                try (PreparedStatement pstI = conn.prepareStatement(itemSql)) {
                    pstI.setInt(1, itemId);
                    pstI.setInt(2, student.getSchoolId());
                    ResultSet rsI = pstI.executeQuery();
                    if (rsI.next()) {
                        actualPrice = rsI.getDouble("price");
                        itemName = rsI.getString("item_name");
                        int stock = rsI.getInt("stock");
                        if (stock == 0) { 
                            response.sendRedirect("studentDashboard?error=out_of_stock");
                            return; 
                        }
                    } else {
                        response.sendRedirect("studentDashboard?error=item_not_found");
                        return;
                    }
                }

                // Verify balance and process purchase
                try (PreparedStatement pstB = conn.prepareStatement("SELECT balance FROM wallets WHERE student_id = ? FOR UPDATE")) {
                    pstB.setInt(1, student.getId());
                    ResultSet rsB = pstB.executeQuery();
                    if (rsB.next() && rsB.getDouble("balance") >= actualPrice) {
                        
                        // Deduct money
                        try (PreparedStatement pstD = conn.prepareStatement("UPDATE wallets SET balance = balance - ? WHERE student_id = ?")) {
                            pstD.setDouble(1, actualPrice);
                            pstD.setInt(2, student.getId());
                            pstD.executeUpdate();
                        }

                        // Reduce stock (if not unlimited)
                        try (PreparedStatement pstS = conn.prepareStatement("UPDATE marketplace_items SET stock = stock - 1 WHERE item_id = ? AND stock > 0")) {
                            pstS.setInt(1, itemId);
                            pstS.executeUpdate();
                        }

                        // Record order
                        String orderSql = "INSERT INTO marketplace_orders (student_id, item_id, item_name, price, status) VALUES (?, ?, ?, ?, 'PENDING_TEACHER')";
                        try (PreparedStatement order = conn.prepareStatement(orderSql)) {
                            order.setInt(1, student.getId());
                            order.setInt(2, itemId);
                            order.setString(3, itemName);
                            order.setDouble(4, actualPrice);
                            order.executeUpdate();
                        }
                        
                        conn.commit();
                        response.sendRedirect("studentDashboard?success=1");
                        return;
                    } else {
                        response.sendRedirect("studentDashboard?error=balance");
                        return;
                    }
                }
            }
            // Add requestMoney logic similarly using PreparedStatements...
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("studentDashboard?error=db");
        }
    }
}