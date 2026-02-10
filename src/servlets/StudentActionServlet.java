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

        if (student == null) { response.sendRedirect("login.html"); return; }

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
                            conn.prepareStatement("UPDATE wallets SET balance = balance - " + amount + " WHERE student_id = " + student.getId()).executeUpdate();
                            conn.prepareStatement("UPDATE wallets SET balance = balance + " + amount + " WHERE student_id = " + receiverId).executeUpdate();

                            try (PreparedStatement log = conn.prepareStatement("INSERT INTO transactions (sender_id, receiver_id, amount, type, description, school_id) VALUES (?, ?, ?, 'TRANSFER', ?, ?)")) {
                                log.setInt(1, student.getId()); log.setInt(2, receiverId); log.setDouble(3, amount);
                                log.setString(4, (note == null || note.isEmpty()) ? "Peer Transfer" : note);
                                log.setInt(5, student.getSchoolId()); log.executeUpdate();
                            }

                            if (reqId != null) {
                                conn.prepareStatement("UPDATE payment_requests SET status = 'APPROVED' WHERE request_id = " + reqId).executeUpdate();
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

                try (PreparedStatement pstB = conn.prepareStatement("SELECT balance FROM wallets WHERE student_id = ? FOR UPDATE")) {
                    pstB.setInt(1, student.getId());
                    ResultSet rsB = pstB.executeQuery();
                    if (rsB.next() && rsB.getDouble("balance") >= price) {
                        conn.prepareStatement("UPDATE wallets SET balance = balance - " + price + " WHERE student_id = " + student.getId()).executeUpdate();
                        conn.prepareStatement("UPDATE marketplace_items SET stock = stock - 1 WHERE item_id = " + itemId + " AND stock > 0").executeUpdate();

                        try (PreparedStatement log = conn.prepareStatement("INSERT INTO transactions (sender_id, amount, type, description, school_id) VALUES (?, ?, 'MARKETPLACE', ?, ?)")) {
                            log.setInt(1, student.getId()); log.setDouble(2, price); log.setString(3, "Bought: " + itemName);
                            log.setInt(4, student.getSchoolId()); log.executeUpdate();
                        }

                        try (PreparedStatement order = conn.prepareStatement("INSERT INTO marketplace_orders (student_id, item_id, item_name, price, status) VALUES (?, ?, ?, ?, 'PENDING_TEACHER')")) {
                            order.setInt(1, student.getId()); order.setInt(2, itemId);
                            order.setString(3, itemName); order.setDouble(4, price);
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