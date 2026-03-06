package servlets;

import java.io.IOException;
import java.sql.*;
import java.util.Arrays;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/teacherAction")
public class TeacherActionServlet extends HttpServlet {
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User teacher = (User) session.getAttribute("user");
        String action = request.getParameter("action");

        if (teacher == null || !teacher.getRole().equalsIgnoreCase("teacher")) {
            response.sendRedirect("login.jsp"); 
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            if ("viewTeacherMarketplaceItems".equals(action)) {
                System.out.println("DEBUG: viewTeacherMarketplaceItems called for teacher: " + teacher.getId());
                // Fetch all marketplace items created by the logged-in teacher
                String sql = "SELECT item_id, item_name, item_description, price, stock FROM marketplace_items WHERE teacher_id = ? AND school_id = ?";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setInt(1, teacher.getId());
                    pst.setInt(2, teacher.getSchoolId());
                    ResultSet rs = pst.executeQuery();
                    
                    StringBuilder json = new StringBuilder();
                    json.append("{\"status\":\"success\",\"items\":[");
                    boolean first = true;
                    int count = 0;
                    while (rs.next()) {
                        count++;
                        if (!first) json.append(",");
                        json.append("{");
                        json.append("\"item_id\":").append(rs.getInt("item_id")).append(",");
                        json.append("\"item_name\":\"").append(escapeJson(rs.getString("item_name"))).append("\",");
                        json.append("\"item_description\":\"").append(escapeJson(rs.getString("item_description"))).append("\",");
                        json.append("\"price\":").append(rs.getDouble("price")).append(",");
                        json.append("\"stock\":").append(rs.getInt("stock"));
                        json.append("}");
                        first = false;
                    }
                    json.append("]}");
                    System.out.println("DEBUG: Found " + count + " items for teacher " + teacher.getId());
                    
                    response.setContentType("application/json");
                    response.getWriter().write(json.toString());
                }
            }
            else if ("getTeacherBlocks".equals(action)) {
                // Fetch reward blocks for the teacher
                String sql = "SELECT id, name, amount FROM reward_types WHERE teacher_id = ? OR teacher_id IS NULL ORDER BY name ASC";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setInt(1, teacher.getId());
                    ResultSet rs = pst.executeQuery();
                    
                    StringBuilder json = new StringBuilder();
                    json.append("{\"status\":\"success\",\"blocks\":[");
                    boolean first = true;
                    while (rs.next()) {
                        if (!first) json.append(",");
                        json.append("{");
                        json.append("\"id\":").append(rs.getInt("id")).append(",");
                        json.append("\"name\":\"").append(escapeJson(rs.getString("name"))).append("\",");
                        json.append("\"amount\":").append(rs.getDouble("amount"));
                        json.append("}");
                        first = false;
                    }
                    json.append("]}");
                    
                    response.setContentType("application/json");
                    response.getWriter().write(json.toString());
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.setContentType("application/json");
            response.getWriter().write("{\"status\":\"error\",\"message\":\"Database error\"}");
        }
    }
    
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
                String email = request.getParameter("email"); // Added email parameter

                // UPDATED SQL: Added email column and one extra '?'
                String sql = "INSERT INTO users (username, password, role, school_id, roll_no, email, must_change_password) VALUES (?, ?, 'student', ?, ?, ?, TRUE)";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setString(1, studentUser);
                    pst.setString(2, studentPass);
                    pst.setInt(3, teacher.getSchoolId());
                    pst.setString(4, rollNo);
                    pst.setString(5, email); // Set the email value
                    pst.executeUpdate();
                }
                conn.commit();
            }
            
            // --- Existing Marketplace Logic ---
            else if ("createItem".equals(action)) {
                // NEW: Capture the checkbox value (Defaults to true if not checked)
                boolean requiresApproval = request.getParameter("requiresApproval") != null;

                // UPDATED SQL: Added requires_approval column
                String sql = "INSERT INTO marketplace_items (teacher_id, school_id, item_name, price, stock, item_description, requires_approval) VALUES (?, ?, ?, ?, ?, ?, ?)";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setInt(1, teacher.getId());
                    pst.setInt(2, teacher.getSchoolId());
                    pst.setString(3, request.getParameter("itemName"));
                    pst.setDouble(4, Double.parseDouble(request.getParameter("price")));
                    pst.setInt(5, Integer.parseInt(request.getParameter("stock")));
                    pst.setString(6, request.getParameter("description"));
                    pst.setBoolean(7, requiresApproval); // Set the new boolean value
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
            
            // --- Reward Block Management ---
            else if ("addRewardType".equals(action)) {
                String name = request.getParameter("name");
                double amount = Double.parseDouble(request.getParameter("amount"));
                String icon = request.getParameter("icon");
                
                String sql = "INSERT INTO reward_types (teacher_id, name, amount, icon) VALUES (?, ?, ?, ?)";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setInt(1, teacher.getId());
                    pst.setString(2, name);
                    pst.setDouble(3, amount);
                    pst.setString(4, icon);
                    pst.executeUpdate();
                    conn.commit();
                    response.setContentType("application/json");
                    response.getWriter().write("{\"status\":\"success\"}");
                }
            }
            else if ("deleteRewardType".equals(action)) {
                int id = Integer.parseInt(request.getParameter("rewardId"));
                
                String sql = "DELETE FROM reward_types WHERE id = ? AND teacher_id = ?";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setInt(1, id);
                    pst.setInt(2, teacher.getId());
                    pst.executeUpdate();
                    conn.commit();
                    response.setContentType("application/json");
                    response.getWriter().write("{\"status\":\"success\"}");
                }
            }
            
            // --- New: Delete Marketplace Item ---
            else if ("deleteMarketplaceItem".equals(action)) {
                int itemId = Integer.parseInt(request.getParameter("item_id"));
                
                // First, check if the item belongs to the teacher
                String checkSql = "SELECT teacher_id FROM marketplace_items WHERE item_id = ?";
                try (PreparedStatement checkPst = conn.prepareStatement(checkSql)) {
                    checkPst.setInt(1, itemId);
                    ResultSet rs = checkPst.executeQuery();
                    if (rs.next()) {
                        int ownerId = rs.getInt("teacher_id");
                        if (ownerId != teacher.getId()) {
                            response.setContentType("application/json");
                            response.getWriter().write("{\"status\":\"error\",\"message\":\"You can only delete your own items\"}");
                            return;
                        }
                    } else {
                        response.setContentType("application/json");
                        response.getWriter().write("{\"status\":\"error\",\"message\":\"Item not found\"}");
                        return;
                    }
                }
                
                // Delete the item
                String deleteSql = "DELETE FROM marketplace_items WHERE item_id = ? AND teacher_id = ?";
                try (PreparedStatement deletePst = conn.prepareStatement(deleteSql)) {
                    deletePst.setInt(1, itemId);
                    deletePst.setInt(2, teacher.getId());
                    int rowsAffected = deletePst.executeUpdate();
                    if (rowsAffected > 0) {
                        conn.commit();
                        response.setContentType("application/json");
                        response.getWriter().write("{\"status\":\"success\"}");
                    } else {
                        response.setContentType("application/json");
                        response.getWriter().write("{\"status\":\"error\",\"message\":\"Item not found or you do not have permission to delete it.\"}");
                    }
                }
            }
            
            response.sendRedirect("teacherDashboard?success=1");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("teacherDashboard?error=1");
        }
    }
    
    private String escapeJson(String str) {
        if (str == null) return "";
        return str.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }
}