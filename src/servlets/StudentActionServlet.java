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
        HttpSession session = request.getSession();
        User student = (User) session.getAttribute("user");
        String action = request.getParameter("action");

        if (student == null) { response.sendRedirect("login.jsp"); return; }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false); 

            if ("sendMoney".equals(action)) {
                String receiverUser = request.getParameter("receiverUsername");
                double amount = Double.parseDouble(request.getParameter("amount"));
                String note = request.getParameter("note");
                String reqId = request.getParameter("requestId");

                int receiverId = -1;
                try (PreparedStatement pstR = conn.prepareStatement("SELECT user_id FROM users WHERE username = ? AND school_id = ?")) {
                    pstR.setString(1, receiverUser);
                    pstR.setInt(2, student.getSchoolId());
                    ResultSet rsR = pstR.executeQuery();
                    if (rsR.next()) receiverId = rsR.getInt("user_id");
                }

                if (receiverId != -1 && receiverId != student.getId()) {
                    try (PreparedStatement pstB = conn.prepareStatement("SELECT balance FROM wallets WHERE student_id = ? FOR UPDATE")) {
                        pstB.setInt(1, student.getId());
                        ResultSet rsB = pstB.executeQuery();
                        if (rsB.next() && rsB.getDouble("balance") >= amount) {
                            try (PreparedStatement pstSub = conn.prepareStatement("UPDATE wallets SET balance = balance - ? WHERE student_id = ?")) {
                                pstSub.setDouble(1, amount); pstSub.setInt(2, student.getId()); pstSub.executeUpdate();
                            }
                            try (PreparedStatement pstAdd = conn.prepareStatement("UPDATE wallets SET balance = balance + ? WHERE student_id = ?")) {
                                pstAdd.setDouble(1, amount); pstAdd.setInt(2, receiverId); pstAdd.executeUpdate();
                            }

                            try (PreparedStatement log = conn.prepareStatement("INSERT INTO transactions (sender_id, receiver_id, amount, type, description, school_id) VALUES (?, ?, ?, 'TRANSFER', ?, ?)")) {
                                log.setInt(1, student.getId()); log.setInt(2, receiverId); log.setDouble(3, amount);
                                log.setString(4, (note == null || note.isEmpty()) ? "Peer Transfer" : note);
                                log.setInt(5, student.getSchoolId()); log.executeUpdate();
                            }

                            if (reqId != null) {
                                try (PreparedStatement pstReq = conn.prepareStatement("UPDATE payment_requests SET status = 'APPROVED' WHERE request_id = ?")) {
                                    pstReq.setInt(1, Integer.parseInt(reqId)); pstReq.executeUpdate();
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
            else if ("requestMoney".equals(action)) {
                String payerUser = request.getParameter("payerUsername");
                double amount = Double.parseDouble(request.getParameter("amount"));
                String note = request.getParameter("note");

                String sql = "INSERT INTO payment_requests (sender_id, receiver_id, amount, note) " +
                             "SELECT ?, user_id, ?, ? FROM users WHERE username = ? AND school_id = ?";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setInt(1, student.getId()); pst.setDouble(2, amount); pst.setString(3, note);
                    pst.setString(4, payerUser); pst.setInt(5, student.getSchoolId());
                    pst.executeUpdate();
                    conn.commit();
                    response.sendRedirect("studentDashboard?success=1");
                    return;
                }
            }
            else if ("buyItem".equals(action)) {
                int itemId = Integer.parseInt(request.getParameter("itemId"));
                double price = Double.parseDouble(request.getParameter("itemPrice"));
                String itemName = request.getParameter("itemName");

                // UPDATED: Check if item requires approval
                boolean needsApproval = true;
                try (PreparedStatement pstItem = conn.prepareStatement("SELECT requires_approval FROM marketplace_items WHERE item_id = ?")) {
                    pstItem.setInt(1, itemId);
                    ResultSet rsItem = pstItem.executeQuery();
                    if (rsItem.next()) needsApproval = rsItem.getBoolean("requires_approval");
                }

                try (PreparedStatement pstB = conn.prepareStatement("SELECT balance FROM wallets WHERE student_id = ? FOR UPDATE")) {
                    pstB.setInt(1, student.getId());
                    ResultSet rsB = pstB.executeQuery();
                    if (rsB.next() && rsB.getDouble("balance") >= price) {
                        try (PreparedStatement pstSub = conn.prepareStatement("UPDATE wallets SET balance = balance - ? WHERE student_id = ?")) {
                            pstSub.setDouble(1, price); pstSub.setInt(2, student.getId()); pstSub.executeUpdate();
                        }
                        try (PreparedStatement pstStock = conn.prepareStatement("UPDATE marketplace_items SET stock = stock - 1 WHERE item_id = ? AND stock > 0")) {
                            pstStock.setInt(1, itemId); pstStock.executeUpdate();
                        }

                        try (PreparedStatement log = conn.prepareStatement("INSERT INTO transactions (sender_id, amount, type, description, school_id) VALUES (?, ?, 'MARKETPLACE', ?, ?)")) {
                            log.setInt(1, student.getId()); log.setDouble(2, price); log.setString(3, "Bought: " + itemName);
                            log.setInt(4, student.getSchoolId()); log.executeUpdate();
                        }

                        // UPDATED: Use COMPLETED if no approval is required
                        String initialStatus = needsApproval ? "PENDING_TEACHER" : "COMPLETED";
                        try (PreparedStatement order = conn.prepareStatement("INSERT INTO marketplace_orders (student_id, item_id, item_name, price, status) VALUES (?, ?, ?, ?, ?)")) {
                            order.setInt(1, student.getId()); order.setInt(2, itemId);
                            order.setString(3, itemName); order.setDouble(4, price);
                            order.setString(5, initialStatus);
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
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("studentDashboard?error=db");
        }
    }
}