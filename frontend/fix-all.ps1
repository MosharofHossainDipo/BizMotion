$utf8 = [System.Text.UTF8Encoding]::new($false)

# ── 1. list-customers HTML - use ngClass not ngIf on table ────
[System.IO.File]::WriteAllText("$PWD\src\app\customers\list\list-customers.component.html", @'
<div class="page-content">
  <div class="page-header">
    <div>
      <h1 class="page-title">Customers</h1>
      <p class="page-sub">Manage and monitor your customer database</p>
    </div>
    <div class="header-actions">
      <div class="search-wrap">
        <input type="text" class="search-input" [(ngModel)]="search" placeholder="Search customers..." />
      </div>
      <button class="primary-btn" *ngIf="canCreate" (click)="addNew()">+ Add Customer</button>
    </div>
  </div>

  <div class="error-banner" *ngIf="error">{{ error }}<button class="retry-btn" (click)="load()">Retry</button></div>

  <div class="table-card">
    <table class="tbl">
      <thead>
        <tr>
          <th>CUSTOMER</th><th>EMAIL</th><th>PHONE</th><th>GROUP</th><th>STATUS</th>
          <th class="tr" *ngIf="canEdit || canDelete">ACTIONS</th>
        </tr>
      </thead>
      <tbody>
        <tr *ngIf="loading">
          <td colspan="6" class="loading-row">
            <div class="loading-inner"><div class="spinner"></div><span>Loading customers...</span></div>
          </td>
        </tr>
        <ng-container *ngIf="!loading">
          <tr *ngFor="let c of filtered">
            <td>
              <div class="customer-cell">
                <div class="av" [ngClass]="avatarClass(c.name)">{{ getInitials(c.name) }}</div>
                <div><p class="c-name">{{ c.name }}</p><p class="c-code">{{ c.customerCode }}</p></div>
              </div>
            </td>
            <td class="muted">{{ c.email }}</td>
            <td class="muted">{{ c.phone || "-" }}</td>
            <td>
              <span class="group-badge" *ngIf="c.customerGroup">{{ c.customerGroup }}</span>
              <span class="muted" *ngIf="!c.customerGroup">-</span>
            </td>
            <td>
              <span class="status-badge" [class.active]="c.status==='Active'" [class.inactive]="c.status!=='Active'">{{ c.status }}</span>
            </td>
            <td class="tr" *ngIf="canEdit || canDelete">
              <button class="tbl-btn" *ngIf="canEdit" (click)="toggleStatus(c)">
                {{ c.status === "Active" ? "Deactivate" : "Activate" }}
              </button>
              <button class="tbl-btn danger" *ngIf="canDelete" [disabled]="deletingId===c.id" (click)="delete(c)">
                {{ deletingId===c.id ? "..." : "Delete" }}
              </button>
            </td>
          </tr>
          <tr *ngIf="filtered.length===0">
            <td colspan="6" class="empty-row">
              <div class="empty-state">
                <p class="empty-title">No customers found</p>
                <p class="empty-sub">{{ search ? "No results for \"" + search + "\"" : "Add your first customer." }}</p>
              </div>
            </td>
          </tr>
        </ng-container>
      </tbody>
    </table>
    <div class="table-footer" *ngIf="!loading && customers.length > 0">
      Showing {{ filtered.length }} of {{ customers.length }} customers
    </div>
  </div>
</div>
'@, $utf8)
Write-Host "  [OK] list-customers HTML" -ForegroundColor Green

# ── 2. dashboard HTML - fix sum cards ─────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\dashboard\main\main-dashboard.component.html", @'
<div class="dashboard-content">

  <div class="page-header">
    <nav class="page-tabs">
      <a class="ptab active">Overview</a>
      <a class="ptab">Reports</a>
      <a class="ptab">Activity</a>
    </nav>
    <div class="page-actions">
      <button class="outline-btn" *ngIf="canViewReports">Export</button>
      <button class="primary-btn" *ngIf="canCreate">Add Customer</button>
    </div>
  </div>

  <!-- METRICS -->
  <div class="metrics-row">
    <div class="metric-card">
      <div class="metric-icon blue">
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="1" x2="12" y2="23"></line><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path></svg>
      </div>
      <div><p class="metric-label">TOTAL INCOME</p><p class="metric-value">BDT 12.4M</p></div>
    </div>
    <div class="metric-card">
      <div class="metric-icon red">
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18"></polyline><polyline points="17 6 23 6 23 12"></polyline></svg>
      </div>
      <div><p class="metric-label">TOTAL EXPENSE</p><p class="metric-value">BDT 8.2M</p></div>
    </div>
    <div class="metric-card border-green"><div><p class="metric-label">INCOME TODAY</p><p class="metric-value">BDT 45,000</p></div></div>
    <div class="metric-card border-red"><div><p class="metric-label">EXPENSE TODAY</p><p class="metric-value">BDT 12,500</p></div></div>
    <div class="metric-card"><div><p class="metric-label">INCOME THIS MONTH</p><p class="metric-value">BDT 840,000</p></div></div>
    <div class="metric-card"><div><p class="metric-label">EXPENSE THIS MONTH</p><p class="metric-value">BDT 320,000</p></div></div>
  </div>

  <!-- SUMMARY + TREND -->
  <div class="mid-row">
    <div class="summary-col">
      <div class="card sum-link" (click)="navigateTo('/customers/list')">
        <div class="sum-loading" *ngIf="loadingStats"><div class="mini-spin"></div></div>
        <p class="sum-val" *ngIf="!loadingStats">{{ totalCustomers }}</p>
        <p class="sum-label">CUSTOMERS</p>
      </div>
      <div class="card sum-link" (click)="navigateTo('/customers/companies')">
        <div class="sum-loading" *ngIf="loadingStats"><div class="mini-spin"></div></div>
        <p class="sum-val" *ngIf="!loadingStats">{{ totalCompanies }}</p>
        <p class="sum-label">COMPANIES</p>
      </div>
      <div class="card red-border">
        <p class="sum-val red">-BDT 11,395,628</p>
        <p class="sum-label">NET WORTH</p>
        <div class="net-row"><span>Goal: 350,000</span><span class="red">-3255%</span></div>
      </div>
    </div>
    <div class="card trend-card">
      <div class="trend-head">
        <h3 class="card-title">Financial Performance Trend</h3>
        <div class="legend">
          <div class="leg-item"><span class="leg-dot navy"></span>Income</div>
          <div class="leg-item"><span class="leg-dot amber"></span>Expense</div>
        </div>
      </div>
      <svg viewBox="0 0 1000 180" preserveAspectRatio="none" style="width:100%;height:180px">
        <defs><linearGradient id="ig" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stop-color="#003874" stop-opacity="0.12"/><stop offset="100%" stop-color="#003874" stop-opacity="0"/></linearGradient></defs>
        <path d="M0,140 Q100,40 200,90 T400,110 T600,70 T800,30 T1000,90 L1000,180 L0,180 Z" fill="url(#ig)"/>
        <path d="M0,140 Q100,40 200,90 T400,110 T600,70 T800,30 T1000,90" fill="none" stroke="#003874" stroke-width="2.5"/>
        <path d="M0,165 Q100,130 200,148 T400,140 T600,158 T800,120 T1000,140" fill="none" stroke="#F59E0B" stroke-dasharray="6 3" stroke-width="2"/>
      </svg>
      <div class="trend-labels"><span>JUL 2025</span><span>SEP</span><span>NOV</span><span>JAN 2026</span><span>MAR</span><span>MAY</span><span>JUN 2026</span></div>
    </div>
  </div>

  <!-- TABLES -->
  <div class="two-col">
    <div class="card">
      <div class="card-head">
        <h3 class="card-title">Recent Clients</h3>
        <button class="text-btn" *ngIf="canCreate" (click)="navigateTo('/customers/add')">+ Add</button>
      </div>
      <table class="tbl">
        <thead><tr><th>IMAGE</th><th>NAME</th><th class="tr">CREATED</th><th class="tr" *ngIf="canEdit">ACTIONS</th></tr></thead>
        <tbody>
          <tr *ngIf="loadingStats"><td colspan="4" style="text-align:center;padding:20px;color:#64748b"><div class="mini-spin" style="margin:auto"></div></td></tr>
          <tr *ngFor="let c of recentCustomers">
            <td><div class="av" [ngClass]="avatarClass(c.name)">{{ getInitials(c.name) }}</div></td>
            <td class="fw6">{{ c.name }}</td>
            <td class="tr muted">{{ c.createdAt | date:"dd/MM/yyyy" }}</td>
            <td class="tr" *ngIf="canEdit"><button class="tbl-btn" (click)="navigateTo('/customers/list')">View</button></td>
          </tr>
          <tr *ngIf="!loadingStats && recentCustomers.length===0">
            <td colspan="4" style="text-align:center;padding:20px;color:#64748b">No customers yet.</td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="card">
      <div class="card-head">
        <h3 class="card-title">Recent Invoices</h3>
        <div style="display:flex;align-items:center;gap:8px">
          <div class="progress-wrap"><div class="progress-bar" style="width:31%"></div></div>
          <span style="font-size:11px;font-weight:700;color:#64748b">31% Paid</span>
        </div>
      </div>
      <table class="tbl">
        <thead><tr><th>#</th><th>ACCOUNT</th><th class="tr">STATUS</th><th class="tr" *ngIf="canEdit">ACTIONS</th></tr></thead>
        <tbody>
          <tr><td class="inv-num">INV-Jun090652026_Linnex</td><td>Linnex Electronics Bangladesh</td><td class="tr"><span class="badge unpaid">Unpaid</span></td><td class="tr" *ngIf="canEdit"><button class="tbl-btn">Approve</button></td></tr>
          <tr><td class="inv-num">INV-Jun090652026_Somatec</td><td>SOMATEC PHARMACEUTICALS LTD.</td><td class="tr"><span class="badge unpaid">Unpaid</span></td><td class="tr" *ngIf="canEdit"><button class="tbl-btn">Approve</button></td></tr>
          <tr><td class="inv-num">INV-Jun07062026_WHPL</td><td>White Horse Pharmaceuticals Ltd.</td><td class="tr"><span class="badge unpaid">Unpaid</span></td><td class="tr" *ngIf="canEdit"><button class="tbl-btn">Approve</button></td></tr>
        </tbody>
      </table>
    </div>
  </div>

  <!-- EXPENSE + CATEGORY + BALANCES -->
  <div class="three-col">
    <div class="card">
      <div class="card-head"><h3 class="card-title">Latest Expense</h3><button class="text-btn" *ngIf="canCreate">+ Add</button></div>
      <div class="expense-list">
        <div class="exp-item" *ngFor="let item of latestExpenses">
          <div><p class="exp-date">{{ item.date }}</p><p class="exp-desc">{{ item.desc }}</p></div>
          <p class="exp-amt">BDT {{ item.amount }}</p>
        </div>
      </div>
    </div>
    <div class="card">
      <h3 class="card-title" style="margin-bottom:16px">Expense by Category</h3>
      <div class="cat-list">
        <div class="cat-item" *ngFor="let c of expenseCategories">
          <div class="cat-head"><span>{{ c.name }}</span><span>{{ c.amount }}</span></div>
          <div class="cat-track"><div class="cat-fill" [style.width]="c.percent" [style.background]="c.color"></div></div>
        </div>
      </div>
    </div>
    <div class="card">
      <h3 class="card-title" style="margin-bottom:16px">Account Balances</h3>
      <div class="bal-list">
        <div class="bal-item" *ngFor="let a of accountBalances"><span>{{ a.name }}</span><span class="fw7">{{ a.amount }}</span></div>
      </div>
    </div>
  </div>

  <!-- SALES + CALENDAR -->
  <div class="two-col">
    <div class="card sales-card">
      <h3 class="card-title">Sales Distribution</h3>
      <div class="donut-wrap">
        <svg viewBox="0 0 100 100" style="width:130px;height:130px">
          <circle cx="50" cy="50" r="40" fill="transparent" stroke="#E2E8F0" stroke-width="8"/>
          <circle cx="50" cy="50" r="40" fill="transparent" stroke="#003874" stroke-width="8" stroke-dasharray="251.2" stroke-dashoffset="60" stroke-linecap="round" transform="rotate(-90 50 50)"/>
        </svg>
        <div class="donut-center"><span class="donut-lbl">Total Sales</span><span class="donut-val">1.4k</span></div>
      </div>
      <div class="sales-stats">
        <div class="stat"><p class="stat-lbl">COUNT</p><p class="stat-val">842</p></div>
        <div class="stat"><p class="stat-lbl">VOLUME</p><p class="stat-val">BDT 4.2M</p></div>
      </div>
    </div>
    <div class="card">
      <div class="cal-head">
        <h3 class="card-title">JUNE 2026</h3>
        <div style="display:flex;gap:5px">
          <button class="cal-ghost">Today</button>
          <button class="cal-arrow">&#8249;</button>
          <button class="cal-arrow">&#8250;</button>
        </div>
      </div>
      <div class="cal-grid">
        <div class="cal-dn" *ngFor="let d of dayNames">{{ d }}</div>
        <div class="cal-day empty">31</div>
        <div class="cal-day" *ngFor="let d of calDays" [class.today]="d===14">{{ d }}</div>
      </div>
    </div>
  </div>

</div>
'@, $utf8)
Write-Host "  [OK] dashboard HTML" -ForegroundColor Green

Write-Host "All fixed!" -ForegroundColor Cyan
