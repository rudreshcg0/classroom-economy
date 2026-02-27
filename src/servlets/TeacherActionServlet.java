package servlets;

import java.io.IOException;
import java.sql.*;
import java.util.Arrays;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/teacherAction")
public class TeacherActionServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User teacher = (User) session.getAttribute("user");
        String action = request.getParameter("action");

        // Updated redirect to .jsp
        if (teacher == null || !teacher.getRole().equalsIgnoreCase("teacher")) {
            response.sendRedirect("login.jsp"); 
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false); 

            // --- NEW: Student Creation Logic ---
            if ("addStudent".equals(action)) {
                String studentUser = request.getParameter("username");
                String studentPass = request.getParameter("password");
                String rollNo = request.getParameter("rollNo");

                // UPDATED SQL: Set must_change_password to TRUE for new students
                String sql = "INSERT INTO users (username, password, role, school_id, roll_no, must_change_password) VALUES (?, ?, 'student', ?, ?, TRUE)";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setString(1, studentUser);
                    pst.setString(2, studentPass);
                    pst.setInt(3, teacher.getSchoolId());
                    pst.setString(4, rollNo);
                    pst.executeUpdate();
                }
                conn.commit();
            }
            
            // --- Existing Marketplace Logic ---
            else if ("createItem".equals(action)) {
                String sql = "INSERT INTO marketplace_items (teacher_id, school_id, item_name, price, stock, item_description) VALUES (?, ?, ?, ?, ?, ?)";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setInt(1, teacher.getId());
                    pst.setInt(2, teacher.getSchoolId());
                    pst.setString(3, request.getParameter("itemName"));
                    pst.setDouble(4, Double.parseDouble(request.getParameter("price")));
                    pst.setInt(5, Integer.parseInt(request.getParameter("stock")));
                    pst.setString(6, request.getParameter("description"));
                    pst.executeUpdate();
                }
                conn.commit();
            } 
            else if ("bulkProcess".equals(action)) {
                String decision = request.getParameter("decision"); 
                String[] selectedIds = request.getParameterValues("selectedOrders");

                if (selectedIds != null && selectedIds.length > 0) {
                    for (String idStr : selectedIds) {
                        int orderId = Integer.parseInt(idStr);
                        
                        if ("REJECTED".equals(decision)) {
                            // 1. Fetch details for Refund & Restock
                            String sqlFind = "SELECT student_id, item_id, price, item_name FROM marketplace_orders WHERE order_id = ?";
                            try (PreparedStatement pstF = conn.prepareStatement(sqlFind)) {
                                pstF.setInt(1, orderId);
                                ResultSet rsF = pstF.executeQuery();
                                if (rsF.next()) {
                                    int studentId = rsF.getInt("student_id");
                                    int itemId = rsF.getInt("item_id");
                                    double price = rsF.getDouble("price");
                                    String item = rsF.getString("item_name");

                                    // 2. Refund Wallet
                                    String sqlRefund = "UPDATE wallets SET balance = balance + ? WHERE student_id = ?";
                                    try (PreparedStatement pstR = conn.prepareStatement(sqlRefund)) {
                                        pstR.setDouble(1, price);
                                        pstR.setInt(2, studentId);
                                        pstR.executeUpdate();
                                    }

                                    // 3. RESTOCK
                                    String sqlRestock = "UPDATE marketplace_items SET stock = stock + 1 WHERE item_id = ? AND stock <> -1";
                                    try (PreparedStatement pstRS = conn.prepareStatement(sqlRestock)) {
                                        pstRS.setInt(1, itemId);
                                        pstRS.executeUpdate();
                                    }

                                    // 4. Log Transaction
                                    String sqlLog = "INSERT INTO transactions (receiver_id, amount, type, description, school_id) VALUES (?, ?, 'REFUND', ?, ?)";
                                    try (PreparedStatement pstL = conn.prepareStatement(sqlLog)) {
                                        pstL.setInt(1, studentId);
                                        pstL.setDouble(2, price);
                                        pstL.setString(3, "Refund: " + item + " (Rejected)");
                                        pstL.setInt(4, teacher.getSchoolId());
                                        pstL.executeUpdate();
                                    }
                                }
                            }
                        }
                    }

                    // 5. Update Order Statuses
                    String finalStatus = "APPROVED".equals(decision) ? "COMPLETED" : "REJECTED";
                    String sqlUpdate = "UPDATE marketplace_orders SET status = ? WHERE order_id = ANY(?)";
                    try (PreparedStatement pstU = conn.prepareStatement(sqlUpdate)) {
                        pstU.setString(1, finalStatus);
                        Integer[] ids = Arrays.stream(selectedIds).map(Integer::valueOf).toArray(Integer[]::new);
                        Array idArr = conn.createArrayOf("INTEGER", ids);
                        pstU.setArray(2, idArr);
                        pstU.executeUpdate();
                    }
                    conn.commit(); 
                }
            }
            response.sendRedirect("teacherDashboard?success=1");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("teacherDashboard?error=1");
        }
    }
}