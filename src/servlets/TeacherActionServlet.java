package servlets;

import java.io.IOException;
import java.sql.*;
import java.util.Arrays;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;
import org.mindrot.jbcrypt.BCrypt;

@WebServlet("/teacherAction")
public class TeacherActionServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User teacher = (session != null) ? (User) session.getAttribute("user") : null;
        String action = request.getParameter("action");

        // --- SECURITY: Strict Role & Session Validation ---
        if (teacher == null || !"teacher".equalsIgnoreCase(teacher.getRole())) {
            response.sendRedirect("login.jsp?error=unauthorized");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false); 

            // --- ACTION: Student Creation ---
            if ("addStudent".equals(action)) {
                String studentUser = request.getParameter("username");
                String studentPass = request.getParameter("password");
                String rollNo = request.getParameter("rollNo");
                String email = request.getParameter("email");

                // SECURITY: Hash password before saving
                String hashedPass = BCrypt.hashpw(studentPass, BCrypt.gensalt(12));

                String sql = "INSERT INTO users (username, password, role, school_id, roll_no, email, must_change_password) VALUES (?, ?, 'student', ?, ?, ?, TRUE)";
                try (PreparedStatement pst = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                    pst.setString(1, studentUser);
                    pst.setString(2, hashedPass);
                    pst.setInt(3, teacher.getSchoolId()); // Forced isolation
                    pst.setString(4, rollNo);
                    pst.setString(5, email);
                    pst.executeUpdate();
                    
                    // Also initialize a wallet for the new student
                    ResultSet rs = pst.getGeneratedKeys();
                    if (rs.next()) {
                        int newStudentId = rs.getInt(1);
                        try (PreparedStatement pstW = conn.prepareStatement("INSERT INTO wallets (student_id, school_id, balance) VALUES (?, ?, 0.00)")) {
                            pstW.setInt(1, newStudentId);
                            pstW.setInt(2, teacher.getSchoolId());
                            pstW.executeUpdate();
                        }
                    }
                }
                conn.commit();
            }
            
            // --- ACTION: Create Marketplace Item ---
            else if ("createItem".equals(action)) {
                String sql = "INSERT INTO marketplace_items (teacher_id, school_id, item_name, price, stock, item_description) VALUES (?, ?, ?, ?, ?, ?)";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setInt(1, teacher.getId());
                    pst.setInt(2, teacher.getSchoolId()); // Forced isolation
                    pst.setString(3, request.getParameter("itemName"));
                    pst.setDouble(4, Double.parseDouble(request.getParameter("price")));
                    pst.setInt(5, Integer.parseInt(request.getParameter("stock")));
                    pst.setString(6, request.getParameter("description"));
                    pst.executeUpdate();
                }
                conn.commit();
            } 

            // --- ACTION: Bulk Process Orders ---
            else if ("bulkProcess".equals(action)) {
                String decision = request.getParameter("decision"); 
                String[] selectedIds = request.getParameterValues("selectedOrders");

                if (selectedIds != null && selectedIds.length > 0) {
                    for (String idStr : selectedIds) {
                        int orderId = Integer.parseInt(idStr);
                        
                        if ("REJECTED".equals(decision)) {
                            // SECURITY: Verify order belongs to this teacher AND school
                            String sqlFind = "SELECT o.student_id, o.item_id, o.price, o.item_name FROM marketplace_orders o " +
                                             "JOIN marketplace_items i ON o.item_id = i.item_id " +
                                             "WHERE o.order_id = ? AND i.teacher_id = ? AND i.school_id = ?";
                            
                            try (PreparedStatement pstF = conn.prepareStatement(sqlFind)) {
                                pstF.setInt(1, orderId);
                                pstF.setInt(2, teacher.getId());
                                pstF.setInt(3, teacher.getSchoolId());
                                ResultSet rsF = pstF.executeQuery();
                                
                                if (rsF.next()) {
                                    int studentId = rsF.getInt("student_id");
                                    int itemId = rsF.getInt("item_id");
                                    double price = rsF.getDouble("price");
                                    String item = rsF.getString("item_name");

                                    // Refund Wallet using PreparedStatements
                                    try (PreparedStatement pstR = conn.prepareStatement("UPDATE wallets SET balance = balance + ? WHERE student_id = ?")) {
                                        pstR.setDouble(1, price);
                                        pstR.setInt(2, studentId);
                                        pstR.executeUpdate();
                                    }

                                    // Restock item
                                    try (PreparedStatement pstRS = conn.prepareStatement("UPDATE marketplace_items SET stock = stock + 1 WHERE item_id = ? AND stock <> -1")) {
                                        pstRS.setInt(1, itemId);
                                        pstRS.executeUpdate();
                                    }

                                    // Log Transaction
                                    try (PreparedStatement pstL = conn.prepareStatement("INSERT INTO transactions (receiver_id, amount, type, description, school_id) VALUES (?, ?, 'REFUND', ?, ?)")) {
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

                    // Update Order Statuses securely
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
            response.sendRedirect("teacherDashboard?error=system");
        }
    }
}