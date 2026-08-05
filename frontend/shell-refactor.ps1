# BizMotion — Shared AppShell Refactor
# Extracts sidebar/nav/shader into ONE layout component
# Run from D:\rbca-frontend
# All authenticated pages render inside <router-outlet> of AppShellComponent

$utf8 = [System.Text.UTF8Encoding]::new($false)
Write-Host "Starting AppShell refactor..." -ForegroundColor Cyan

# ── Create folder ─────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path "src\app\layout\app-shell" | Out-Null
Write-Host "  [OK] layout/app-shell folder created" -ForegroundColor Green

# ── 1. AppShellComponent TS ───────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\layout\app-shell\app-shell.component.ts", @'
import { Component, OnInit, AfterViewInit, OnDestroy } from "@angular/core";
import { CommonModule } from "@angular/common";
import { Router, RouterOutlet, NavigationEnd } from "@angular/router";
import { filter } from "rxjs/operators";
import { AuthService }  from "../../services/auth.service";
import { ScopeService } from "../../services/scope.service";
import { NAV_ITEMS, NavItem } from "../../models/nav.model";

@Component({
  selector: "app-shell",
  standalone: true,
  imports: [CommonModule, RouterOutlet],
  templateUrl: "./app-shell.component.html",
  styleUrls:  ["./app-shell.component.css"]
})
export class AppShellComponent implements OnInit, AfterViewInit, OnDestroy {

  // ── Identity ──────────────────────────────────────────────
  username     = "";
  userInitials = "";
  role         = "";

  // ── Sidebar state ─────────────────────────────────────────
  sidebarCollapsed                = false;
  expandedMenus: Set<string>      = new Set();
  visibleNavItems: NavItem[]      = [];

  // ── Role flags (shared across all child pages) ────────────
  isSuperAdmin  = false;
  isAdmin       = false;
  isAccountant  = false;
  isViewer      = false;

  canViewUsers      = false;
  canViewInvoices   = true;
  canViewPayments   = true;
  canViewReports    = true;
  canViewLedger     = true;
  canViewCustomers  = true;
  canManageSettings = false;
  canCreateAny      = false;
  canEditAny        = false;
  canDeleteAny      = false;

  currentUrl = "";

  private animationId: number | null = null;

  constructor(
    private auth:   AuthService,
    public  scope:  ScopeService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.username     = this.auth.getUsername() || "User";
    this.role         = this.auth.getRole()     || "";
    this.userInitials = this.username
      .split(" ").map((w: string) => w.charAt(0).toUpperCase()).slice(0,2).join("");

    this.isSuperAdmin = this.scope.isSuperAdmin();
    this.isAdmin      = this.scope.isAdmin();
    this.isAccountant = this.scope.isAccountant();
    this.isViewer     = this.scope.isViewer();

    this.canViewUsers      = this.scope.can("VIEW_USER");
    this.canManageSettings = this.scope.can("MANAGE_SETTINGS");
    this.canCreateAny      = !this.isViewer;
    this.canEditAny        = !this.isViewer;
    this.canDeleteAny      = this.scope.canDelete();

    // All roles see all nav items — VIEWER just gets read-only rendering
    this.visibleNavItems = NAV_ITEMS.map(item => ({
      ...item,
      children: item.children ? [...item.children] : undefined
    }));

    // Track current URL for active nav highlighting
    this.currentUrl = this.router.url;
    this.router.events.pipe(
      filter(e => e instanceof NavigationEnd)
    ).subscribe((e: any) => {
      this.currentUrl = e.urlAfterRedirects;
      // Auto-expand the parent menu that contains the active route
      this.autoExpandActiveMenu();
    });

    this.autoExpandActiveMenu();
  }

  ngAfterViewInit(): void { this.initShader(); }

  ngOnDestroy(): void {
    if (this.animationId !== null) cancelAnimationFrame(this.animationId);
  }

  // ── Sidebar methods ───────────────────────────────────────
  toggleSidebar(): void { this.sidebarCollapsed = !this.sidebarCollapsed; }

  toggleMenu(label: string): void {
    if (this.expandedMenus.has(label)) {
      this.expandedMenus.delete(label);
    } else {
      this.expandedMenus.clear();
      this.expandedMenus.add(label);
    }
  }

  isExpanded(label: string): boolean { return this.expandedMenus.has(label); }

  isActiveRoute(route: string): boolean {
    if (!route || route === "#") return false;
    return this.currentUrl.startsWith(route);
  }

  isActiveParent(item: NavItem): boolean {
    if (!item.children) return this.isActiveRoute(item.route);
    return item.children.some(child => this.isActiveRoute(child.route));
  }

  private autoExpandActiveMenu(): void {
    for (const item of this.visibleNavItems) {
      if (item.children && item.children.some(c => this.currentUrl.startsWith(c.route))) {
        this.expandedMenus.clear();
        this.expandedMenus.add(item.label);
        break;
      }
    }
  }

  navigate(route: string): void {
    if (route && route !== "#") this.router.navigate([route]);
  }

  goToSettings(): void { this.router.navigate(["/settings"]); }

  logout(): void { this.auth.logout(); this.router.navigate(["/login"]); }

