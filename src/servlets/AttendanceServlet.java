package servlets;

import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/markAttendance")
public class AttendanceServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // 1. Retrieve form data
        String[] studentIds = request.getParameterValues("presentStudents");
        String classIdStr = request.getParameter("classId");
        String schoolIdStr = request.getParameter("schoolId");

        if (classIdStr == null || studentIds == null) {
            response.sendRedirect("teacherDashboard?error=no_selection");
            return;
        }

        int classId = Integer.parseInt(classIdStr);
        int schoolId = Integer.parseInt(schoolIdStr);

        try (Connection conn = DBConnection.getConnection()) {
            // Start Transaction
            conn.setAutoCommit(false);

            // Prepared Statements for high performance and security
            String updateWallet = "UPDATE wallets SET balance = balance + (SELECT pay_per_session FROM classes WHERE class_id = ?) WHERE student_id = ?";
            String markAttend = "INSERT INTO attendance (student_id, class_id, is_present, processed_payment) VALUES (?, ?, TRUE, TRUE)";
            String logTrans = "INSERT INTO transactions (receiver_id, amount, type, description, school_id) " +
                              "VALUES (?, (SELECT pay_per_session FROM classes WHERE class_id = ?), 'ATTENDANCE_PAY', 'Daily Attendance Pay', ?)";

            try (PreparedStatement pstWallet = conn.prepareStatement(updateWallet);
                 PreparedStatement pstAttend = conn.prepareStatement(markAttend);
                 PreparedStatement pstLog = conn.prepareStatement(logTrans)) {

                for (String sId : studentIds) {
                    int studentId = Integer.parseInt(sId);

                    // A. Update Wallet (Minting Money)
                    pstWallet.setInt(1, classId);
                    pstWallet.setInt(2, studentId);
                    pstWallet.executeUpdate();

                    // B. Mark Attendance
                    pstAttend.setInt(1, studentId);
                    pstAttend.setInt(2, classId);
                    pstAttend.executeUpdate();

                    // C. Log the Receipt
                    pstLog.setInt(1, studentId);
                    pstLog.setInt(2, classId);
                    pstLog.setInt(3, schoolId);
                    pstLog.executeUpdate();
                }

                conn.commit(); // Finalize all changes
                response.sendRedirect("teacherDashboard?success=1");

            } catch (SQLException e) {
                conn.rollback(); // If one fails, they all fail
                throw e;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            // Likely error: Unique constraint violation (Student already paid today)
            response.sendRedirect("teacherDashboard?error=already_paid");
        }
    }
}