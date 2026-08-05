# BizMotion Frontend v3 - Full Scope-Driven RBAC Setup
# Run from D:\rbca-frontend
# Overwrites all previous frontend files with scope-aware version

$base = "src\app"
$utf8 = [System.Text.UTF8Encoding]::new($false)

Write-Host "Building scope-driven RBAC frontend..." -ForegroundColor Cyan

# ── 1. auth.model.ts ─────────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\$base\models\auth.model.ts", @'
export interface LoginRequest {
  username: string;
  password: string;
}
export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
  confirmPassword: string;
}
export interface AuthResponse {
  accessToken:  string;
  refreshToken: string;
  role:         string;
  scopes:       string[];
  username:     string;
  userId:       number;
}
'@, $utf8)
Write-Host "  [OK] auth.model.ts" -ForegroundColor Green

# ── 2. auth.service.ts ────────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\$base\services\auth.service.ts", @'
import { Injectable } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { Observable } from "rxjs";
import { tap } from "rxjs/operators";
import { LoginRequest, RegisterRequest, AuthResponse } from "../models/auth.model";

@Injectable({ providedIn: "root" })
export class AuthService {

  private base = "http://localhost:8080/api/auth";

  constructor(private http: HttpClient) {}

  register(data: RegisterRequest): Observable<string> {
    return this.http.post<string>(`${this.base}/register`, data, { responseType: "text" as "json" });
  }

  login(data: LoginRequest): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.base}/login`, data).pipe(
      tap(res => this.saveSession(res))
    );
  }

  refresh(refreshToken: string): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.base}/refresh`, { refreshToken }).pipe(
      tap(res => this.saveSession(res))
    );
  }

  private saveSession(res: AuthResponse): void {
    sessionStorage.setItem("accessToken",  res.accessToken);
    sessionStorage.setItem("refreshToken", res.refreshToken);
    sessionStorage.setItem("role",         res.role);
    sessionStorage.setItem("username",     res.username);
    sessionStorage.setItem("userId",       String(res.userId));
    sessionStorage.setItem("scopes",       JSON.stringify(res.scopes));
  }

  saveTokens(res: AuthResponse): void { this.saveSession(res); }

  getAccessToken():  string | null { return sessionStorage.getItem("accessToken"); }
  getRefreshToken(): string | null { return sessionStorage.getItem("refreshToken"); }
  getRole():         string | null { return sessionStorage.getItem("role"); }
  getUsername():     string | null { return sessionStorage.getItem("username"); }
  getUserId():       string | null { return sessionStorage.getItem("userId"); }

  getScopes(): string[] {
    const s = sessionStorage.getItem("scopes");
    return s ? JSON.parse(s) : [];
  }

  isLoggedIn(): boolean { return !!this.getAccessToken(); }

  logout(): void { sessionStorage.clear(); }
}
'@, $utf8)
Write-Host "  [OK] auth.service.ts" -ForegroundColor Green

