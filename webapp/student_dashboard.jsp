<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>Student Wallet - VCES Pay</title>
    <script src="https://cdn.jsdelivr.net/npm/canvas-confetti@1.6.0/dist/confetti.browser.min.js"></script>
    <script src="https://unpkg.com/@lottiefiles/lottie-player@latest/dist/lottie-player.js"></script>
    
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; display: flex; background: #f8fafc; overflow-x: hidden; }
        .sidebar { width: 260px; background: #1e293b; color: white; height: 100vh; padding: 25px; position: fixed; z-index: 10; }
        .sidebar h2 { color: #10b981; margin-bottom: 30px; }
        .nav-item { padding: 12px; cursor: pointer; border-radius: 8px; margin-bottom: 5px; color: #94a3b8; display: block; text-decoration: none; transition: 0.3s; }
        .nav-item.active { background: #334155; color: white; }
        .main { margin-left: 285px; padding: 40px; width: calc(100% - 285px); }
        .balance-card { background: linear-gradient(135deg, #10b981, #059669); color: white; padding: 30px; border-radius: 16px; margin-bottom: 25px; box-shadow: 0 10px 15px -3px rgba(16, 185, 129, 0.2); }
        .card { background: white; padding: 25px; border-radius: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .tab { display: none; } .tab.active { display: block; }
        .btn { padding: 12px; border: none; border-radius: 8px; color: white; cursor: pointer; font-weight: bold; width: 100%; transition: 0.3s; }
        input { width: 100%; padding: 12px; border: 1px solid #e2e8f0; border-radius: 8px; margin-bottom: 10px; box-sizing: border-box; }
        .text-green { color: #10b981 !important; }
        .text-red { color: #ef4444 !important; }
        .item-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 20px; }
        .full-overlay { display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(255, 255, 255, 0.98); z-index: 9999; flex-direction: column; align-items: center; justify-content: center; backdrop-filter: blur(8px); }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 12px; border-bottom: 1px solid #f1f5f9; text-align: left; }
        .search-bar { margin-bottom: 15px; padding: 10px; border: 2px solid #e2e8f0; border-radius: 10px; font-size: 14px; width: 100%; box-sizing: border-box; }
        .toggle-btn { background: #64748b; margin-bottom: 20px; width: auto; padding: 8px 16px; font-size: 13px; }
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
                <div style="background:#fffbeb; padding:15px; border-radius:12px; border:1px solid #fcd34d; margin-bottom:10px; display:flex; justify-content:space-between; align-items:center;">
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
            <h3>Recent Wallet Activity</h3>
            <table>
                <% List<Map<String, Object>> hist = (List<Map<String, Object>>)request.getAttribute("history");
                   if(hist != null) { for(Map<String, Object> h : hist) { boolean isCredit = (boolean)h.get("isCredit"); %>
                    <tr>
                        <td><%= h.get("desc") %></td>
                        <td align="right" class="<%= isCredit ? "text-green" : "text-red" %>" style="font-weight:bold;"><%= isCredit ? "+" : "-" %>$<%= h.get("amount") %></td>
                    </tr>
                <% } } %>
            </table>
        </div>
    </div>

    <div id="pay" class="tab">
        <div class="card">
            <h3>💸 Send Money</h3>
            <form action="studentAction" method="POST">
                <input type="hidden" name="action" value="sendMoney">
                <input type="text" name="receiverUsername" placeholder="Recipient Username" required>
                <input type="number" name="amount" placeholder="Amount ($)" step="0.01" required>
                <input type="text" name="note" placeholder="Note (Optional)">
                <button type="submit" class="btn" style="background:#3b82f6;">Send Now</button>
            </form>
        </div>
        <div class="card" style="border-top: 4px solid #8b5cf6;">
            <h3>📥 Request Money</h3>
            <form action="studentAction" method="POST">
                <input type="hidden" name="action" value="requestMoney">
                <input type="text" name="payerUsername" placeholder="Friend's Username" required>
                <input type="number" name="amount" placeholder="Amount ($)" step="0.01" required>
                <input type="text" name="note" placeholder="Reason for request">
                <button type="submit" class="btn" style="background:#8b5cf6;">Send Request</button>
            </form>
        </div>
    </div>

    <div id="shop" class="tab">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
            <h2 style="margin: 0;">Marketplace</h2>
            <button class="btn toggle-btn" id="studentMarketBtn" onclick="toggleStudentMarket()">📜 View Order History</button>
        </div>

        <div id="marketStoreGrid">
            <div class="item-grid">
                <% List<Map<String, Object>> items = (List<Map<String, Object>>)request.getAttribute("availableItems");
                   if(items != null) { for(Map<String, Object> i : items) { int stock = (int)i.get("stock"); %>
                    <div class="card" style="border:1px solid #e2e8f0; display:flex; flex-direction:column; justify-content:space-between;">
                        <div>
                            <h4><%= i.get("name") %></h4>
                            <p style="font-size:12px; color:#64748b;"><%= i.get("desc") %></p>
                        </div>
                        <div style="margin-top:10px;">
                            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                                <span class="text-green" style="font-weight:bold; font-size:18px;">$<%= i.get("price") %></span>
                                <span id="stock-count-<%= i.get("id") %>" style="font-size:11px; color:#94a3b8;"><%= stock == -1 ? "♾️ Unlimited" : stock + " left" %></span>
                            </div>
                            <form action="studentAction" method="POST">
                                <input type="hidden" name="action" value="buyItem">
                                <input type="hidden" name="itemId" value="<%= i.get("id") %>">
                                <input type="hidden" name="itemPrice" value="<%= i.get("price") %>">
                                <input type="hidden" name="itemName" value="<%= i.get("name") %>">
                                <button type="submit" id="buy-btn-<%= i.get("id") %>" class="btn" style="background:#f59e0b;" <%= stock == 0 ? "disabled" : "" %>><%= stock == 0 ? "Sold Out" : "Buy Now" %></button>
                            </form>
                        </div>
                    </div>
                <% } } %>
            </div>
        </div>

        <div id="marketHistoryAudit" style="display: none;">
            <div class="card">
                <input type="text" id="auditSearch" onkeyup="filterStudentAudit()" placeholder="🔍 Search orders by item name or status..." class="search-bar">
                <table>
                    <thead>
                        <tr style="background: #f8fafc;">
                            <th>Item</th><th>Price</th><th>Date</th><th>Status</th>
                        </tr>
                    </thead>
                    <tbody id="auditTableBody">
                        <% List<Map<String, Object>> myOrders = (List<Map<String, Object>>)request.getAttribute("myOrders");
                           if(myOrders != null) { for(Map<String, Object> o : myOrders) { String status = (String)o.get("status"); %>
                            <tr class="audit-row">
                                <td class="order-item"><strong><%= o.get("item_name") %></strong></td>
                                <td>$<%= o.get("price") %></td>
                                <td><small><%= o.get("date") %></small></td>
                                <td class="order-status">
                                    <% if("PENDING_TEACHER".equals(status)) { %><span style="color: #f59e0b;">⏳ Pending</span>
                                    <% } else if("COMPLETED".equals(status)) { %><span class="text-green">✅ Approved</span>
                                    <% } else { %><span class="text-red">❌ Rejected</span><% } %>
                                </td>
                            </tr>
                        <% } } %>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<div id="successOverlay" class="full-overlay">
    <lottie-player src="https://assets10.lottiefiles.com/packages/lf20_afwjhpyv.json" background="transparent" speed="1" style="width: 300px; height: 300px;" autoplay></lottie-player>
    <h2 style="color:#10b981; font-size:28px; margin-top:-20px;">Payment Successful</h2>
    <button onclick="closePopups()" class="btn" style="background:#1e293b; width:180px; margin-top:30px;">Done</button>
</div>
<div id="errorOverlay" class="full-overlay">
    <lottie-player src="https://assets10.lottiefiles.com/packages/lf20_ghfp8v9f.json" background="transparent" speed="1" style="width: 300px; height: 300px;" autoplay></lottie-player>
    <h2 style="color:#ef4444; font-size:28px; margin-top:-20px;">Transaction Failed</h2>
    <p id="errorTxt" style="color:#64748b;">Insufficient balance or system error.</p>
    <button onclick="closePopups()" class="btn" style="background:#ef4444; width:180px; margin-top:30px;">Try Again</button>
</div>

<audio id="successSound" src="https://assets.mixkit.co/active_storage/sfx/2013/2013-preview.mp3"></audio>
<audio id="errorSound" src="https://assets.mixkit.co/active_storage/sfx/951/951-preview.mp3"></audio>

<script>
    function openTab(evt, tabName) {
        document.querySelectorAll(".tab").forEach(t => t.style.display = "none");
        document.querySelectorAll(".nav-item").forEach(n => n.classList.remove("active"));
        document.getElementById(tabName).style.display = "block";
        evt.currentTarget.classList.add("active");
    }

    function toggleStudentMarket() {
        const grid = document.getElementById('marketStoreGrid');
        const history = document.getElementById('marketHistoryAudit');
        const btn = document.getElementById('studentMarketBtn');
        if (grid.style.display === "none") {
            grid.style.display = "block"; history.style.display = "none";
            btn.innerText = "📜 View Order History";
        } else {
            grid.style.display = "none"; history.style.display = "block";
            btn.innerText = "🛒 Back to Store";
        }
    }

    function filterStudentAudit() {
        let filter = document.getElementById("auditSearch").value.toLowerCase();
        let rows = document.getElementsByClassName("audit-row");
        for (let row of rows) {
            let item = row.querySelector(".order-item").textContent.toLowerCase();
            let status = row.querySelector(".order-status").textContent.toLowerCase();
            row.style.display = (item.includes(filter) || status.includes(filter)) ? "" : "none";
        }
    }

    function updateBalance() {
        fetch('getBalance').then(res => res.text()).then(newBalance => {
            const display = document.querySelector('.balance-card h1');
            if (display && display.innerText !== "$" + newBalance) {
                display.innerText = "$" + newBalance;
                display.style.transform = "scale(1.1)";
                setTimeout(() => display.style.transform = "scale(1)", 300);
            }
        });
    }

    function updateStock() {
        fetch('getMarketStock').then(res => res.text()).then(data => {
            data.split(',').forEach(item => {
                if (!item) return;
                const [id, stock] = item.split(':');
                const stockEl = document.getElementById('stock-count-' + id);
                const btnEl = document.getElementById('buy-btn-' + id);
                if (stockEl && btnEl) {
                    const stockNum = parseInt(stock);
                    stockEl.innerText = (stockNum === -1) ? "♾️ Unlimited" : stockNum + " left";
                    btnEl.disabled = (stockNum === 0);
                    btnEl.innerText = (stockNum === 0) ? "Sold Out" : "Buy Now";
                    btnEl.style.background = (stockNum === 0) ? "#cbd5e0" : "#f59e0b";
                }
            });
        });
    }

    setInterval(() => { updateBalance(); updateStock(); }, 5000);

    window.onload = function() {
        const params = new URLSearchParams(window.location.search);
        if (params.has('success')) {
            document.getElementById('successOverlay').style.display = 'flex';
            document.getElementById('successSound').play();
            confetti({ particleCount: 150, spread: 70, origin: { y: 0.6 } });
        }
        if (params.has('error')) {
            if(params.get('error') === 'balance') document.getElementById('errorTxt').innerText = "Insufficient balance!";
            document.getElementById('errorOverlay').style.display = 'flex';
            document.getElementById('errorSound').play();
        }
    };

    function closePopups() {
        const url = new URL(window.location);
        url.searchParams.delete('success'); url.searchParams.delete('error');
        window.history.pushState({}, '', url);
        location.reload();
    }
</script>
</body>
</html>