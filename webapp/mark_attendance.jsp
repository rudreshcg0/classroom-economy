<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<html>
<head>
    <title>Mark Attendance - VCES</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; padding: 40px; background: #f4f7f6; }
        .container { max-width: 900px; margin: auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
        .header { border-bottom: 2px solid #eee; margin-bottom: 20px; padding-bottom: 10px; display: flex; justify-content: space-between; align-items: center; }
        table { width: 100%; border-collapse: collapse; }
        th, td { text-align: left; padding: 12px; border-bottom: 1px solid #eee; }
        th { background: #3182ce; color: white; }
        
        /* Keyboard Navigation Styles */
        .attendance-row { transition: background-color 0.1s; border-left: 5px solid transparent; }
        .kb-active { background-color: #ebf8ff !important; border-left: 5px solid #3182ce !important; outline: none; }
        .row-present { background-color: #f0fff4 !important; }
        
        .btn-pay { background: #38a169; color: white; border: none; padding: 15px 30px; border-radius: 8px; cursor: pointer; width: 100%; font-size: 16px; font-weight: bold; margin-top: 20px; }
        .btn-pay:hover { background: #2f855a; }
        .hint-box { background: #edf2f7; padding: 10px; border-radius: 8px; font-size: 13px; margin-bottom: 15px; color: #4a5568; }
    </style>
</head>
<body>

<div class="container">
    <div class="header">
        <div>
            <a href="teacherDashboard" style="text-decoration: none; color: #3182ce; font-weight: bold;">⬅ Back to Dashboard</a>
            <% Map<String, Object> cd = (Map<String, Object>)request.getAttribute("classDetails"); %>
            <h1 style="margin: 10px 0;">Marking: <%= cd.get("name") %></h1>
        </div>
        <div style="text-align: right;">
            <p style="margin: 0; color: #2d3748;">Pay Rate: <strong>$<%= cd.get("pay") %></strong></p>
        </div>
    </div>

    <div class="hint-box">
        <strong>Keyboard Shortcuts:</strong> ⬆⬇ to Navigate | <strong>Space</strong> to toggle Present/Absent | <strong>Enter</strong> to Submit
    </div>

    <form id="attendanceForm" action="markAttendance" method="POST">
        <input type="hidden" name="classId" value="<%= cd.get("id") %>">
        <input type="hidden" name="schoolId" value="${sessionScope.user.schoolId}">

        <table>
            <thead>
                <tr>
                    <th style="width: 80px; text-align: center;">
                        <input type="checkbox" id="masterAttendance" onclick="toggleAllAttendance(this)" style="transform: scale(1.2);">
                        <label for="masterAttendance" style="font-size: 10px; display: block; cursor: pointer;">All Present</label>
                    </th>
                    <th>Roll No</th>
                    <th>Student Name</th>
                    <th>Wallet Balance</th>
                </tr>
            </thead>
            <tbody>
                <% 
                    List<User> students = (List<User>)request.getAttribute("students");
                    if(students != null && !students.isEmpty()) {
                        for(User s : students) { 
                %>
                <tr class="attendance-row">
                    <td style="text-align: center;">
                        <input type="checkbox" name="presentStudents" value="<%= s.getId() %>" class="attendance-check" style="transform: scale(1.4);">
                    </td>
                    <td><%= s.getRollNo() %></td>
                    <td><strong><%= s.getUsername() %></strong></td>
                    <td>$<%= s.getBalance() %></td>
                </tr>
                <% 
                        }
                    } else { 
                %>
                <tr><td colspan="4" style="text-align:center; padding: 40px;">No students linked to this class.</td></tr>
                <% } %>
            </tbody>
        </table>

        <% if(students != null && !students.isEmpty()) { %>
            <button type="submit" class="btn-pay">Submit Attendance & Process Payments</button>
        <% } %>
    </form>
</div>

<script>
// 1. SELECT ALL LOGIC
function toggleAllAttendance(master) {
    const checkboxes = document.querySelectorAll('.attendance-check');
    checkboxes.forEach(cb => {
        cb.checked = master.checked;
        const row = cb.closest('.attendance-row');
        if (cb.checked) row.classList.add('row-present');
        else row.classList.remove('row-present');
    });
}

// 2. KEYBOARD NAVIGATION LOGIC
document.addEventListener('keydown', function(e) {
    const rows = Array.from(document.querySelectorAll('.attendance-row'));
    let activeRow = document.querySelector('.kb-active');
    let index = rows.indexOf(activeRow);

    if (e.key === 'ArrowDown') {
        e.preventDefault();
        if (index < rows.length - 1) {
            if (activeRow) activeRow.classList.remove('kb-active');
            rows[index + 1].classList.add('kb-active');
            rows[index + 1].scrollIntoView({ block: 'center', behavior: 'smooth' });
        }
    } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        if (index > 0) {
            if (activeRow) activeRow.classList.remove('kb-active');
            rows[index - 1].classList.add('kb-active');
            rows[index - 1].scrollIntoView({ block: 'center', behavior: 'smooth' });
        }
    } else if (e.key === ' ') { // Spacebar to toggle
        e.preventDefault();
        if (activeRow) {
            const cb = activeRow.querySelector('.attendance-check');
            cb.checked = !cb.checked;
            if (cb.checked) activeRow.classList.add('row-present');
            else activeRow.classList.remove('row-present');
        }
    } else if (e.key === 'Enter') { // Enter to trigger submit
        if (confirm("Process payments for all selected students?")) {
            document.getElementById('attendanceForm').submit();
        }
    }
});

// Initialize highlight on the first row when page loads
window.onload = () => {
    const firstRow = document.querySelector('.attendance-row');
    if (firstRow) firstRow.classList.add('kb-active');
};

// Add click-to-focus for mouse users
document.querySelectorAll('.attendance-row').forEach(row => {
    row.addEventListener('click', function(e) {
        if (e.target.type !== 'checkbox') {
            document.querySelector('.kb-active')?.classList.remove('kb-active');
            this.classList.add('kb-active');
        }
    });
});
</script>

</body>
</html>