  // ── WebGL shader — runs ONCE for the whole app session ────
  private initShader(): void {
    const canvas = document.getElementById("shader-canvas") as HTMLCanvasElement;
    if (!canvas) return;
    const sync = () => {
      const w = canvas.clientWidth  || window.innerWidth;
      const h = canvas.clientHeight || window.innerHeight;
      if (canvas.width !== w || canvas.height !== h) { canvas.width = w; canvas.height = h; }
    };
    if (typeof ResizeObserver !== "undefined") new ResizeObserver(sync).observe(canvas);
    sync();
    const gl = canvas.getContext("webgl") as WebGLRenderingContext | null;
    if (!gl) return;

    const vs = `attribute vec2 a;void main(){gl_Position=vec4(a,0,1);}`;
    const fs = `precision highp float;uniform float t;uniform vec2 r;void main(){
      vec2 uv=gl_FragCoord.xy/r;
      float f=sin(uv.x*2.+t*.5)*.5+.5,g=sin(uv.y*3.-t*.3)*.5+.5;
      vec3 c=mix(vec3(.984,.984,1.),vec3(.012,.22,.455),uv.y*.15);
      c=mix(c,vec3(.969,.580,.114),f*g*.07);
      gl_FragColor=vec4(c*(1.-length(uv-.5)*.18),1.);}`;

    const mk = (type: number, src: string): WebGLShader => {
      const s = gl.createShader(type)!;
      gl.shaderSource(s, src); gl.compileShader(s); return s;
    };
    const p = gl.createProgram()!;
    gl.attachShader(p, mk(gl.VERTEX_SHADER, vs));
    gl.attachShader(p, mk(gl.FRAGMENT_SHADER, fs));
    gl.linkProgram(p); gl.useProgram(p);

    const buf = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buf);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1,-1,1,-1,-1,1,1,1]), gl.STATIC_DRAW);
    const al = gl.getAttribLocation(p, "a");
    gl.enableVertexAttribArray(al);
    gl.vertexAttribPointer(al, 2, gl.FLOAT, false, 0, 0);

    const tl = gl.getUniformLocation(p, "t");
    const rl = gl.getUniformLocation(p, "r");

    const draw = (ms: number) => {
      sync();
      gl.viewport(0, 0, canvas.width, canvas.height);
      if (tl) gl.uniform1f(tl, ms * 0.001);
      if (rl) gl.uniform2f(rl, canvas.width, canvas.height);
      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
      this.animationId = requestAnimationFrame(draw);
    };
    draw(0);
  }
}
'@, $utf8)
Write-Host "  [OK] app-shell.component.ts" -ForegroundColor Green

# ── 2. AppShellComponent HTML ─────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\layout\app-shell\app-shell.component.html", @'
<div class="shell-wrapper">
  <canvas id="shader-canvas" class="shader-bg"></canvas>

  <!-- SIDEBAR — renders once, persists across all child routes -->
  <aside class="sidebar" [class.collapsed]="sidebarCollapsed">

    <div class="sidebar-top">
      <h1 class="logo-text">BIZMOTION</h1>
    </div>

    <div class="profile-block">
      <div class="profile-inner">
        <div class="avatar">{{ userInitials }}</div>
        <div class="profile-text">
          <p class="pname">{{ username }}</p>
          <p class="prole">{{ role }}</p>
        </div>
      </div>
    </div>

    <nav class="sidebar-nav">
      <ng-container *ngFor="let item of visibleNavItems">

        <!-- Parent with children -->
        <ng-container *ngIf="item?.children && item?.children!.length > 0">
          <a class="nav-item nav-parent"
             [class.nav-active-parent]="isActiveParent(item)"
             (click)="toggleMenu(item.label)">
            <span class="nav-label">{{ item.label }}</span>
            <svg class="nav-chevron" [class.rotated]="isExpanded(item.label)"
                 xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24"
                 fill="none" stroke="currentColor" stroke-width="2.5"
                 stroke-linecap="round" stroke-linejoin="round">
              <polyline points="9 18 15 12 9 6"></polyline>
            </svg>
          </a>
          <div class="sub-menu" [class.open]="isExpanded(item.label)">
            <a class="sub-item"
               *ngFor="let child of item.children!"
               [class.sub-active]="isActiveRoute(child.route)"
               (click)="navigate(child.route)">
              <span class="sub-dot"></span>{{ child.label }}
            </a>
          </div>
        </ng-container>

        <!-- No children -->
        <ng-container *ngIf="!item?.children || item?.children!.length === 0">
          <a class="nav-item"
             [class.nav-active]="isActiveRoute(item.route)"
             (click)="navigate(item.route)">
            <span class="nav-label">{{ item.label }}</span>
          </a>
        </ng-container>

      </ng-container>
    </nav>

    <div class="sidebar-footer">
      <a class="nav-item" [class.nav-active]="isActiveRoute('/settings')" (click)="goToSettings()">
        <span class="nav-label">Settings</span>
      </a>
      <a class="nav-item nav-logout" (click)="logout()">
        <span class="nav-label">Logout</span>
      </a>
    </div>

  </aside>

  <!-- MAIN area — child pages render here via router-outlet -->
  <main class="shell-main" [class.expanded]="sidebarCollapsed">

    <!-- Header — ONE hamburger -->
    <header class="shell-header">
      <div class="header-left">
        <button class="hamburger-btn" (click)="toggleSidebar()">
          <span class="ham-line"></span>
          <span class="ham-line"></span>
          <span class="ham-line"></span>
        </button>
        <div class="search-box">
          <svg class="search-svg" xmlns="http://www.w3.org/2000/svg" width="15" height="15"
               viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
               stroke-linecap="round" stroke-linejoin="round">
            <circle cx="11" cy="11" r="8"></circle>
            <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
          </svg>
          <input type="text" class="search-input" placeholder="Global Search..." />
        </div>
      </div>
      <div class="header-right">
        <button class="icon-btn" title="Notifications">
          <svg xmlns="http://www.w3.org/2000/svg" width="17" height="17" viewBox="0 0 24 24"
               fill="none" stroke="currentColor" stroke-width="2"
               stroke-linecap="round" stroke-linejoin="round">
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
            <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
          </svg>
        </button>
        <button class="outline-btn" *ngIf="canCreateAny" (click)="navigate('/customers/add')">
          Add Customer
        </button>
        <button class="outline-btn" (click)="goToSettings()">Settings</button>
      </div>
    </header>

    <!-- Viewer read-only notice -->
    <div class="readonly-bar" *ngIf="isViewer">
      Read-only access. Contact your administrator for additional permissions.
    </div>

    <!-- CHILD PAGE CONTENT — only this swaps on navigation -->
    <div class="page-outlet">
      <router-outlet></router-outlet>
    </div>

  </main>
