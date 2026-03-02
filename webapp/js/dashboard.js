function toggleSidebar() {
    document.getElementById('sidebar').classList.toggle('active');
}

function openTab(evt, tabName) {
    document.querySelectorAll(".tab").forEach(t => t.style.display = "none");
    document.querySelectorAll(".nav-item").forEach(n => n.classList.remove("active"));
    document.getElementById(tabName).style.display = "block";
    evt.currentTarget.classList.add("active");
    if(window.innerWidth <= 992) {
        toggleSidebar();
    }
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
        if(!data) return;
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
    if (params.has('success') || params.has('profileUpdated')) {
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
    url.searchParams.delete('success'); 
    url.searchParams.delete('error'); 
    url.searchParams.delete('profileUpdated');
    window.history.pushState({}, '', url);
    location.reload();
}