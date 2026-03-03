<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<% 
    String selectedClass = (String)request.getAttribute("selectedClassId"); 
%>

<style>
    /* Professional Ledger Coloring - Forced Styles */
    .text-credit { 
        color: #10b981 !important; 
        font-weight: bold !important; 
    } 
    .text-debit { 
        color: #ef4444 !important; 
        font-weight: bold !important; 
    }
    
    /* Professional Badge System */
    .badge {
        padding: 4px 10px;
        border-radius: 12px;
        font-size: 11px;
        font-weight: 700;
        text-transform: uppercase;
        display: inline-block;
    }
    
    .bg-deduct { background-color: #fee2e2 !important; color: #991b1b !important; }
    .bg-salary { background-color: #dcfce7 !important; color: #166534 !important; }
    .bg-transfer { background-color: #e0f2fe !important; color: #075985 !important; }
    .bg-default { background-color: #f1f5f9; color: #475569; }

    /* Layout Hover Effects */
    .ledger-row:hover {
        background-color: #ebf8ff !important;
        transform: translateX(4px);
    }
    .search-mini:focus {
        outline: none;
        border-color: #3182ce !important;
        box-shadow: 0 0 0 3px rgba(66, 153, 225, 0.1);
    }
</style>

<div style="margin-bottom: 2rem;">
    <h1 style="color: #1a202c; font-size: 1.875rem; font-weight: 700; margin-bottom: 0.5rem;">
        Financial Audit Ledger
    </h1>
    <p style="color: #64748b; font-size: 1rem;">Track and audit the flow of classroom currency.</p>
</div>

<div class="card" style="border-top: 4px solid #3182ce; padding: 1.5rem; margin-bottom: 2rem;">
    <h3 style="margin-top:0; color:#2d3748; font-size: 1.1rem; margin-bottom: 1rem; display: flex; align-items: center; gap: 8px;">
        <span>🔍</span> Select a Class
    </h3>
    <form action="adminDashboard" method="GET" style="display:flex; gap:12px; align-items:center;">
        <input type="hidden" name="view" value="ledger">
        <select name="classId" onchange="this.form.submit()" 
                style="flex:1; padding:12px; border-radius:10px; border:1px solid #cbd5e0; font-size: 1rem; background-color: #f8fafc;">
            <option value="">-- Choose a class to start auditing --</option>
            <% List<Map<String, Object>> cl = (List<Map<String, Object>>)request.getAttribute("classList");
               if(cl != null) for(Map<String, Object> c : cl) { %>
                <option value="<%= c.get("id") %>" <%= (c.get("id").toString().equals(selectedClass)) ? "selected" : "" %>><%= c.get("name") %></option>
            <% } %>
        </select>
    </form>
</div>

<% if(selectedClass != null) { %>
    <div style="display: grid; grid-template-columns: 1fr 1.5fr; gap: 2rem; align-items: start;">
        
        <div style="display: flex; flex-direction: column; gap: 1.5rem;">
            <div class="card" style="padding: 1.25rem;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                    <span style="color: #4a5568; font-weight: 700;">👤 Staff</span>
                    <input type="text" class="search-mini" onkeyup="filterTable(this, 'staffLedgerList')" placeholder="Search..." style="width: 120px;">
                </div>
                <table id="staffLedgerList" style="width: 100%;">
                    <% List<User> ct = (List<User>)request.getAttribute("classTeachers");
                       if(ct != null) for(User t : ct) { %>
                        <tr class="ledger-row" style="background: #f8fafc;">
                            <td style="padding: 12px;"><%= t.getUsername() %></td>
                            <td align="right">
                                <a href="adminDashboard?view=ledger&classId=<%= selectedClass %>&viewUserId=<%= t.getId() %>" style="color: #3182ce; font-weight: 600; font-size: 0.85rem;">Audit &rarr;</a>
                            </td>
                        </tr>
                    <% } %>
                </table>
            </div>

            <div class="card" style="padding: 1.25rem;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                    <span style="color: #4a5568; font-weight: 700;">🎓 Students</span>
                    <input type="text" class="search-mini" onkeyup="filterTable(this, 'studentLedgerList')" placeholder="Search..." style="width: 120px;">
                </div>
                <table id="studentLedgerList" style="width: 100%;">
                    <% List<User> cs = (List<User>)request.getAttribute("classStudents");
                       if(cs != null) for(User s : cs) { %>
                        <tr class="ledger-row" style="background: #f8fafc;">
                            <td style="padding: 12px;"><%= s.getUsername() %></td>
                            <td align="right">
                                <a href="adminDashboard?view=ledger&classId=<%= selectedClass %>&viewUserId=<%= s.getId() %>" style="color: #3182ce; font-weight: 600; font-size: 0.85rem;">View Log &rarr;</a>
                            </td>
                        </tr>
                    <% } %>
                </table>
            </div>
        </div>

        <div class="card" style="padding: 1.5rem; position: sticky; top: 20px;">
            <% if(request.getAttribute("history") != null) { %>
                <div style="margin-bottom: 1.5rem; border-bottom: 1px solid #e2e8f0; padding-bottom: 10px;">
                    <h3 style="margin:0; color: #1a202c;">Transaction History</h3>
                    <p style="color: #3182ce; font-weight: 700; margin-top: 4px;">Auditing: <%= request.getAttribute("targetName") %></p>
                </div>
                <table style="width: 100%; border-collapse: collapse;">
                    <thead>
                        <tr style="text-align: left; color: #64748b; font-size: 0.75rem; text-transform: uppercase;">
                            <th style="padding: 10px 5px; border-bottom: 2px solid #edf2f7;">Date</th>
                            <th style="padding: 10px 5px; border-bottom: 2px solid #edf2f7;">Amount</th>
                            <th style="padding: 10px 5px; border-bottom: 2px solid #edf2f7;">Type</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% List<Map<String, Object>> history = (List<Map<String, Object>>)request.getAttribute("history");
                       for(Map<String, Object> h : history) { 
                           boolean isCredit = (boolean)h.get("isCredit");
                           String type = h.get("type").toString();
                    %>
                        <tr>
                            <td style="padding: 12px 5px; border-bottom: 1px solid #edf2f7; font-size: 0.85rem; color: #64748b;">
                                <%= h.get("date") %>
                            </td>
                            <td style="padding: 12px 5px; border-bottom: 1px solid #edf2f7;" class="<%= isCredit ? "text-credit" : "text-debit" %>">
                                <%= isCredit ? "+" : "-" %>₹<%= String.format("%.2f", h.get("amount")) %>
                            </td>
                            <td style="padding: 12px 5px; border-bottom: 1px solid #edf2f7;">
                                <span class="badge <%= (type.equals("REWARD_DEDUCT") || type.equals("DEBIT")) ? "bg-deduct" : 
                                               (type.contains("REWARD") || type.equalsIgnoreCase("Salary") ? "bg-salary" : "bg-transfer") %>">
                                    <%= type.replace("_", " ") %>
                                </span>
                            </td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
            <% } else { %>
                <div style="text-align: center; padding: 4rem 0;">
                    <h3 style="color:#cbd5e0;">Select a user to audit history</h3>
                </div>
            <% } %>
        </div>
    </div>
<% } %>