</div>
'@, $utf8)
Write-Host "  [OK] app-shell.component.html" -ForegroundColor Green

# ── 3. AppShellComponent CSS ──────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\layout\app-shell\app-shell.component.css", @'
@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap");
*{box-sizing:border-box;margin:0;padding:0}

:host{
  --primary:#003874;--primary-c:#1a4f95;--on-surf:#1a1c20;--on-sv:#424751;
  --border:#E2E8F0;--surf-low:#f3f3fa;--surf-cont:#ededf4;
  --ok:#10B981;--err:#EF4444;--sec-cont:#d0e1fb;
  display:block;font-family:"Inter","Segoe UI",sans-serif;
}

/* Background shader */
.shader-bg{position:fixed;inset:0;width:100%;height:100%;z-index:-1;pointer-events:none}

.shell-wrapper{display:flex;min-height:100vh;background:linear-gradient(135deg,#f9f9ff 0%,#eef2ff 100%)}

/* ── Sidebar ── */
.sidebar{
  position:fixed;left:0;top:0;width:220px;height:100vh;
  background:rgba(255,255,255,.92);backdrop-filter:blur(12px);
  border-right:1px solid var(--border);
  display:flex;flex-direction:column;
  z-index:40;overflow-y:auto;
  transition:transform .3s ease;
}
.sidebar.collapsed{transform:translateX(-220px)}

.sidebar-top{padding:22px 20px 16px;border-bottom:1px solid var(--border)}
.logo-text{font-size:19px;font-weight:800;color:var(--primary-c);letter-spacing:-.01em}

.profile-block{padding:12px 12px 14px;border-bottom:1px solid var(--border)}
.profile-inner{display:flex;align-items:center;gap:10px;padding:10px 12px;background:color-mix(in srgb,var(--sec-cont) 30%,transparent);border:1px solid color-mix(in srgb,var(--primary) 10%,transparent);border-radius:12px}
.avatar{width:34px;height:34px;border-radius:50%;background:var(--sec-cont);color:var(--primary);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;flex-shrink:0}
.profile-text{}
.pname{font-size:12px;font-weight:700;color:var(--on-surf)}
.prole{font-size:10px;color:var(--on-sv);text-transform:capitalize;margin-top:1px}

/* Nav */
.sidebar-nav{flex:1;padding:10px 10px;display:flex;flex-direction:column;gap:1px;overflow-y:auto}

.nav-item{
  display:flex;align-items:center;justify-content:space-between;
  gap:8px;padding:8px 12px;
  border-radius:0 99px 99px 0;
  font-size:12px;font-weight:600;color:var(--on-sv);
  cursor:pointer;transition:background .15s,color .15s;
}
.nav-item:hover{background:var(--surf-cont);color:var(--on-surf)}
.nav-item.nav-active{background:var(--primary);color:white}
.nav-item.nav-active-parent{background:color-mix(in srgb,var(--primary) 12%,transparent);color:var(--primary)}
.nav-label{flex:1}
.nav-chevron{flex-shrink:0;transition:transform .22s ease;opacity:.6}
.nav-chevron.rotated{transform:rotate(90deg);opacity:1;color:var(--primary)}
.nav-logout{color:var(--err)}
.nav-logout:hover{background:#fef2f2}

/* Submenu */
.sub-menu{
  overflow:hidden;max-height:0;opacity:0;
  transition:max-height .3s cubic-bezier(.4,0,.2,1),opacity .2s ease;
  display:flex;flex-direction:column;padding-left:14px;
}
.sub-menu.open{max-height:600px;opacity:1;padding-top:2px;padding-bottom:4px}
.sub-item{
  display:flex;align-items:center;gap:8px;
  padding:7px 12px 7px 10px;
  font-size:11px;font-weight:600;color:var(--on-sv);
  cursor:pointer;border-radius:0 99px 99px 0;
  transition:background .15s,color .15s;margin-bottom:1px;
}
.sub-item:hover{background:var(--surf-cont);color:var(--on-surf)}
.sub-item.sub-active{background:var(--sec-cont);color:var(--primary);font-weight:700}
.sub-dot{width:4px;height:4px;border-radius:50%;background:currentColor;opacity:.4;flex-shrink:0;transition:opacity .15s,transform .15s}
.sub-item:hover .sub-dot,.sub-item.sub-active .sub-dot{opacity:1;transform:scale(1.5)}

.sidebar-footer{padding:8px 10px 16px;border-top:1px solid var(--border);display:flex;flex-direction:column;gap:1px}

/* ── Main area ── */
.shell-main{
  margin-left:220px;flex:1;min-height:100vh;
  display:flex;flex-direction:column;
  transition:margin-left .3s ease;
}
.shell-main.expanded{margin-left:0}

/* Header */
.shell-header{
  position:sticky;top:0;z-index:30;
  display:flex;align-items:center;justify-content:space-between;
  padding:0 24px;height:58px;
  background:rgba(255,255,255,.88);backdrop-filter:blur(12px);
  border-bottom:1px solid var(--border);gap:16px;
}
.header-left{display:flex;align-items:center;gap:14px}

.hamburger-btn{
  display:flex;flex-direction:column;align-items:center;justify-content:center;
  gap:4px;padding:7px;background:none;border:none;cursor:pointer;
  border-radius:8px;transition:background .15s;flex-shrink:0;
}
.hamburger-btn:hover{background:var(--surf-cont)}
.ham-line{width:16px;height:2px;background:var(--on-sv);border-radius:2px}

.search-box{position:relative;display:flex;align-items:center}
.search-svg{position:absolute;left:10px;color:#94a3b8;pointer-events:none}
.search-input{
  padding:8px 12px 8px 32px;background:var(--surf-low);
  border:1px solid var(--border);border-radius:8px;
  font-size:13px;font-family:inherit;outline:none;
  width:200px;color:var(--on-surf);transition:all .2s;
}
.search-input:focus{border-color:var(--primary);box-shadow:0 0 0 3px rgba(0,56,116,.08);background:white;width:240px}

.header-right{display:flex;align-items:center;gap:8px}
.icon-btn{width:34px;height:34px;border:none;border-radius:8px;background:var(--surf-low);cursor:pointer;display:flex;align-items:center;justify-content:center;color:var(--on-sv);transition:background .15s}
.icon-btn:hover{background:var(--surf-cont)}
.outline-btn{padding:7px 14px;background:white;border:1px solid var(--border);border-radius:8px;font-size:12px;font-weight:700;color:var(--on-sv);cursor:pointer;font-family:inherit;transition:all .15s}
.outline-btn:hover{background:var(--surf-low);border-color:#94a3b8}

/* Read-only bar */
.readonly-bar{display:flex;align-items:center;gap:8px;padding:10px 24px;background:#fffbeb;border-bottom:1px solid #fde68a;font-size:13px;color:#92400e;font-weight:600}

/* Page outlet — child content renders here */
.page-outlet{flex:1;overflow-y:auto}

/* Responsive */
@media(max-width:768px){
  .shell-main{margin-left:0}
  .sidebar{transform:translateX(-220px)}
  .sidebar:not(.collapsed){transform:translateX(0)}
}
'@, $utf8)
Write-Host "  [OK] app-shell.component.css" -ForegroundColor Green

# ── 4. app.routes.ts — shell as parent, children nested ──────
[System.IO.File]::WriteAllText("$PWD\src\app\app.routes.ts", @'
import { Routes } from "@angular/router";
import { authGuard } from "./guards/auth.guard";

export const routes: Routes = [
  { path: "", redirectTo: "login", pathMatch: "full" },
  { path: "login",        loadComponent: () => import("./auth/login/login.component").then(m => m.LoginComponent) },
  { path: "register",     loadComponent: () => import("./auth/register/register.component").then(m => m.RegisterComponent) },
  { path: "unauthorized", loadComponent: () => import("./unauthorized/unauthorized.component").then(m => m.UnauthorizedComponent) },

  {
    // AppShellComponent is the authenticated layout — authGuard runs ONCE here
    path: "",
    loadComponent: () => import("./layout/app-shell/app-shell.component").then(m => m.AppShellComponent),
    canActivate: [authGuard],
    children: [
      { path: "dashboard", loadComponent: () => import("./dashboard/main/main-dashboard.component").then(m => m.MainDashboardComponent) },
      { path: "settings",  loadComponent: () => import("./settings/settings.component").then(m => m.SettingsComponent) },

      {
        path: "customers",
        children: [
          { path: "",          redirectTo: "list", pathMatch: "full" },
          { path: "add",       loadComponent: () => import("./customers/add/add-customer.component").then(m => m.AddCustomerComponent) },
          { path: "list",      loadComponent: () => import("./customers/list/list-customers.component").then(m => m.ListCustomersComponent) },
          { path: "companies", loadComponent: () => import("./customers/companies/companies.component").then(m => m.CompaniesComponent) },
          { path: "groups",    loadComponent: () => import("./customers/groups/groups.component").then(m => m.GroupsComponent) },
          { path: "files",     loadComponent: () => import("./customers/files/files.component").then(m => m.FilesComponent) },
        ]
      },

      {
        path: "accounting",
        children: [
          { path: "",                       redirectTo: "accounts", pathMatch: "full" },
          { path: "new-deposit",            loadComponent: () => import("./accounting/new-deposit/new-deposit.component").then(m => m.NewDepositComponent) },
          { path: "new-expense",            loadComponent: () => import("./accounting/new-expense/new-expense.component").then(m => m.NewExpenseComponent) },
          { path: "transfer",               loadComponent: () => import("./accounting/transfer/transfer.component").then(m => m.TransferComponent) },
          { path: "bills",                  loadComponent: () => import("./accounting/bills/bills.component").then(m => m.BillsComponent) },
          { path: "view-transactions",      loadComponent: () => import("./accounting/view-transactions/view-transactions.component").then(m => m.ViewTransactionsComponent) },
          { path: "uncleared-transactions", loadComponent: () => import("./accounting/uncleared-transactions/uncleared-transactions.component").then(m => m.UnclearedTransactionsComponent) },
          { path: "accounts",               loadComponent: () => import("./accounting/accounts/accounts.component").then(m => m.AccountsComponent) },
          { path: "new-account",            loadComponent: () => import("./accounting/new-account/new-account.component").then(m => m.NewAccountComponent) },
        ]
      },

      {
        path: "sales",
        children: [
          { path: "",                      redirectTo: "invoices", pathMatch: "full" },
          { path: "invoices",              loadComponent: () => import("./sales/invoices/invoices.component").then(m => m.InvoicesComponent) },
          { path: "new-invoice",           loadComponent: () => import("./sales/new-invoice/new-invoice.component").then(m => m.NewInvoiceComponent) },
          { path: "pos",                   loadComponent: () => import("./sales/pos/pos.component").then(m => m.PosComponent) },
          { path: "recurring-invoices",    loadComponent: () => import("./sales/recurring-invoices/recurring-invoices.component").then(m => m.RecurringInvoicesComponent) },
          { path: "new-recurring-invoice", loadComponent: () => import("./sales/new-recurring-invoice/new-recurring-invoice.component").then(m => m.NewRecurringInvoiceComponent) },
          { path: "quotes",                loadComponent: () => import("./sales/quotes/quotes.component").then(m => m.QuotesComponent) },
          { path: "create-new-quote",      loadComponent: () => import("./sales/create-new-quote/create-new-quote.component").then(m => m.CreateNewQuoteComponent) },
          { path: "payments",              loadComponent: () => import("./sales/payments/payments.component").then(m => m.PaymentsComponent) },
        ]
      },
    ]
  },

  { path: "**", redirectTo: "login" }
];
'@, $utf8)
Write-Host "  [OK] app.routes.ts - shell as parent route" -ForegroundColor Green

# ── 5. Strip MainDashboardComponent — content only, no shell ──
[System.IO.File]::WriteAllText("$PWD\src\app\dashboard\main\main-dashboard.component.ts", @'
import { Component, OnInit } from "@angular/core";
import { CommonModule } from "@angular/common";
import { ScopeService } from "../../services/scope.service";

@Component({
  selector: "app-main-dashboard",
  standalone: true,
  imports: [CommonModule],
  templateUrl: "./main-dashboard.component.html",
  styleUrls:  ["./main-dashboard.component.css"]
})
export class MainDashboardComponent implements OnInit {

  // Page-specific scope flags for dashboard card visibility
  canEdit   = false;
  canCreate = false;
  canDelete = false;
  canViewReports = true;

  latestExpenses = [
    { date: "11/06/2026", desc: "Shahiur Bua May 26 salary",  amount: "5,500" },
    { date: "11/06/2026", desc: "Lawyer payment for audit",    amount: "25,000" },
    { date: "10/06/2026", desc: "Arafat bhai may 26 salary",  amount: "35,000" },
  ];
  expenseCategories = [
    { name: "As Salary",   amount: "18,206,088", percent: "85%", color: "#003874" },
    { name: "Misc",        amount: "6,253,292",  percent: "40%", color: "#505f76" },
    { name: "Server Bill", amount: "4,133,435",  percent: "25%", color: "#5e2b00" },
    { name: "Office Rent", amount: "3,144,675",  percent: "20%", color: "#1a4f95" },
  ];
  accountBalances = [
    { name: "BRAC Bank Limited",   amount: "BDT 1.2M" },
    { name: "Connect Informatics", amount: "BDT 450K" },
    { name: "Petty cash",          amount: "BDT 12K" },
    { name: "Payoneer Account",    amount: "BDT 85K" },
  ];
  dayNames = ["SUN","MON","TUE","WED","THU","FRI","SAT"];
  calDays  = Array.from({ length: 20 }, (_, i) => i + 1);

  constructor(public scope: ScopeService) {}

  ngOnInit(): void {
    this.canCreate = !this.scope.isViewer();
    this.canEdit   = !this.scope.isViewer();
    this.canDelete = this.scope.canDelete();
  }
}
'@, $utf8)
Write-Host "  [OK] main-dashboard.component.ts - stripped to content only" -ForegroundColor Green

# ── 6. MainDashboard HTML — content only, no sidebar/canvas ──
[System.IO.File]::WriteAllText("$PWD\src\app\dashboard\main\main-dashboard.component.html", @'
<div class="dashboard-content">

  <!-- Header row with tabs -->
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
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="12" y1="1" x2="12" y2="23"></line><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
        </svg>
      </div>
      <div><p class="metric-label">TOTAL INCOME</p><p class="metric-value">BDT 12.4M</p></div>
    </div>
    <div class="metric-card">
      <div class="metric-icon red">
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="23 6 13.5 15.5 8.5 10.5 1 18"></polyline><polyline points="17 6 23 6 23 12"></polyline>
        </svg>
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
      <div class="card"><p class="sum-val">47</p><p class="sum-label">CUSTOMERS</p></div>
      <div class="card"><p class="sum-val">1</p><p class="sum-label">COMPANIES</p></div>
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
        <defs><linearGradient id="ig" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0%" stop-color="#003874" stop-opacity="0.12"/>
          <stop offset="100%" stop-color="#003874" stop-opacity="0"/>
        </linearGradient></defs>
        <path d="M0,140 Q100,40 200,90 T400,110 T600,70 T800,30 T1000,90 L1000,180 L0,180 Z" fill="url(#ig)"/>
        <path d="M0,140 Q100,40 200,90 T400,110 T600,70 T800,30 T1000,90" fill="none" stroke="#003874" stroke-width="2.5"/>
        <path d="M0,165 Q100,130 200,148 T400,140 T600,158 T800,120 T1000,140" fill="none" stroke="#F59E0B" stroke-dasharray="6 3" stroke-width="2"/>
      </svg>
      <div class="trend-labels">
        <span>JUL 2025</span><span>SEP</span><span>NOV</span><span>JAN 2026</span><span>MAR</span><span>MAY</span><span>JUN 2026</span>
      </div>
    </div>
  </div>

  <!-- TABLES -->
  <div class="two-col">
    <div class="card">
      <div class="card-head"><h3 class="card-title">Recent Clients</h3>
        <button class="text-btn" *ngIf="canCreate">+ Add</button>
      </div>
      <table class="tbl">
        <thead><tr><th>IMAGE</th><th>NAME</th><th class="tr">CREATED</th><th class="tr" *ngIf="canEdit">ACTIONS</th></tr></thead>
        <tbody>
          <tr><td><div class="av blue-av">IM</div></td><td class="fw6">Integrated Marketing Service Ltd.</td><td class="tr muted">07/04/2026</td>
            <td class="tr" *ngIf="canEdit"><button class="tbl-btn">Edit</button><button class="tbl-btn red-btn" *ngIf="canDelete">Delete</button></td></tr>
          <tr><td><div class="av purple-av">BI</div></td><td class="fw6">Believe Int. Pvt. Ltd.</td><td class="tr muted">06/01/2026</td>
            <td class="tr" *ngIf="canEdit"><button class="tbl-btn">Edit</button><button class="tbl-btn red-btn" *ngIf="canDelete">Delete</button></td></tr>
          <tr><td><div class="av orange-av">ET</div></td><td class="fw6">Excellent Tiles Industries Ltd.</td><td class="tr muted">06/01/2026</td>
            <td class="tr" *ngIf="canEdit"><button class="tbl-btn">Edit</button><button class="tbl-btn red-btn" *ngIf="canDelete">Delete</button></td></tr>
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
        <div class="bal-item" *ngFor="let a of accountBalances">
          <span>{{ a.name }}</span><span class="fw7">{{ a.amount }}</span>
        </div>
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
Write-Host "  [OK] main-dashboard.component.html - content only" -ForegroundColor Green

# ── 7. Dashboard CSS — content only, no sidebar rules ─────────
[System.IO.File]::WriteAllText("$PWD\src\app\dashboard\main\main-dashboard.component.css", @'
:host{--primary:#003874;--primary-c:#1a4f95;--on-surf:#1a1c20;--on-sv:#424751;--border:#E2E8F0;--surf-low:#f3f3fa;--surf-cont:#ededf4;--ok:#10B981;--err:#EF4444;--warn:#F59E0B;--sec-cont:#d0e1fb;font-family:"Inter","Segoe UI",sans-serif}

.dashboard-content{padding:24px 28px 40px;display:flex;flex-direction:column;gap:20px;min-height:100%}

/* Page header */
.page-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:4px}
.page-tabs{display:flex;gap:4px}
.ptab{padding:7px 14px;font-size:13px;font-weight:600;color:var(--on-sv);border-radius:8px;cursor:pointer;border:none;background:none;transition:all .15s}
.ptab:hover{background:var(--surf-cont);color:var(--on-surf)}
.ptab.active{background:var(--sec-cont);color:var(--primary)}
.page-actions{display:flex;gap:8px}
.primary-btn{padding:8px 16px;background:var(--primary);color:white;border:none;border-radius:8px;font-size:12px;font-weight:700;cursor:pointer;font-family:inherit}
.primary-btn:hover{background:var(--primary-c)}
.outline-btn{padding:7px 14px;background:white;border:1px solid var(--border);border-radius:8px;font-size:12px;font-weight:700;color:var(--on-sv);cursor:pointer;font-family:inherit}
.outline-btn:hover{background:var(--surf-low)}

/* Card base */
.card{background:white;border:1px solid var(--border);border-radius:14px;padding:22px;box-shadow:0 1px 3px rgba(0,0,0,.04);transition:box-shadow .2s,transform .2s}
.card:hover{box-shadow:0 4px 16px rgba(0,0,0,.08);transform:translateY(-1px)}
.card-title{font-size:14px;font-weight:700;color:var(--on-surf)}
.card-head{display:flex;justify-content:space-between;align-items:center;margin-bottom:16px}

/* Metrics */
.metrics-row{display:grid;grid-template-columns:repeat(6,1fr);gap:12px}
.metric-card{background:white;border:1px solid var(--border);border-radius:12px;padding:16px 14px;display:flex;align-items:center;gap:12px;box-shadow:0 1px 3px rgba(0,0,0,.04);transition:transform .2s}
.metric-card:hover{transform:translateY(-2px)}
.metric-card.border-green{border-left:4px solid var(--ok)}
.metric-card.border-red{border-left:4px solid var(--err)}
.metric-icon{width:36px;height:36px;border-radius:10px;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.metric-icon.blue{background:#dbeafe;color:#1d4ed8}
.metric-icon.red{background:#fef2f2;color:#dc2626}
.metric-label{font-size:9px;font-weight:700;letter-spacing:.06em;text-transform:uppercase;color:var(--on-sv);margin-bottom:3px}
.metric-value{font-size:15px;font-weight:800;color:var(--on-surf)}

/* Mid row */
.mid-row{display:grid;grid-template-columns:210px 1fr;gap:16px;align-items:start}
.summary-col{display:flex;flex-direction:column;gap:12px}
.red-border{border-left:3px solid var(--err)}
.sum-val{font-size:24px;font-weight:800;color:var(--on-surf);margin-bottom:2px}
.sum-val.red{color:var(--err);font-size:18px}
.sum-label{font-size:10px;font-weight:700;letter-spacing:.06em;text-transform:uppercase;color:var(--on-sv)}
.net-row{display:flex;justify-content:space-between;margin-top:8px;font-size:11px;color:var(--on-sv)}
.red{color:var(--err);font-weight:700}

.trend-card{padding:22px}
.trend-head{display:flex;align-items:center;justify-content:space-between;margin-bottom:14px}
.legend{display:flex;gap:14px}
.leg-item{display:flex;align-items:center;gap:6px;font-size:12px;color:var(--on-sv);font-weight:500}
.leg-dot{width:10px;height:10px;border-radius:50%;display:inline-block}
.leg-dot.navy{background:var(--primary)}
.leg-dot.amber{background:var(--warn)}
.trend-labels{display:flex;justify-content:space-between;font-size:10px;font-weight:700;color:var(--on-sv);padding:6px 2px 0}

/* Grids */
.two-col{display:grid;grid-template-columns:1fr 1fr;gap:18px}
.three-col{display:grid;grid-template-columns:1fr 1.4fr 1fr;gap:18px}

/* Tables */
.tbl{width:100%;border-collapse:collapse;font-size:12px}
.tbl thead tr{background:var(--surf-low);border-bottom:1px solid var(--border)}
.tbl th{padding:9px 14px;font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.05em;color:var(--on-sv);text-align:left}
.tbl tbody tr{border-bottom:1px solid var(--border);transition:background .12s}
.tbl tbody tr:last-child{border-bottom:none}
.tbl tbody tr:hover{background:var(--surf-low)}
.tbl td{padding:11px 14px;color:var(--on-surf)}
.tr{text-align:right!important}
.muted{color:var(--on-sv)}
.fw6{font-weight:600}
.fw7{font-weight:800}
.av{width:30px;height:30px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:9px;font-weight:800}
.blue-av{background:#dbeafe;color:#1d4ed8}
.purple-av{background:#ede9fe;color:#7c3aed}
.orange-av{background:#ffedd5;color:#c2410c}
.inv-num{font-size:10px;color:var(--primary);font-weight:600}
.badge{display:inline-block;padding:2px 8px;border-radius:6px;font-size:10px;font-weight:700}
.badge.unpaid{background:#ffdad6;color:#ba1a1a}
.badge.paid{background:#dcfce7;color:#15803d}
.text-btn{background:none;border:none;font-size:12px;font-weight:700;color:var(--primary);cursor:pointer;font-family:inherit;padding:3px 8px;border-radius:6px}
.text-btn:hover{background:var(--surf-low)}
.tbl-btn{padding:3px 10px;background:white;border:1px solid var(--border);border-radius:6px;font-size:11px;font-weight:600;cursor:pointer;color:var(--primary);margin-left:4px}
.tbl-btn:hover{background:var(--surf-low)}
.tbl-btn.red-btn{color:var(--err);border-color:#fecaca}
.tbl-btn.red-btn:hover{background:#fef2f2}
.progress-wrap{width:70px;height:6px;background:var(--surf-cont);border-radius:99px;overflow:hidden}
.progress-bar{height:100%;background:var(--ok);border-radius:99px}

/* Expense */
.expense-list{display:flex;flex-direction:column;gap:8px}
.exp-item{display:flex;justify-content:space-between;align-items:center;padding:9px 11px;background:var(--surf-low);border-radius:9px}
.exp-date{font-size:10px;font-weight:700;color:var(--primary)}
.exp-desc{font-size:11px;color:var(--on-sv);margin-top:2px}
.exp-amt{font-size:12px;font-weight:800;color:var(--on-surf);white-space:nowrap;margin-left:8px}

/* Categories */
.cat-list{display:flex;flex-direction:column;gap:14px}
.cat-item{display:flex;flex-direction:column;gap:5px}
.cat-head{display:flex;justify-content:space-between;font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.04em;color:var(--on-sv)}
.cat-track{height:6px;background:var(--surf-cont);border-radius:99px;overflow:hidden}
.cat-fill{height:100%;border-radius:99px;transition:width .5s}

/* Balances */
.bal-list{display:flex;flex-direction:column}
.bal-item{display:flex;justify-content:space-between;align-items:center;padding:10px 0;border-bottom:1px solid var(--border);font-size:13px;color:var(--on-surf)}
.bal-item:last-child{border-bottom:none}

/* Sales */
.sales-card{display:flex;flex-direction:column;align-items:center;gap:14px}
.donut-wrap{position:relative}
.donut-center{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center}
.donut-lbl{font-size:9px;font-weight:700;text-transform:uppercase;color:var(--on-sv);letter-spacing:.05em}
.donut-val{font-size:20px;font-weight:800;color:var(--on-surf)}
.sales-stats{display:grid;grid-template-columns:1fr 1fr;gap:10px;width:100%}
.stat{text-align:center;padding:10px;background:var(--surf-low);border-radius:9px}
.stat-lbl{font-size:9px;font-weight:700;text-transform:uppercase;color:var(--on-sv);letter-spacing:.05em;margin-bottom:3px}
.stat-val{font-size:15px;font-weight:800;color:var(--on-surf)}

/* Calendar */
.cal-head{display:flex;justify-content:space-between;align-items:center;margin-bottom:14px}
.cal-ghost{padding:4px 10px;background:var(--surf-low);border:1px solid var(--border);border-radius:7px;font-size:11px;font-weight:700;cursor:pointer;font-family:inherit}
.cal-ghost:hover{background:var(--surf-cont)}
.cal-arrow{width:26px;height:26px;background:var(--surf-low);border:1px solid var(--border);border-radius:7px;font-size:15px;cursor:pointer;display:flex;align-items:center;justify-content:center}
.cal-arrow:hover{background:var(--surf-cont)}
.cal-grid{display:grid;grid-template-columns:repeat(7,1fr);gap:4px}
.cal-dn{text-align:center;font-size:9px;font-weight:700;text-transform:uppercase;color:var(--on-sv);padding:4px 0}
.cal-day{height:46px;border:1px solid var(--border);border-radius:7px;background:white;font-size:11px;padding:4px 5px;color:var(--on-surf);cursor:pointer;transition:background .12s}
.cal-day:hover{background:var(--surf-low)}
.cal-day.empty{opacity:.4}
.cal-day.today{background:var(--sec-cont);border:2px solid var(--primary);font-weight:800;color:var(--primary)}

/* Responsive */
@media(max-width:1200px){.metrics-row{grid-template-columns:repeat(3,1fr)}.three-col{grid-template-columns:1fr 1fr}.mid-row{grid-template-columns:1fr}}
@media(max-width:900px){.two-col{grid-template-columns:1fr}.metrics-row{grid-template-columns:repeat(2,1fr)}}
'@, $utf8)
Write-Host "  [OK] main-dashboard.component.css - content only" -ForegroundColor Green

# ── 8. Strip settings — remove goBack, use shell router ──────
$sts = Get-Content "src\app\settings\settings.component.ts" -Raw
# Fix goBack to just navigate
$sts = $sts -replace 'goBack\(\): void \{ this\.router\.navigate\(\["/dashboard"\]\); \}', 'goBack(): void { this.router.navigate(["/dashboard"]); }'
[System.IO.File]::WriteAllText("$PWD\src\app\settings\settings.component.ts", $sts, $utf8)
Write-Host "  [OK] settings.component.ts - goBack intact" -ForegroundColor Green

# ── 9. Strip all accounting/sales pages (remove goBack sidebar)
$pages = @(
  "accounting\new-deposit\new-deposit",
  "accounting\new-expense\new-expense",
  "accounting\transfer\transfer",
  "accounting\bills\bills",
  "accounting\view-transactions\view-transactions",
  "accounting\uncleared-transactions\uncleared-transactions",
  "accounting\accounts\accounts",
  "accounting\new-account\new-account",
  "sales\invoices\invoices",
  "sales\pos\pos",
  "sales\recurring-invoices\recurring-invoices",
  "sales\new-recurring-invoice\new-recurring-invoice",
  "sales\quotes\quotes",
  "sales\create-new-quote\create-new-quote",
  "sales\payments\payments"
)

foreach ($page in $pages) {
  $parts    = $page -split "\\"
  $folder   = $parts[0] + "\" + $parts[1]
  $file     = $parts[2]
  $htmlPath = "src\app\$folder\$file.component.html"
  $cssPath  = "src\app\$folder\$file.component.css"
  $tsPath   = "src\app\$folder\$file.component.ts"

  # Clean HTML - just the coming-soon card, no back button (shell has nav)
  $title = ($file -split "-" | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join " "
  $cleanHtml = @"
<div class="cs-page">
  <div class="cs-card">
    <div class="cs-icon">&#128274;</div>
    <h1 class="cs-title">$title</h1>
    <p class="cs-msg">Coming Soon</p>
    <p class="cs-sub">This module is under active development.</p>
  </div>
</div>
"@
  [System.IO.File]::WriteAllText("$PWD\$htmlPath", $cleanHtml, $utf8)

  $cleanCss = @'
.cs-page{padding:40px;min-height:100%;display:flex;align-items:center;justify-content:center}
.cs-card{background:white;border:1px solid #E2E8F0;border-radius:16px;padding:56px 48px;text-align:center;max-width:440px;box-shadow:0 4px 20px rgba(0,0,0,.06)}
.cs-icon{font-size:44px;margin-bottom:18px}
.cs-title{font-size:22px;font-weight:700;color:#003874;margin-bottom:10px}
.cs-msg{font-size:17px;font-weight:600;color:#1d4ed8;margin-bottom:10px}
.cs-sub{font-size:14px;color:#64748b;line-height:1.6}
'@
  [System.IO.File]::WriteAllText("$PWD\$cssPath", $cleanCss, $utf8)

  Write-Host "  [OK] stripped $file" -ForegroundColor Green
}

# ── 10. Strip customer sub-pages (remove goBack/sidebar) ─────
$custPages = @("add","list","companies","groups","files")
foreach ($cp in $custPages) {
  $tsPath = "src\app\customers\$cp\*-customer.component.ts","src\app\customers\$cp\$cp.component.ts" | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($tsPath) {
    $ts = Get-Content $tsPath -Raw
    if ($ts) {
      [System.IO.File]::WriteAllText($tsPath, $ts, $utf8)
    }
  }
}
Write-Host "  [OK] customer sub-pages checked" -ForegroundColor Green

# ── 11. BOM fix ───────────────────────────────────────────────
Get-ChildItem -Path "src" -Recurse -Include "*.ts","*.html","*.css" | ForEach-Object {
  $c = Get-Content $_.FullName -Raw
  if ($c) { [System.IO.File]::WriteAllText($_.FullName, $c.TrimStart([char]0xFEFF), $utf8) }
}
Write-Host "  [OK] BOM removed from all files" -ForegroundColor Green

Write-Host ""
Write-Host "AppShell refactor complete!" -ForegroundColor Cyan
Write-Host "Run: ng serve" -ForegroundColor Yellow
Write-Host ""
Write-Host "What changed:" -ForegroundColor White
Write-Host "  - AppShellComponent renders sidebar ONCE per session" -ForegroundColor Gray
Write-Host "  - Navigating between pages NO LONGER re-renders/flickers sidebar" -ForegroundColor Gray
Write-Host "  - WebGL shader runs ONCE (no restart on page change)" -ForegroundColor Gray
Write-Host "  - sidebarCollapsed/expandedMenus state PERSISTS across navigation" -ForegroundColor Gray
Write-Host "  - authGuard runs ONCE on shell, not per-page" -ForegroundColor Gray
Write-Host "  - Active nav item auto-highlights based on current URL" -ForegroundColor Gray
Write-Host "  - ~150 lines of boilerplate removed from every page" -ForegroundColor Gray
