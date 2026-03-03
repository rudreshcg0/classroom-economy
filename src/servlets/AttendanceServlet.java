package servlets;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/markAttendance")
public class AttendanceServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User teacher = (session != null) ? (User) session.getAttribute("user") : null;
        String classIdStr = request.getParameter("classId");

        // SECURITY: Strict Session & Role Validation
        if (teacher == null || !"teacher".equalsIgnoreCase(teacher.getRole()) || classIdStr == null) {
            response.sendRedirect("teacherDashboard?error=unauthorized");
            return;
        }

        List<User> linkedStudents = new ArrayList<>();
        Map<String, Object> classDetails = new HashMap<>();

        try (Connection conn = DBConnection.getConnection()) {
            // SECURITY: Verify the teacher actually owns this class to prevent ID-guessing attacks
            String sqlClass = "SELECT class_id, class_name, pay_per_session FROM classes WHERE class_id = ? AND teacher_id = ? AND school_id = ?";
            try (PreparedStatement pst1 = conn.prepareStatement(sqlClass)) {
                pst1.setInt(1, Integer.parseInt(classIdStr));
                pst1.setInt(2, teacher.getId());
                pst1.setInt(3, teacher.getSchoolId());
                ResultSet rs1 = pst1.executeQuery();
                if (rs1.next()) {
                    classDetails.put("id", rs1.getInt("class_id"));
                    classDetails.put("name", rs1.getString("class_name"));
                    classDetails.put("pay", rs1.getDouble("pay_per_session"));
                } else {
                    response.sendRedirect("teacherDashboard?error=class_not_found");
                    return;
                }
            }

            // SECURITY: Ensure students being fetched belong to the same school
            String sqlStudents = "SELECT u.user_id, u.username, u.roll_no, w.balance " +
                                 "FROM users u " +
                                 "JOIN student_classes sc ON u.user_id = sc.student_id " +
                                 "JOIN wallets w ON u.user_id = w.student_id " +
                                 "WHERE sc.class_id = ? AND u.school_id = ? ORDER BY u.roll_no ASC";
            try (PreparedStatement pst2 = conn.prepareStatement(sqlStudents)) {
                pst2.setInt(1, Integer.parseInt(classIdStr));
                pst2.setInt(2, teacher.getSchoolId());
                ResultSet rs2 = pst2.executeQuery();
                while (rs2.next()) {
                    linkedStudents.add(new User(
                        rs2.getInt("user_id"),
                        rs2.getString("username"),
                        "student",
                        teacher.getSchoolId(),
                        rs2.getDouble("balance"),
                        rs2.getString("roll_no")
                    ));
                }
            }

            request.setAttribute("classDetails", classDetails);
            request.setAttribute("students", linkedStudents);
            request.getRequestDispatcher("mark_attendance.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("teacherDashboard?error=system");
        }
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User teacher = (session != null) ? (User) session.getAttribute("user") : null;
        String[] studentIds = request.getParameterValues("presentStudents");
        String classIdStr = request.getParameter("classId");

        // SECURITY: Validate session and teacher role
        if (teacher == null || !"teacher".equalsIgnoreCase(teacher.getRole())) {
            response.sendRedirect("login.jsp?error=unauthorized");
            return;
        }

        if (classIdStr == null || studentIds == null) {
            response.sendRedirect("teacherDashboard?error=no_selection");
            return;
        }

        int classId = Integer.parseInt(classIdStr);
        int schoolId = teacher.getSchoolId(); // SECURITY: Trust the session, not the form parameter
        int processedCount = 0;

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            // SECURITY: Verify class ownership again during POST
            String verifyClass = "SELECT 1 FROM classes WHERE class_id = ? AND teacher_id = ? AND school_id = ?";
            try (PreparedStatement pstV = conn.prepareStatement(verifyClass)) {
                pstV.setInt(1, classId);
                pstV.setInt(2, teacher.getId());
                pstV.setInt(3, schoolId);
                if (!pstV.executeQuery().next()) {
                    response.sendRedirect("teacherDashboard?error=unauthorized_class");
                    return;
                }
            }

            String checkSql = "SELECT 1 FROM attendance WHERE student_id = ? AND class_id = ? AND attendance_date = CURRENT_DATE";
            String updateWallet = "UPDATE wallets SET balance = balance + (SELECT pay_per_session FROM classes WHERE class_id = ?) WHERE student_id = ? AND school_id = ?";
            String markAttend = "INSERT INTO attendance (student_id, class_id, is_present, processed_payment, attendance_date) VALUES (?, ?, TRUE, TRUE, CURRENT_DATE)";
            String logTrans = "INSERT INTO transactions (sender_id, receiver_id, amount, type, description, school_id) " +
                              "VALUES (NULL, ?, (SELECT pay_per_session FROM classes WHERE class_id = ?), 'ATTENDANCE_PAY', 'System Attendance Reward', ?)";

            try (PreparedStatement pstCheck = conn.prepareStatement(checkSql);
                 PreparedStatement pstWallet = conn.prepareStatement(updateWallet);
                 PreparedStatement pstAttend = conn.prepareStatement(markAttend);
                 PreparedStatement pstLog = conn.prepareStatement(logTrans)) {

                for (String sId : studentIds) {
                    int studentId = Integer.parseInt(sId);

                    pstCheck.setInt(1, studentId);
                    pstCheck.setInt(2, classId);
                    try (ResultSet rs = pstCheck.executeQuery()) {
                        if (rs.next()) continue; 
                    }

                    // Process Wallet update with school isolation
                    pstWallet.setInt(1, classId);
                    pstWallet.setInt(2, studentId);
                    pstWallet.setInt(3, schoolId);
                    pstWallet.executeUpdate();

                    pstAttend.setInt(1, studentId);
                    pstAttend.setInt(2, classId);
                    pstAttend.executeUpdate();

                    pstLog.setInt(1, studentId);
                    pstLog.setInt(2, classId);
                    pstLog.setInt(3, schoolId);
                    pstLog.executeUpdate();
                    
                    processedCount++;
                }

                conn.commit();
                response.sendRedirect("teacherDashboard?success=" + (processedCount > 0 ? "1" : "already_paid"));

            } catch (SQLException e) {
                conn.rollback();
                throw e;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("teacherDashboard?error=db_error");
        }
    }
}