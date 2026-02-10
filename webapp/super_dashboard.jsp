<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>Student Wallet</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; display: flex; background: #f8fafc; }
        .sidebar { width: 260px; background: #1e293b; color: white; height: 100vh; padding: 25px; position: fixed; }
        .sidebar h2 { color: #10b981; margin-bottom: 30px; }
        .nav-item { padding: 12px; cursor: pointer; border-radius: 8px; margin-bottom: 5px; color: #94a3b8; display: block; text-decoration: none; }
        .nav-item.active { background: #334155; color: white; }
        .main { margin-left: 285px; padding: 40px; width: calc(100% - 285px); }
        .balance-card { background: linear-gradient(135deg, #10b981, #059669); color: white; padding: 30px; border-radius: 16px; margin-bottom: 25px; }
        .card { background: white; padding: 25px; border-radius: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .tab { display: none; } .tab.active { display: block; }
        .btn { padding: 10px; border: none; border-radius: 8px; color: white; cursor: pointer; font-weight: bold; width: 100%; transition: 0.3s; }
        input { width: 100%; padding: 12px; border: 1px solid #e2e8f0; border-radius: 8px; margin-bottom: 10px; box-sizing: border-box; }
        .badge-pending { background: #fffbeb; color: #92400e; padding: 15px; border-radius: 12px; border: 1px solid #fcd34d; margin-bottom: 10px; }
        .text-green { color: #10b981 !important; }
        .text-red { color: #ef4444 !important; }
        .store-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 20px; }
        table { width: 100%; border-collapse: collapse; }
        td { padding: 12px; border-bottom: 1px solid #f1f5f9; }
    </style>
</head>
<body>

<div class="sidebar">
    <h2>VCES Pay</h2>
    <div class="nav-item active" onclick="openTab(event, 'home')">🏠 Dashboard</div>
    <div class="nav-item" onclick="openTab(event, 'pay')">💸 Pay & Request</div>
    <div class="nav-item" onclick="openTab(event, 'shop')">🛒 Marketplace</div>
    <a href="login.html" class="nav-item" style="color: #f87171; margin-top: 30px;">Logout</a>
</div>

<div class="main">
    <div id="home" class="tab active">
        <div class="balance-card">
            <small>WALLET BALANCE</small>
            <h1 style="margin: 5px 0; font-size: 42px;">$${balance != null ? balance : '0.00'}</h1>
            <p style="margin: 0; opacity: 0.8;">Roll No: ${rollNo}</p>
        </div>

        <div class="card">
            <h3>🔔 Pending Payment Requests</h3>
            <% List<Map<String, Object>> pr = (List<Map<String, Object>>)request.getAttribute("pendingRequests");
               if(pr != null && !pr.isEmpty()) { for(Map<String, Object> r : pr) { %>
                <div class="badge-pending" style="display:flex; justify-content:space-between; align-items:center;">
                    <div><strong><%= r.get("from") %></strong>: $<%= r.get("amt") %><br><small>"<%= r.get("note") %>"</small></div>
                    <form action="studentAction" method="POST">
                        <input type="hidden" name="action" value="sendMoney">
                        <input type="hidden" name="requestId" value="<%= r.get("id") %>">
                        <input type="hidden" name="receiverUsername" value="<%= r.get("from") %>">
                        <input type="hidden" name="amount" value="<%= r.get("amt") %>">
                        <button type="submit" class="btn" style="background:#059669; width:auto; padding: 8px 15px;">Pay Now</button>
                    </form>
                </div>
            <% } } else { %> <p style="color: #94a3b8;">No new requests.</p> <% } %>
        </div>

        <div class="card">
            <h3>Recent History</h3>
            <table>
                <% List<Map<String, Object>> hist = (List<Map<String, Object>>)request.getAttribute("history");
                   if(hist != null) for(Map<String, Object> h : hist) { 
                       boolean isCredit = (boolean)h.get("isCredit"); %>
                    <tr>
                        <td><%= h.get("desc") %></td>
                        <td align="right" class="<%= isCredit ? "text-green" : "text-red" %>" style="font-weight:bold;">
                            <%= isCredit ? "+" : "-" %>$<%= h.get("amount") %>
                        </td>
                    </tr>
                <% } %>
            </table>
        </div>
    </div>

    <div id="pay" class="tab">
        <div class="card">
            <h3>Send Money Instantly</h3>
            <form action="studentAction" method="POST">
                <input type="hidden" name="action" value="sendMoney">
                <input type="text" name="receiverUsername" placeholder="Enter Friend's Username" required>
                <input type="number" name="amount" placeholder="Amount ($)" step="0.01" required>
                <button type="submit" class="btn" style="background:#3b82f6;">Send Money</button>
            </form>
        </div>
        <div class="card">
            <h3>Request Money</h3>
            <form action="studentAction" method="POST">
                <input type="hidden" name="action" value="requestMoney">
                <input type="text" name="payerUsername" placeholder="Friend's Username" required>
                <input type="number" name="amount" placeholder="Amount ($)" step="0.01" required>
                <button type="submit" class="btn" style="background:#8b5cf6;">Send Request</button>
            </form>
        </div>
    </div>

    <div id="shop" class="tab">
        <div class="card">
            <h2>🎓 College Marketplace</h2>
            <p style="color: #718096; margin-bottom: 25px;">Live updates every 5 seconds.</p>
            <div class="store-grid">
                <% List<Map<String, Object>> shopItems = (List<Map<String, Object>>)request.getAttribute("availableItems");
                   if(shopItems != null) { for(Map<String, Object> item : shopItems) { 
                   int stock = (int)item.get("stock"); %>
                    <div style="border: 1px solid #e2e8f0; padding: 20px; border-radius: 12px; background: #fff; display: flex; flex-direction: column; justify-content: space-between;">
                        <div>
                            <h4 style="margin:0;"><%= item.get("name") %></h4>
                            <p style="color:#64748b; font-size:13px; margin: 10px 0;"><%= item.get("desc") %></p>
                        </div>
                        <div style="margin-top:15px;">
                            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                                <span style="font-weight:bold; color:#10b981; font-size:20px;">$<%= item.get("price") %></span>
                                <span id="stock-count-<%= item.get("id") %>" style="font-size:12px; font-weight:bold; color:#94a3b8;">
                                    <%= stock == -1 ? "♾️ Unlimited" : stock + " Left" %>
                                </span>
                            </div>
                            <form action="studentAction" method="POST">
                                <input type="hidden" name="action" value="buyItem">
                                <input type="hidden" name="itemId" value="<%= item.get("id") %>">
                                <input type="hidden" name="itemPrice" value="<%= item.get("price") %>">
                                <input type="hidden" name="itemName" value="<%= item.get("name") %>">
                                <button type="submit" id="buy-btn-<%= item.get("id") %>" class="btn" style="background:#f59e0b;" <%= stock == 0 ? "disabled" : "" %>>
                                    <%= stock == 0 ? "Sold Out" : "Purchase" %>
                                </button>
                            </form>
                        </div>
                    </div>
                <% } } %>
            </div>
        </div>
    </div>
</div>

<script>
    // Tab Switching Logic
    function openTab(evt, tabName) {
        var i, tab, nav;
        tab = document.getElementsByClassName("tab");
        for (i = 0; i < tab.length; i++) tab[i].style.display = "none";
        nav = document.getElementsByClassName("nav-item");
        for (i = 0; i < nav.length; i++) nav[i].className = nav[i].className.replace(" active", "");
        document.getElementById(tabName).style.display = "block";
        evt.currentTarget.className += " active";
    }

    // Live Stock Counter AJAX Logic
    function updateStock() {
        fetch('getMarketStock')
            .then(response => response.text())
            .then(data => {
                const items = data.split(',');
                items.forEach(item => {
                    if (!item) return;
                    const [id, stock] = item.split(':');
                    const stockEl = document.getElementById('stock-count-' + id);
                    const btnEl = document.getElementById('buy-btn-' + id);

                    if (stockEl && btnEl) {
                        const stockNum = parseInt(stock);
                        stockEl.innerText = (stockNum === -1) ? "♾️ Unlimited" : stockNum + " Left";
                        
                        if (stockNum === 0) {
                            btnEl.disabled = true;
                            btnEl.innerText = "Sold Out";
                            btnEl.style.background = "#cbd5e0";
                        } else {
                            btnEl.disabled = false;
                            btnEl.innerText = "Purchase";
                            btnEl.style.background = "#f59e0b";
                        }
                    }
                });
            });
    }

    // Ping server every 5 seconds
    setInterval(updateStock, 5000);
</script>
</body>
</html>