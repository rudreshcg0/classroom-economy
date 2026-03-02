<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<% 
    String selectedClass = (String)request.getAttribute("selectedClassId"); 
%>

<div style="margin-bottom: 2rem;">
    <h1 style="color: #1a202c; font-size: 1.875rem; font-weight: 700; margin-bottom: 0.5rem;">
        Financial Audit Ledger
    </h1>
    <p style="color: #64748b; font-size: 1rem;">Track and audit the flow of classroom currency.</p>
</div>

<div class="card" style="border-top: 4px solid #3182ce; padding: 1.5rem;">
    <h3 style="margin-top:0; color:#2d3748; font-size: 1.1rem; margin-bottom: 1rem; display: flex; align-items: center; gap: 8px;">
        <span style="font-size: 1.2rem;">🔍</span> Select a Class
    </h3>
    <form action="adminDashboard" method="GET" style="display:flex; gap:12px; align-items:center;">
        <input type="hidden" name="view" value="ledger">
        <select name="classId" onchange="this.form.submit()" 
                style="flex:1; padding:12px; border-radius:10px; border:1px solid #cbd5e0; font-size: 1rem; background-color: #f8fafc; cursor: pointer; transition: border-color 0.2s;">
            <option value="">-- Choose a class to start auditing --</option>
            <% List<Map<String, Object>> cl = (List<Map<String, Object>>)request.getAttribute("classList");
               if(cl != null) for(Map<String, Object> c : cl) { %>
                <option value="<%= c.get("id") %>" <%= (c.get("id").toString().equals(selectedClass)) ? "selected" : "" %>><%= c.get("name") %></option>
            <% } %>
        </select>
    </form>
</div>

