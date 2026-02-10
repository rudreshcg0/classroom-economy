package servlets;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/manageStudents")
public class ManageStudentsServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User teacher = (User) session.getAttribute("user");
        if (teacher == null) { response.sendRedirect("login.html"); return; }

        List<User> students = new ArrayList<>();
        List<Map<String, Object>> classes = new ArrayList<>();
        List<Map<String, Object>> enrollments = new ArrayList<>();

        try (Connection conn = DBConnection.getConnection()) {
            // 1. Fetch Classes
            String sqlC = "SELECT class_id, class_name FROM classes WHERE teacher_id = ?";
            try (PreparedStatement pst1 = conn.prepareStatement(sqlC)) {
                pst1.setInt(1, teacher.getId());
                ResultSet rs1 = pst1.executeQuery();
                while(rs1.next()){
                    Map<String, Object> map = new HashMap<>();
                    map.put("id", rs1.getInt("class_id"));
                    map.put("name", rs1.getString("class_name"));
                    classes.add(map);
                }
            }

            // 2. Fetch Registry
            String sqlS = "SELECT u.user_id, u.username, u.roll_no, w.balance FROM users u " +
                          "LEFT JOIN wallets w ON u.user_id = w.student_id " +
                          "WHERE u.school_id = ? AND u.role = 'student' ORDER BY u.roll_no ASC";
            try (PreparedStatement pst2 = conn.prepareStatement(sqlS)) {
                pst2.setInt(1, teacher.getSchoolId());
                ResultSet rs2 = pst2.executeQuery();
                while(rs2.next()){
                    students.add(new User(rs2.getInt("user_id"), rs2.getString("username"), "student", 
                                teacher.getSchoolId(), rs2.getDouble("balance"), rs2.getString("roll_no")));
                }
            }

            // 3. Fetch Enrollment Map
            String sqlE = "SELECT sc.student_id, sc.class_id, c.class_name FROM student_classes sc " +
                          "JOIN classes c ON sc.class_id = c.class_id WHERE c.teacher_id = ?";
            try (PreparedStatement pst3 = conn.prepareStatement(sqlE)) {
                pst3.setInt(1, teacher.getId());
                ResultSet rs3 = pst3.executeQuery();
                while(rs3.next()){
                    Map<String, Object> eMap = new HashMap<>();
                    eMap.put("sId", rs3.getInt("student_id"));
                    eMap.put("cId", rs3.getInt("class_id"));
                    eMap.put("cName", rs3.getString("class_name"));
                    enrollments.add(eMap);
                }
            }

            request.setAttribute("classes", classes);
            request.setAttribute("students", students);
            request.setAttribute("enrollments", enrollments);
            request.getRequestDispatcher("manage_students.jsp").forward(request, response);
        } catch (SQLException e) { e.printStackTrace(); }
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User teacher = (User) session.getAttribute("user");
        String action = request.getParameter("action");

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            if ("register".equals(action)) {
                String rawData = request.getParameter("studentData");
                String schoolPrefix = "school";
                try (PreparedStatement psS = conn.prepareStatement("SELECT school_name FROM schools WHERE school_id = ?")) {
                    psS.setInt(1, teacher.getSchoolId());
                    ResultSet rsS = psS.executeQuery();
                    if (rsS.next()) { schoolPrefix = rsS.getString("school_name").split("_")[0].toLowerCase(); }
                }

                String[] lines = rawData.split("\\r?\\n");
                try (PreparedStatement pst = conn.prepareStatement("INSERT INTO users (username, password, role, school_id, roll_no) VALUES (?, ?, 'student', ?, ?)")) {
                    for (String line : lines) {
                        String[] parts = line.split(",");
                        if (parts.length >= 2) {
                            String fName = parts[0].trim().split(" ")[0].toLowerCase();
                            String roll = parts[1].trim();
                            pst.setString(1, fName + "." + roll + "@" + schoolPrefix + ".vces");
                            pst.setString(2, fName + "@" + roll);
                            pst.setInt(3, teacher.getSchoolId());
                            pst.setString(4, roll);
                            pst.addBatch();
                        }
                    }
                    pst.executeBatch();
                }
                // Initialize Wallets at $0.00
                try (Statement stmt = conn.createStatement()) {
                    stmt.executeUpdate("INSERT INTO wallets (student_id, balance, school_id) SELECT user_id, 0.0, school_id FROM users WHERE role = 'student' AND user_id NOT IN (SELECT student_id FROM wallets)");
                }

            } else if ("enroll".equals(action) || "unenroll".equals(action)) {
                String[] ids = request.getParameterValues("studentIds");
                int cId = Integer.parseInt(request.getParameter("classId"));
                String sql = "enroll".equals(action) ? "INSERT INTO student_classes (student_id, class_id) VALUES (?, ?) ON CONFLICT DO NOTHING" : "DELETE FROM student_classes WHERE student_id = ? AND class_id = ?";
                try (PreparedStatement pst = conn.prepareStatement(sql)) {
                    if (ids != null) {
                        for (String sId : ids) {
                            try { pst.setInt(1, Integer.parseInt(sId)); pst.setInt(2, cId); pst.addBatch(); } catch (Exception e) { continue; }
                        }
                        pst.executeBatch();
                    }
                }
            } else if ("terminate".equals(action)) {
                String[] ids = request.getParameterValues("studentIds");
                if (ids != null) {
                    try (PreparedStatement pst = conn.prepareStatement("DELETE FROM users WHERE user_id = ? AND school_id = ?")) {
                        for (String sId : ids) {
                            try { 
                                pst.setInt(1, Integer.parseInt(sId)); 
                                pst.setInt(2, teacher.getSchoolId()); 
                                pst.addBatch(); 
                            } catch (Exception e) { continue; } // Skips "on" from Select All
                        }
                        pst.executeBatch();
                    }
                }
            }
            conn.commit();
            response.sendRedirect("manageStudents?success=1");
        } catch (SQLException e) { e.printStackTrace(); response.sendRedirect("manageStudents?error=1"); }
    }
}