# ── 3. scope.service.ts  (the hasScope utility) ───────────────
New-Item -ItemType Directory -Force -Path "$base\services" | Out-Null
[System.IO.File]::WriteAllText("$PWD\$base\services\scope.service.ts", @'
import { Injectable } from "@angular/core";
import { AuthService } from "./auth.service";

/**
 * Centralised scope (permission) checker.
 * Use this everywhere — never check sessionStorage directly.
 *
 * Usage:
 *   scopeService.hasScope("VIEW_USER")
 *   scopeService.hasAnyScope(["CREATE_INVOICE","EDIT_INVOICE"])
 *   scopeService.hasAllScopes(["VIEW_USER","ASSIGN_ROLE"])
 */
@Injectable({ providedIn: "root" })
export class ScopeService {

  constructor(private auth: AuthService) {}

  /** True if the user has this exact scope */
  hasScope(scope: string): boolean {
    return this.auth.getScopes().includes(scope);
  }

  /** True if the user has at least one of the given scopes */
  hasAnyScope(scopes: string[]): boolean {
    const mine = this.auth.getScopes();
    return scopes.some(s => mine.includes(s));
  }

  /** True if the user has ALL of the given scopes */
  hasAllScopes(scopes: string[]): boolean {
    const mine = this.auth.getScopes();
    return scopes.every(s => mine.includes(s));
  }

  /** True if user is SUPER_ADMIN (bypass all checks) */
  isSuperAdmin(): boolean {
    return this.auth.getRole() === "SUPER_ADMIN";
  }

  /** True if user has a scope OR is SUPER_ADMIN */
  can(scope: string): boolean {
    return this.isSuperAdmin() || this.hasScope(scope);
  }
}
'@, $utf8)
Write-Host "  [OK] scope.service.ts" -ForegroundColor Green

# ── 4. jwt.interceptor.ts ─────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\$base\interceptors\jwt.interceptor.ts", @'
import { HttpInterceptorFn, HttpErrorResponse } from "@angular/common/http";
import { inject } from "@angular/core";
import { catchError, switchMap, throwError } from "rxjs";
import { AuthService } from "../services/auth.service";
import { Router } from "@angular/router";

export const jwtInterceptor: HttpInterceptorFn = (req, next) => {
  const auth   = inject(AuthService);
  const router = inject(Router);
  const token  = auth.getAccessToken();

  const authReq = token
    ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
    : req;

  return next(authReq).pipe(
    catchError((err: HttpErrorResponse) => {
      if (err.status === 401) {
        const rt = auth.getRefreshToken();
        if (rt) {
          return auth.refresh(rt).pipe(
            switchMap(res => {
              const retry = req.clone({ setHeaders: { Authorization: `Bearer ${res.accessToken}` } });
              return next(retry);
            }),
            catchError(() => { auth.logout(); router.navigate(["/login"]); return throwError(() => err); })
          );
        }
        auth.logout();
        router.navigate(["/login"]);
      }
      return throwError(() => err);
    })
  );
};
'@, $utf8)
Write-Host "  [OK] jwt.interceptor.ts" -ForegroundColor Green

# ── 5. auth.guard.ts ──────────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\$base\guards\auth.guard.ts", @'
import { inject } from "@angular/core";
import { CanActivateFn, Router } from "@angular/router";
import { AuthService } from "../services/auth.service";

export const authGuard: CanActivateFn = () => {
  const auth   = inject(AuthService);
  const router = inject(Router);
  if (auth.isLoggedIn()) return true;
  router.navigate(["/login"]);
  return false;
};
'@, $utf8)
Write-Host "  [OK] auth.guard.ts" -ForegroundColor Green

# ── 6. scope.guard.ts (replaces role.guard — checks actual scope) ──
[System.IO.File]::WriteAllText("$PWD\$base\guards\scope.guard.ts", @'
import { inject } from "@angular/core";
import { CanActivateFn, Router, ActivatedRouteSnapshot } from "@angular/router";
import { ScopeService } from "../services/scope.service";

/**
 * Scope-based route guard.
 * Add to route: canActivate: [authGuard, scopeGuard]
 * Route data:   data: { scopes: ["MANAGE_SETTINGS"] }
 *
 * SUPER_ADMIN bypasses all scope checks automatically.
 */
export const scopeGuard: CanActivateFn = (route: ActivatedRouteSnapshot) => {
  const scopeService = inject(ScopeService);
  const router       = inject(Router);

  const required: string[] = route.data["scopes"] || [];

  if (required.length === 0) return true;
  if (scopeService.isSuperAdmin()) return true;
  if (scopeService.hasAnyScope(required)) return true;

  router.navigate(["/unauthorized"]);
  return false;
};
'@, $utf8)
Write-Host "  [OK] scope.guard.ts" -ForegroundColor Green

# ── 7. role.guard.ts (keep for backwards compat) ─────────────
[System.IO.File]::WriteAllText("$PWD\$base\guards\role.guard.ts", @'
import { inject } from "@angular/core";
import { CanActivateFn, Router, ActivatedRouteSnapshot } from "@angular/router";
import { AuthService } from "../services/auth.service";

export const roleGuard: CanActivateFn = (route: ActivatedRouteSnapshot) => {
  const auth   = inject(AuthService);
  const router = inject(Router);
  const roles: string[] = route.data["roles"] || [];
  const userRole = auth.getRole();
  if (userRole && roles.includes(userRole)) return true;
  router.navigate(["/dashboard"]);
  return false;
};
'@, $utf8)
Write-Host "  [OK] role.guard.ts" -ForegroundColor Green

# ── 8. app.routes.ts ──────────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\$base\app.routes.ts", @'
import { Routes } from "@angular/router";
import { authGuard } from "./guards/auth.guard";
import { roleGuard }  from "./guards/role.guard";
import { scopeGuard } from "./guards/scope.guard";

export const routes: Routes = [
  { path: "", redirectTo: "login", pathMatch: "full" },
  {
    path: "login",
    loadComponent: () => import("./auth/login/login.component").then(m => m.LoginComponent)
  },
  {
    path: "register",
    loadComponent: () => import("./auth/register/register.component").then(m => m.RegisterComponent)
  },
  {
    path: "admin",
    loadComponent: () => import("./dashboard/admin/admin-dashboard.component").then(m => m.AdminDashboardComponent),
    canActivate: [authGuard, roleGuard],
    data: { roles: ["SUPER_ADMIN","ADMIN"] }
  },
  {
    path: "settings",
    loadComponent: () => import("./settings/settings.component").then(m => m.SettingsComponent),
    canActivate: [authGuard, scopeGuard],
    data: { scopes: ["MANAGE_SETTINGS"] }
  },
  {
    path: "dashboard",
    loadComponent: () => import("./dashboard/user/user-dashboard.component").then(m => m.UserDashboardComponent),
    canActivate: [authGuard]
  },
  {
    path: "unauthorized",
    loadComponent: () => import("./unauthorized/unauthorized.component").then(m => m.UnauthorizedComponent)
  },
  { path: "**", redirectTo: "login" }
];
'@, $utf8)
Write-Host "  [OK] app.routes.ts" -ForegroundColor Green

# ── 9. app.config.ts ──────────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\$base\app.config.ts", @'
import { ApplicationConfig } from "@angular/core";
import { provideRouter } from "@angular/router";
import { provideHttpClient, withInterceptors } from "@angular/common/http";
import { routes } from "./app.routes";
import { jwtInterceptor } from "./interceptors/jwt.interceptor";

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(withInterceptors([jwtInterceptor]))
  ]
};
'@, $utf8)
Write-Host "  [OK] app.config.ts" -ForegroundColor Green

# ── 10. app.component.ts ──────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\$base\app.component.ts", @'
import { Component } from "@angular/core";
import { RouterOutlet } from "@angular/router";
@Component({ selector: "app-root", standalone: true, imports: [RouterOutlet], template: "<router-outlet />" })
export class AppComponent {}
'@, $utf8)
[System.IO.File]::WriteAllText("$PWD\$base\app.component.html", "<router-outlet />", $utf8)
Write-Host "  [OK] app.component.ts / app.component.html" -ForegroundColor Green

# ── 11. NAV CONFIG — scope-driven sidebar items ───────────────
[System.IO.File]::WriteAllText("$PWD\$base\models\nav.model.ts", @'
export interface NavItem {
  label:       string;
  icon:        string;
  route:       string;
  /** User must have at least ONE of these scopes to see this item.
   *  Empty array = always visible (e.g. Dashboard for all logged-in). */
  scopes:      string[];
}

/**
 * Master navigation config.
 * Add new menu items here — never hardcode them in the dashboard component.
 * The sidebar filters this list using ScopeService.hasAnyScope().
 */
export const NAV_ITEMS: NavItem[] = [
  { label: "Dashboard",       icon: "⊞",  route: "/admin",    scopes: [] },
  { label: "User Management", icon: "👤", route: "/settings", scopes: ["VIEW_USER","CREATE_USER","EDIT_USER","DELETE_USER","ASSIGN_ROLE"] },
  { label: "Customers",       icon: "🏢", route: "#",         scopes: ["VIEW_CUSTOMER","CREATE_CUSTOMER","EDIT_CUSTOMER","DELETE_CUSTOMER"] },
  { label: "Accounting",      icon: "⚖",  route: "#",         scopes: ["VIEW_LEDGER","POST_JOURNAL_ENTRY","CLOSE_PERIOD"] },
  { label: "Invoices",        icon: "🧾", route: "#",         scopes: ["VIEW_INVOICE","CREATE_INVOICE","EDIT_INVOICE","APPROVE_INVOICE"] },
  { label: "Payments",        icon: "💳", route: "#",         scopes: ["VIEW_PAYMENT","CREATE_PAYMENT","PROCESS_PAYMENT","REFUND_PAYMENT"] },
  { label: "Reports",         icon: "📊", route: "#",         scopes: ["VIEW_REPORT","EXPORT_REPORT","GENERATE_REPORT"] },
  { label: "Sales",           icon: "📈", route: "#",         scopes: ["VIEW_INVOICE","APPROVE_INVOICE"] },
  { label: "HRM",             icon: "👥", route: "#",         scopes: [] },
  { label: "Documents",       icon: "📁", route: "#",         scopes: [] },
  { label: "Tasks",           icon: "✅", route: "#",         scopes: [] },
  { label: "Calendar",        icon: "📅", route: "#",         scopes: [] },
  { label: "Audit Logs",      icon: "📋", route: "#",         scopes: ["VIEW_AUDIT_LOG"] },
  { label: "Settings",        icon: "⚙",  route: "/settings", scopes: ["MANAGE_SETTINGS"] },
];
'@, $utf8)
Write-Host "  [OK] nav.model.ts" -ForegroundColor Green

# ── 12. unauthorized.component.ts ─────────────────────────────
New-Item -ItemType Directory -Force -Path "$base\unauthorized" | Out-Null
[System.IO.File]::WriteAllText("$PWD\$base\unauthorized\unauthorized.component.ts", @'
import { Component } from "@angular/core";
import { CommonModule } from "@angular/common";
import { Router } from "@angular/router";
@Component({
  selector: "app-unauthorized",
  standalone: true,
  imports: [CommonModule],
  template: `
    <div style="min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;font-family:Inter,sans-serif;background:#f9f9ff">
      <div style="font-size:48px;margin-bottom:16px">🔒</div>
      <h1 style="color:#003874;font-size:24px;font-weight:700;margin-bottom:8px">Access Denied</h1>
      <p style="color:#424751;font-size:14px;margin-bottom:24px">You do not have permission to access this page.</p>
      <button (click)="go()" style="padding:10px 24px;background:#003874;color:white;border:none;border-radius:8px;font-size:14px;font-weight:700;cursor:pointer">
        Go to Dashboard
      </button>
    </div>
  `
})
export class UnauthorizedComponent {
  constructor(private router: Router) {}
  go(): void { this.router.navigate(["/admin"]); }
}
'@, $utf8)
Write-Host "  [OK] unauthorized.component.ts" -ForegroundColor Green

# ── 13. admin-dashboard.component.ts (scope-driven sidebar) ───
[System.IO.File]::WriteAllText("$PWD\$base\dashboard\admin\admin-dashboard.component.ts", @'
import { Component, OnInit, AfterViewInit, OnDestroy } from "@angular/core";
import { CommonModule } from "@angular/common";
import { Router, RouterLink } from "@angular/router";
import { AuthService }  from "../../services/auth.service";
import { ScopeService } from "../../services/scope.service";
import { NAV_ITEMS, NavItem } from "../../models/nav.model";

@Component({
  selector: "app-admin-dashboard",
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: "./admin-dashboard.component.html",
  styleUrls: ["./admin-dashboard.component.css"]
})
export class AdminDashboardComponent implements OnInit, AfterViewInit, OnDestroy {

  role          = "";
  username      = "";
  userInitials  = "";
  sidebarCollapsed = false;

  /** Only nav items the current user has scope for */
  visibleNavItems: NavItem[] = [];

  /** Scope-driven dashboard cards */
  canViewUsers     = false;
  canViewInvoices  = false;
  canViewPayments  = false;
  canViewReports   = false;
  canViewLedger    = false;
  canViewCustomers = false;
  canManageSettings = false;

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
    { name: "BRAC Bank Limited",   amount: "\u09f3 1.2M" },
    { name: "Connect Informatics", amount: "\u09f3 450K" },
    { name: "Petty cash",          amount: "\u09f3 12K" },
    { name: "Payoneer Account",    amount: "\u09f3 85K" },
  ];

  dayNames = ["SUN","MON","TUE","WED","THU","FRI","SAT"];
  calDays  = Array.from({ length: 20 }, (_, i) => i + 1);

  private animationFrameId: number | null = null;

  constructor(
    private auth:   AuthService,
    private scope:  ScopeService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.role         = this.auth.getRole()     || "";
    this.username     = this.auth.getUsername() || "User";
    this.userInitials = this.getInitials(this.username);

    // Build visible nav from scope config
    this.visibleNavItems = NAV_ITEMS.filter(item =>
      item.scopes.length === 0 || this.scope.hasAnyScope(item.scopes) || this.scope.isSuperAdmin()
    );

    // Set dashboard card visibility from scopes
    this.canViewUsers      = this.scope.can("VIEW_USER");
    this.canViewInvoices   = this.scope.can("VIEW_INVOICE");
    this.canViewPayments   = this.scope.can("VIEW_PAYMENT");
    this.canViewReports    = this.scope.can("VIEW_REPORT");
    this.canViewLedger     = this.scope.can("VIEW_LEDGER");
    this.canViewCustomers  = this.scope.can("VIEW_CUSTOMER");
    this.canManageSettings = this.scope.can("MANAGE_SETTINGS");
  }

  ngAfterViewInit(): void { this.initShader(); }

  ngOnDestroy(): void {
    if (this.animationFrameId !== null) cancelAnimationFrame(this.animationFrameId);
  }

  logout():          void { this.auth.logout(); this.router.navigate(["/login"]); }
  toggleSidebar():   void { this.sidebarCollapsed = !this.sidebarCollapsed; }
  goToSettings():    void { this.router.navigate(["/settings"]); }
  navigate(route: string): void { if (route !== "#") this.router.navigate([route]); }

  getInitials(name: string): string {
    return name.split(" ").map(w => w.charAt(0).toUpperCase()).slice(0,2).join("");
  }

  private initShader(): void {
    const canvas = document.getElementById("shader-canvas") as HTMLCanvasElement;
    if (!canvas) return;
    const sync = () => {
      const w = canvas.clientWidth || window.innerWidth;
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
      vec3 c=mix(vec3(.976,.976,1.),vec3(.012,.22,.455),uv.y*.4);
      c=mix(c,vec3(.969,.580,.114),f*g*.18);
      gl_FragColor=vec4(c*(1.-length(uv-.5)*.5),1.);}`;
    const mk = (type: number, src: string) => {
      const s = gl.createShader(type)!;
      gl.shaderSource(s,src); gl.compileShader(s); return s;
    };
    const p = gl.createProgram()!;
    gl.attachShader(p,mk(gl.VERTEX_SHADER,vs));
    gl.attachShader(p,mk(gl.FRAGMENT_SHADER,fs));
    gl.linkProgram(p); gl.useProgram(p);
    const buf = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER,buf);
    gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([-1,-1,1,-1,-1,1,1,1]),gl.STATIC_DRAW);
    const al = gl.getAttribLocation(p,"a");
    gl.enableVertexAttribArray(al); gl.vertexAttribPointer(al,2,gl.FLOAT,false,0,0);
    const tl = gl.getUniformLocation(p,"t");
    const rl = gl.getUniformLocation(p,"r");
    const draw = (ms: number) => {
      sync(); gl.viewport(0,0,canvas.width,canvas.height);
      if(tl) gl.uniform1f(tl,ms*.001);
      if(rl) gl.uniform2f(rl,canvas.width,canvas.height);
      gl.drawArrays(gl.TRIANGLE_STRIP,0,4);
      this.animationFrameId = requestAnimationFrame(draw);
    };
    draw(0);
  }
}
'@, $utf8)
Write-Host "  [OK] admin-dashboard.component.ts (scope-driven)" -ForegroundColor Green

# ── 14. admin-dashboard.component.html ───────────────────────
[System.IO.File]::WriteAllText("$PWD\$base\dashboard\admin\admin-dashboard.component.html", @'
<div class="dashboard-wrapper">
  <canvas id="shader-canvas" class="shader-bg"></canvas>

  <!-- Hamburger -->
  <button class="sidebar-toggle" (click)="toggleSidebar()">
    <span class="ham-line"></span><span class="ham-line"></span><span class="ham-line"></span>
  </button>

  <!-- Sidebar -->
  <aside class="sidebar" [class.collapsed]="sidebarCollapsed">
    <div class="sidebar-logo"><h1 class="logo-text">BIZMOTION</h1></div>

    <div class="sidebar-profile">
      <div class="profile-card">
        <div class="profile-avatar">{{ userInitials }}</div>
        <div class="profile-info">
          <p class="profile-name">{{ username }}</p>
          <p class="profile-role">{{ role }}</p>
        </div>
      </div>
      <button class="add-lead-btn"><span>+</span> Add New Lead</button>
    </div>

    <!-- DYNAMIC NAV — only scopes the user has -->
    <nav class="sidebar-nav">
      <a class="nav-item" *ngFor="let item of visibleNavItems"
         [class.active]="item.route === '/admin' && true"
         (click)="navigate(item.route)">
        <span class="nav-icon">{{ item.icon }}</span>
        <span>{{ item.label }}</span>
      </a>
    </nav>

    <div class="sidebar-footer">
      <a class="nav-item logout" (click)="logout()">
        <span class="nav-icon">⎋</span><span>Logout</span>
      </a>
    </div>
  </aside>

  <!-- Main -->
  <main class="main-content" [class.expanded]="sidebarCollapsed">
    <header class="top-header" [class.expanded]="sidebarCollapsed">
      <div class="header-left">
        <div class="search-wrapper">
          <span class="search-icon">🔍</span>
          <input type="text" class="search-input" placeholder="Global Search..." />
        </div>
        <nav class="header-nav">
          <a class="hnav-item active">Overview</a>
          <a class="hnav-item">Reports</a>
          <a class="hnav-item">Activity</a>
        </nav>
      </div>
      <div class="header-right">
        <button class="icon-btn">🔔</button>
        <div class="divider-v"></div>
        <button class="import-btn" *ngIf="canViewReports">Export</button>
        <button class="primary-btn" *ngIf="canViewCustomers">Add Customer</button>
        <button class="primary-btn" *ngIf="canManageSettings" (click)="goToSettings()">Settings</button>
      </div>
    </header>

    <div class="dashboard-body">

      <!-- Metrics Row -->
      <div class="metrics-grid">
        <div class="metric-card">
          <span class="metric-icon">💳</span>
          <p class="metric-label">TOTAL INCOME</p>
          <p class="metric-value">৳ 12.4M</p>
        </div>
        <div class="metric-card">
          <span class="metric-icon">📤</span>
          <p class="metric-label">TOTAL EXPENSE</p>
          <p class="metric-value">৳ 8.2M</p>
        </div>
        <div class="metric-card border-green">
          <p class="metric-label">INCOME TODAY</p>
          <p class="metric-value">৳ 45,000</p>
        </div>
        <div class="metric-card border-red">
          <p class="metric-label">EXPENSE TODAY</p>
          <p class="metric-value">৳ 12,500</p>
        </div>
        <div class="metric-card">
          <p class="metric-label">INCOME THIS MONTH</p>
          <p class="metric-value">৳ 840,000</p>
        </div>
        <div class="metric-card">
          <p class="metric-label">EXPENSE THIS MONTH</p>
          <p class="metric-value">৳ 320,000</p>
        </div>
      </div>

      <!-- Summary + Trend -->
      <div class="section-row">
        <div class="summary-col">
          <div class="summary-card blue-tint" *ngIf="canViewUsers">
            <div class="summary-top"><span class="summary-val">47</span><span class="summary-icon">👤</span></div>
            <p class="summary-label">CUSTOMERS</p>
          </div>
          <div class="summary-card">
            <div class="summary-top"><span class="summary-val">1</span><span class="summary-icon">🏢</span></div>
            <p class="summary-label">COMPANIES</p>
          </div>
          <div class="summary-card">
            <p class="summary-val red-text">-৳ 11,395,628</p>
            <p class="summary-label">NET WORTH</p>
            <div class="net-worth-foot"><span>Goal: 350,000</span><span class="red-text">-3255%</span></div>
          </div>
        </div>
        <div class="trend-card glass-card">
          <div class="trend-header">
            <h3 class="card-title">Financial Performance Trend</h3>
            <div class="legend-row">
              <div class="legend-item"><div class="legend-dot navy"></div><span>Income</span></div>
              <div class="legend-item"><div class="legend-dot orange"></div><span>Expense</span></div>
            </div>
          </div>
          <div class="chart-area">
            <svg class="trend-svg" viewBox="0 0 1000 200" preserveAspectRatio="none">
              <path d="M0,150 Q100,50 200,100 T400,120 T600,80 T800,40 T1000,100 L1000,200 L0,200 Z" fill="rgba(0,56,116,0.1)"/>
              <path d="M0,150 Q100,50 200,100 T400,120 T600,80 T800,40 T1000,100" fill="none" stroke="#003874" stroke-width="3"/>
              <path d="M0,180 Q100,140 200,160 T400,150 T600,170 T800,130 T1000,150" fill="none" stroke="#F59E0B" stroke-dasharray="4" stroke-width="2"/>
            </svg>
            <div class="chart-labels">
              <span>JUL 2025</span><span>SEP</span><span>NOV</span><span>JAN 2026</span><span>MAR</span><span>MAY</span><span>JUN 2026</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Scope-gated tables -->
      <div class="two-col-row">
        <div class="glass-card table-card" *ngIf="canViewCustomers">
          <div class="table-header"><h3 class="card-title">Recent Clients</h3><span class="more-btn">···</span></div>
          <table class="data-table">
            <thead><tr><th>IMAGE</th><th>NAME</th><th class="text-right">CREATED</th></tr></thead>
            <tbody>
              <tr><td><div class="avatar blue-av">IM</div></td><td class="font-semi">Integrated Marketing Service Ltd.</td><td class="text-right muted">07/04/2026</td></tr>
              <tr><td><div class="avatar purple-av">BI</div></td><td class="font-semi">Believe Int. Pvt. Ltd.</td><td class="text-right muted">06/01/2026</td></tr>
            </tbody>
          </table>
        </div>
        <div class="glass-card table-card" *ngIf="canViewInvoices">
          <div class="table-header">
            <h3 class="card-title">Recent Invoices</h3>
            <div class="invoice-meta"><div class="progress-bar-wrap"><div class="progress-fill" style="width:31%"></div></div><span class="meta-text">31% Paid</span></div>
          </div>
          <table class="data-table">
            <thead><tr><th>#</th><th>ACCOUNT</th><th class="text-right">STATUS</th></tr></thead>
            <tbody>
              <tr><td class="inv-id">INV-Jun090652026_Linnex</td><td>Linnex Electronics</td><td class="text-right"><span class="badge unpaid">Unpaid</span></td></tr>
              <tr><td class="inv-id">INV-Jun090652026_Somatec</td><td>SOMATEC PHARMA</td><td class="text-right"><span class="badge unpaid">Unpaid</span></td></tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Expense, Category, Balances -->
      <div class="three-col-row">
        <div class="glass-card">
          <div class="table-header"><h3 class="card-title">Latest Expense</h3></div>
          <div class="expense-list">
            <div class="expense-item" *ngFor="let item of latestExpenses">
              <div><p class="exp-date">{{ item.date }}</p><p class="exp-desc">{{ item.desc }}</p></div>
              <p class="exp-amount">৳ {{ item.amount }}</p>
            </div>
          </div>
        </div>
        <div class="glass-card">
          <h3 class="card-title" style="margin-bottom:16px">Expense by Category</h3>
          <div class="category-list">
            <div class="category-item" *ngFor="let cat of expenseCategories">
              <div class="cat-header"><span class="cat-name">{{ cat.name }}</span><span class="cat-amount">{{ cat.amount }}</span></div>
              <div class="cat-bar-bg"><div class="cat-bar-fill" [style.width]="cat.percent" [style.background]="cat.color"></div></div>
            </div>
          </div>
        </div>
        <div class="glass-card">
          <h3 class="card-title" style="margin-bottom:16px">Account Balances</h3>
          <div class="balance-list">
            <div class="balance-item" *ngFor="let acc of accountBalances">
              <span class="acc-name">{{ acc.name }}</span><span class="acc-amount">{{ acc.amount }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Sales + Calendar -->
      <div class="two-col-row">
        <div class="glass-card sales-card" *ngIf="canViewReports">
          <h3 class="card-title">Sales Distribution</h3>
          <div class="donut-wrapper">
            <svg class="donut-svg" viewBox="0 0 100 100">
              <circle cx="50" cy="50" r="40" fill="transparent" stroke="rgba(255,255,255,0.2)" stroke-width="8"/>
              <circle cx="50" cy="50" r="40" fill="transparent" stroke="#003874" stroke-width="8" stroke-dasharray="251.2" stroke-dashoffset="60" stroke-linecap="round" transform="rotate(-90 50 50)"/>
            </svg>
            <div class="donut-center"><span class="donut-label">Total Sales</span><span class="donut-value">1.4k</span></div>
          </div>
          <div class="sales-stats">
            <div class="stat-box"><p class="stat-label">COUNT</p><p class="stat-val">842</p></div>
            <div class="stat-box"><p class="stat-label">VOLUME</p><p class="stat-val">৳ 4.2M</p></div>
          </div>
        </div>
        <div class="glass-card calendar-card">
          <div class="cal-header"><h3 class="card-title">JUNE 2026</h3>
            <div class="cal-nav"><button class="cal-btn">Today</button><button class="cal-nav-btn">‹</button><button class="cal-nav-btn">›</button></div>
          </div>
          <div class="cal-grid">
            <div class="cal-day-name" *ngFor="let d of dayNames">{{ d }}</div>
            <div class="cal-day empty">31</div>
            <div class="cal-day" *ngFor="let d of calDays" [class.today]="d===14">{{ d }}</div>
          </div>
        </div>
      </div>

    </div>
  </main>
</div>
'@, $utf8)
Write-Host "  [OK] admin-dashboard.component.html" -ForegroundColor Green

# ── 15. user-dashboard.component.ts ──────────────────────────
[System.IO.File]::WriteAllText("$PWD\$base\dashboard\user\user-dashboard.component.ts", @'
import { Component, OnInit } from "@angular/core";
import { CommonModule } from "@angular/common";
import { AuthService }  from "../../services/auth.service";
import { ScopeService } from "../../services/scope.service";
import { Router }       from "@angular/router";
import { NAV_ITEMS, NavItem } from "../../models/nav.model";

@Component({
  selector: "app-user-dashboard",
  standalone: true,
  imports: [CommonModule],
  template: `
    <div style="padding:40px;font-family:Inter,Arial,sans-serif;min-height:100vh;background:#f9f9ff">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:32px">
        <div>
          <h1 style="color:#003874;margin:0">Dashboard</h1>
          <p style="color:#64748b;margin:4px 0 0;font-size:14px">Welcome, {{ username }} ({{ role }})</p>
        </div>
        <button (click)="logout()" style="padding:10px 20px;background:#ef4444;color:white;border:none;border-radius:8px;cursor:pointer;font-size:14px;font-weight:600">Logout</button>
      </div>

      <p style="font-size:13px;color:#424751;margin-bottom:20px">Your accessible modules based on your current scopes:</p>

      <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:16px">
        <div *ngFor="let item of visibleNavItems"
             style="background:white;border:1px solid #e2e8f0;border-radius:12px;padding:20px;text-align:center;cursor:pointer;transition:box-shadow .2s"
             (click)="go(item.route)">
          <div style="font-size:28px;margin-bottom:8px">{{ item.icon }}</div>
          <p style="font-size:13px;font-weight:600;color:#003874;margin:0">{{ item.label }}</p>
        </div>
      </div>

      <div *ngIf="visibleNavItems.length === 0" style="text-align:center;padding:40px;color:#424751">
        No modules available. Contact your administrator.
      </div>
    </div>
  `
})
export class UserDashboardComponent implements OnInit {
  username = "";
  role     = "";
  visibleNavItems: NavItem[] = [];

  constructor(private auth: AuthService, private scope: ScopeService, private router: Router) {}

  ngOnInit(): void {
    this.username = this.auth.getUsername() || "";
    this.role     = this.auth.getRole()     || "";
    this.visibleNavItems = NAV_ITEMS.filter(item =>
      item.scopes.length === 0 || this.scope.hasAnyScope(item.scopes) || this.scope.isSuperAdmin()
    );
  }

  go(route: string): void { if (route !== "#") this.router.navigate([route]); }
  logout(): void { this.auth.logout(); this.router.navigate(["/login"]); }
}
'@, $utf8)
Write-Host "  [OK] user-dashboard.component.ts" -ForegroundColor Green

# ── 16. login.component.ts ────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\$base\auth\login\login.component.ts", @'
import { Component } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from "@angular/forms";
import { Router, RouterLink } from "@angular/router";
import { AuthService } from "../../services/auth.service";

@Component({
  selector: "app-login",
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: "./login.component.html",
  styleUrls: ["./login.component.css"]
})
export class LoginComponent {
  loginForm:   FormGroup;
  loading      = false;
  serverError  = "";
  showPassword = false;

  constructor(private fb: FormBuilder, private auth: AuthService, private router: Router) {
    if (this.auth.isLoggedIn()) this.redirect();
    this.loginForm = this.fb.group({
      username:   ["", Validators.required],
      password:   ["", Validators.required],
      rememberMe: [false]
    });
  }

  get f() { return this.loginForm.controls; }
  togglePasswordVisibility(): void { this.showPassword = !this.showPassword; }

  onLogin(): void {
    if (this.loginForm.invalid) return;
    this.loading = true; this.serverError = "";
    this.auth.login(this.loginForm.value).subscribe({
      next:  () => { this.redirect(); },
      error: err => { this.serverError = err?.error?.error || "Invalid username or password"; this.loading = false; }
    });
  }

  private redirect(): void {
    const role = this.auth.getRole();
    if (role === "SUPER_ADMIN" || role === "ADMIN") this.router.navigate(["/admin"]);
    else this.router.navigate(["/dashboard"]);
  }
}
'@, $utf8)
Write-Host "  [OK] login.component.ts" -ForegroundColor Green

# ── 17. register.component.ts ────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\$base\auth\register\register.component.ts", @'
import { Component } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule, AbstractControl, ValidationErrors } from "@angular/forms";
import { Router, RouterLink } from "@angular/router";
import { AuthService } from "../../services/auth.service";

function passwordMatch(form: AbstractControl): ValidationErrors | null {
  return form.get("password")?.value === form.get("confirmPassword")?.value ? null : { passwordMismatch: true };
}

@Component({
  selector: "app-register",
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: "./register.component.html",
  styleUrls: ["./register.component.css"]
})
export class RegisterComponent {
  registerForm: FormGroup;
  loading     = false;
  serverError = "";
  successMsg  = "";

  constructor(private fb: FormBuilder, private auth: AuthService, private router: Router) {
    this.registerForm = this.fb.group({
      username:        ["", [Validators.required, Validators.minLength(4), Validators.pattern(/^\S+$/)]],
      email:           ["", [Validators.required, Validators.email]],
      password:        ["", [Validators.required, Validators.minLength(8), Validators.pattern(/^(?=.*[0-9])(?=.*[!@#$%^&*])/)]],
      confirmPassword: ["", Validators.required]
    }, { validators: passwordMatch });
  }

  get f() { return this.registerForm.controls; }

  onRegister(): void {
    if (this.registerForm.invalid) return;
    this.loading = true; this.serverError = "";
    this.auth.register(this.registerForm.value).subscribe({
      next:  () => { this.successMsg = "Account created! Redirecting to login..."; setTimeout(() => this.router.navigate(["/login"]), 2000); this.loading = false; },
      error: err => { this.serverError = err.status === 409 ? (err.error?.error || "Username or email taken") : "Registration failed."; this.loading = false; }
    });
  }
}
'@, $utf8)
Write-Host "  [OK] register.component.ts" -ForegroundColor Green

# ── 18. styles.css ────────────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\styles.css", @'
@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap");
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: "Inter", "Segoe UI", Arial, sans-serif; background: #f9f9ff; color: #1a1c20; }
'@, $utf8)
Write-Host "  [OK] styles.css" -ForegroundColor Green

# ── 19. Fix BOM on all files ──────────────────────────────────
Get-ChildItem -Path "src" -Recurse -Include "*.ts","*.html","*.css" | ForEach-Object {
  $content = Get-Content $_.FullName -Raw
  if ($content) {
    [System.IO.File]::WriteAllText($_.FullName, $content.TrimStart([char]0xFEFF), $utf8)
  }
}
Write-Host "  [OK] BOM removed from all files" -ForegroundColor Green

Write-Host ""
Write-Host "All files created. Run: ng serve" -ForegroundColor Cyan