<% if(selectedClass != null) { %>
    <div class="grid" style="display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; margin-top: 2rem; align-items: start;">
        
        <div style="display: flex; flex-direction: column; gap: 1.5rem;">
            <div class="card" style="padding: 1.25rem;">
                <div class="section-header" style="background:none; border:none; padding:0; margin-bottom: 1rem;">
                    <span style="color: #4a5568; font-weight: 700; display: flex; align-items: center; gap: 8px;">
                        👤 Staff Directory
                    </span>
                    <input type="text" class="search-mini" onkeyup="filterTable(this, 'staffLedgerList')" 
                           placeholder="Search staff..." style="width: 140px; padding: 6px 10px; border-radius: 6px; border: 1px solid #e2e8f0;">
                </div>
                <table id="staffLedgerList" style="width: 100%; border-collapse: separate; border-spacing: 0 8px;">
                    <% List<User> ct = (List<User>)request.getAttribute("classTeachers");
                       if(ct != null && !ct.isEmpty()) { for(User t : ct) { %>
                        <tr class="ledger-row" style="background: #f8fafc; transition: all 0.2s;">
                            <td style="padding: 12px; border-radius: 8px 0 0 8px;"><strong><%= t.getUsername() %></strong></td>
                            <td align="right" style="padding: 12px; border-radius: 0 8px 8px 0;">
                                <a href="adminDashboard?view=ledger&classId=<%= selectedClass %>&viewUserId=<%= t.getId() %>" 
                                   style="color: #3182ce; text-decoration: none; font-weight: 600; font-size: 0.9rem;">Audit Ledger &rarr;</a>
                            </td>
                        </tr>
                    <% } } else { %>
                        <tr><td colspan="2" style="color:#94a3b8; font-style: italic; text-align: center; padding: 1rem;">No staff found.</td></tr>
                    <% } %>
                </table>
            </div>

            <div class="card" style="padding: 1.25rem;">
                <div class="section-header" style="background:none; border:none; padding:0; margin-bottom: 1rem;">
                    <span style="color: #4a5568; font-weight: 700; display: flex; align-items: center; gap: 8px;">
                        🎓 Student Roster
                    </span>
                    <input type="text" class="search-mini" onkeyup="filterTable(this, 'studentLedgerList')" 
                           placeholder="Search students..." style="width: 140px; padding: 6px 10px; border-radius: 6px; border: 1px solid #e2e8f0;">
                </div>
                <table id="studentLedgerList" style="width: 100%; border-collapse: separate; border-spacing: 0 8px;">
                    <% List<User> cs = (List<User>)request.getAttribute("classStudents");
                       if(cs != null && !cs.isEmpty()) { for(User s : cs) { %>
                        <tr class="ledger-row" style="background: #f8fafc; transition: all 0.2s;">
                            <td style="padding: 12px; border-radius: 8px 0 0 8px;"><%= s.getUsername() %></td>
                            <td align="right" style="padding: 12px; border-radius: 0 8px 8px 0;">
                                <a href="adminDashboard?view=ledger&classId=<%= selectedClass %>&viewUserId=<%= s.getId() %>" 
                                   style="color: #3182ce; text-decoration: none; font-weight: 600; font-size: 0.9rem;">View Log &rarr;</a>
                            </td>
                        </tr>
                    <% } } else { %>
                        <tr><td colspan="2" style="color:#94a3b8; font-style: italic; text-align: center; padding: 1rem;">No students found.</td></tr>
                    <% } %>
                </table>
            </div>
        </div>

        <div class="card" style="min-height: 400px; padding: 1.5rem; position: sticky; top: 20px;">
            <% if(request.getAttribute("history") != null) { %>
                <div style="margin-bottom: 1.5rem; border-bottom: 1px solid #e2e8f0; padding-bottom: 1rem;">
                    <h3 style="margin:0; color: #1a202c; font-size: 1.25rem;">
                        Transaction History
                    </h3>
                    <p style="color: #3182ce; font-weight: 600; margin-top: 4px;">
                        <%= request.getAttribute("targetName") %>
                    </p>
                </div>
                <table style="width: 100%; border-collapse: collapse;">
                    <thead>
                        <tr style="text-align: left; color: #64748b; font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.025em;">
                            <th style="padding: 12px 8px; border-bottom: 2px solid #edf2f7;">Date</th>
                            <th style="padding: 12px 8px; border-bottom: 2px solid #edf2f7;">Amount</th>
                            <th style="padding: 12px 8px; border-bottom: 2px solid #edf2f7;">Type</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% List<Map<String, Object>> history = (List<Map<String, Object>>)request.getAttribute("history");
                       for(Map<String, Object> h : history) { 
                           String type = h.get("type").toString();
                           String amountColor = type.toLowerCase().contains("salary") ? "#059669" : "#2d3748";
                    %>
                        <tr>
                            <td style="padding: 14px 8px; border-bottom: 1px solid #edf2f7; font-size: 0.9rem; color: #64748b;">
                                <%= h.get("date") %>
                            </td>
                            <td style="padding: 14px 8px; font-weight: 700; color: <%= amountColor %>;">
                                <%= h.get("amount").toString().startsWith("-") ? "" : "+" %>$<%= h.get("amount") %>
                            </td>
                            <td style="padding: 14px 8px; border-bottom: 1px solid #edf2f7;">
                                <span style="background: #f1f5f9; padding: 4px 8px; border-radius: 6px; font-size: 0.75rem; font-weight: 600; color: #475569; text-transform: uppercase;">
                                    <%= type %>
                                </span>
                            </td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
            <% } else { %>
                <div style="text-align: center; margin-top: 5rem;">
                    <div style="font-size: 3rem; margin-bottom: 1rem;">📄</div>
                    <h3 style="color:#2d3748; margin-bottom: 0.5rem;">Ready to Audit</h3>
                    <p style="color:#64748b; max-width: 250px; margin: 0 auto;">Select a user from the left directory to inspect their full transaction history.</p>
                </div>
            <% } %>
        </div>
    </div>
<% } %>

<style>
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