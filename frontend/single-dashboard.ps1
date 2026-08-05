# BizMotion - Single Dynamic Dashboard
# Run from D:\rbca-frontend
# One dashboard for ALL roles - scope-driven

$utf8 = [System.Text.UTF8Encoding]::new($false)
Write-Host "Building single dynamic dashboard..." -ForegroundColor Cyan

# ── 1. Clean up old dashboard folders ────────────────────────
Remove-Item -Recurse -Force "src\app\dashboard\admin"      -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "src\app\dashboard\user"       -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "src\app\dashboard\accountant" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "src\app\dashboard\viewer"     -ErrorAction SilentlyContinue
Write-Host "  [OK] Old dashboard folders removed" -ForegroundColor Green

# ── 2. Create main dashboard folder ──────────────────────────
New-Item -ItemType Directory -Force -Path "src\app\dashboard\main" | Out-Null
New-Item -ItemType Directory -Force -Path "src\app\unauthorized"   | Out-Null
New-Item -ItemType Directory -Force -Path "src\app\services"       | Out-Null
New-Item -ItemType Directory -Force -Path "src\app\guards"         | Out-Null
New-Item -ItemType Directory -Force -Path "src\app\models"         | Out-Null
New-Item -ItemType Directory -Force -Path "src\app\interceptors"   | Out-Null
Write-Host "  [OK] Folders created" -ForegroundColor Green

# ── 3. app.routes.ts ─────────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\app.routes.ts", @'
import { Routes } from "@angular/router";
import { authGuard } from "./guards/auth.guard";

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
    path: "dashboard",
    loadComponent: () => import("./dashboard/main/main-dashboard.component").then(m => m.MainDashboardComponent),
    canActivate: [authGuard]
  },
  {
    path: "settings",
    loadComponent: () => import("./settings/settings.component").then(m => m.SettingsComponent),
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

# ── 4. app.config.ts ─────────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\app.config.ts", @'
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

# ── 5. app.component.ts ──────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\app.component.ts", @'
import { Component } from "@angular/core";
import { RouterOutlet } from "@angular/router";
@Component({ selector: "app-root", standalone: true, imports: [RouterOutlet], template: "<router-outlet />" })
export class AppComponent {}
'@, $utf8)
[System.IO.File]::WriteAllText("$PWD\src\app\app.component.html", "<router-outlet />", $utf8)
Write-Host "  [OK] app.component" -ForegroundColor Green

# ── 6. auth.model.ts ─────────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\models\auth.model.ts", @'
export interface LoginRequest  { username: string; password: string; }
export interface RegisterRequest { username: string; email: string; password: string; confirmPassword: string; }
export interface AuthResponse  { accessToken: string; refreshToken: string; role: string; scopes: string[]; username: string; userId: number; }
'@, $utf8)
Write-Host "  [OK] auth.model.ts" -ForegroundColor Green

# ── 7. nav.model.ts ──────────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\models\nav.model.ts", @'
export interface NavItem { label: string; icon: string; route: string; scopes: string[]; }

export const NAV_ITEMS: NavItem[] = [
  { label: "Dashboard",  icon: "dashboard", route: "/dashboard", scopes: [] },
  { label: "Customers",  icon: "customers", route: "#",          scopes: ["VIEW_CUSTOMER"] },
  { label: "Accounting", icon: "accounting",route: "#",          scopes: ["VIEW_LEDGER"] },
  { label: "Invoices",   icon: "invoices",  route: "#",          scopes: ["VIEW_INVOICE"] },
  { label: "Payments",   icon: "payments",  route: "#",          scopes: ["VIEW_PAYMENT"] },
  { label: "Reports",    icon: "reports",   route: "#",          scopes: ["VIEW_REPORT"] },
  { label: "Sales",      icon: "sales",     route: "#",          scopes: ["VIEW_INVOICE"] },
  { label: "Support",    icon: "support",   route: "#",          scopes: [] },
  { label: "HRM",        icon: "hrm",       route: "#",          scopes: [] },
  { label: "Documents",  icon: "documents", route: "#",          scopes: [] },
  { label: "Tasks",      icon: "tasks",     route: "#",          scopes: [] },
  { label: "Calendar",   icon: "calendar",  route: "#",          scopes: [] },
  { label: "Audit Logs", icon: "audit",     route: "#",          scopes: ["VIEW_AUDIT_LOG"] },
];
'@, $utf8)
Write-Host "  [OK] nav.model.ts" -ForegroundColor Green

# ── 8. auth.service.ts ───────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\services\auth.service.ts", @'
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
    return this.http.post<AuthResponse>(`${this.base}/login`, data).pipe(tap(r => this.save(r)));
  }

  refresh(rt: string): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.base}/refresh`, { refreshToken: rt }).pipe(tap(r => this.save(r)));
  }

  private save(r: AuthResponse): void {
    sessionStorage.setItem("accessToken",  r.accessToken);
    sessionStorage.setItem("refreshToken", r.refreshToken);
    sessionStorage.setItem("role",         r.role);
    sessionStorage.setItem("username",     r.username);
    sessionStorage.setItem("userId",       String(r.userId));
    sessionStorage.setItem("scopes",       JSON.stringify(r.scopes || []));
  }

  saveTokens(r: AuthResponse): void { this.save(r); }
  getAccessToken():  string | null { return sessionStorage.getItem("accessToken"); }
  getRefreshToken(): string | null { return sessionStorage.getItem("refreshToken"); }
  getRole():         string | null { return sessionStorage.getItem("role"); }
  getUsername():     string | null { return sessionStorage.getItem("username"); }
  getScopes():       string[]      { try { return JSON.parse(sessionStorage.getItem("scopes") || "[]"); } catch { return []; } }
  isLoggedIn():      boolean       { return !!this.getAccessToken(); }
  logout():          void          { sessionStorage.clear(); }
}
'@, $utf8)
Write-Host "  [OK] auth.service.ts" -ForegroundColor Green

# ── 9. scope.service.ts ──────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\services\scope.service.ts", @'
import { Injectable } from "@angular/core";
import { AuthService } from "./auth.service";

@Injectable({ providedIn: "root" })
export class ScopeService {
  constructor(private auth: AuthService) {}

  hasScope(s: string):         boolean { return this.auth.getScopes().includes(s); }
  hasAnyScope(ss: string[]):   boolean { return ss.length === 0 || ss.some(s => this.auth.getScopes().includes(s)); }
  isSuperAdmin(): boolean { return this.auth.getRole() === "SUPER_ADMIN"; }
  isAdmin():      boolean { return this.auth.getRole() === "ADMIN"; }
  isAccountant(): boolean { return this.auth.getRole() === "ACCOUNTANT"; }
  isViewer():     boolean { return this.auth.getRole() === "VIEWER"; }

  can(scope: string):   boolean { return this.isSuperAdmin() || this.hasScope(scope); }
  canCreate():          boolean { return !this.isViewer(); }
  canEdit():            boolean { return !this.isViewer(); }
  canDelete():          boolean { return this.isSuperAdmin() || this.isAdmin(); }
  canManageUsers():     boolean { return this.can("EDIT_USER"); }
  canDeleteUsers():     boolean { return this.can("DELETE_USER"); }
  canSeeUserManagement(): boolean { return this.can("VIEW_USER"); }
  canSeeScopesTab():    boolean { return this.can("MANAGE_SETTINGS"); }
}
'@, $utf8)
Write-Host "  [OK] scope.service.ts" -ForegroundColor Green

# ── 10. jwt.interceptor.ts ────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\interceptors\jwt.interceptor.ts", @'
import { HttpInterceptorFn, HttpErrorResponse } from "@angular/common/http";
import { inject } from "@angular/core";
import { catchError, switchMap, throwError } from "rxjs";
import { AuthService } from "../services/auth.service";
import { Router } from "@angular/router";

export const jwtInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService);
  const router = inject(Router);
  const token = auth.getAccessToken();
  const authReq = token ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }) : req;

  return next(authReq).pipe(
    catchError((err: HttpErrorResponse) => {
      if (err.status === 401) {
        const rt = auth.getRefreshToken();
        if (rt) {
          return auth.refresh(rt).pipe(
            switchMap(res => next(req.clone({ setHeaders: { Authorization: `Bearer ${res.accessToken}` } }))),
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

# ── 11. auth.guard.ts ─────────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\guards\auth.guard.ts", @'
import { inject } from "@angular/core";
import { CanActivateFn, Router } from "@angular/router";
import { AuthService } from "../services/auth.service";

export const authGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  if (auth.isLoggedIn()) return true;
  router.navigate(["/login"]);
  return false;
};
'@, $utf8)
Write-Host "  [OK] auth.guard.ts" -ForegroundColor Green

# ── 12. unauthorized.component.ts ────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\unauthorized\unauthorized.component.ts", @'
import { Component } from "@angular/core";
import { Router } from "@angular/router";
@Component({
  selector: "app-unauthorized", standalone: true, imports: [],
  template: `
    <div style="min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;font-family:Inter,sans-serif;background:#f9f9ff">
      <h1 style="color:#003874;font-size:24px;font-weight:700;margin-bottom:8px">Access Denied</h1>
      <p style="color:#424751;font-size:14px;margin-bottom:24px">You do not have permission to view this page.</p>
      <button (click)="go()" style="padding:10px 24px;background:#003874;color:white;border:none;border-radius:8px;font-size:14px;font-weight:700;cursor:pointer">Go to Dashboard</button>
    </div>
  `
})
export class UnauthorizedComponent { constructor(private r: Router) {} go() { this.r.navigate(["/dashboard"]); } }
'@, $utf8)
Write-Host "  [OK] unauthorized.component.ts" -ForegroundColor Green

# ── 13. login.component.ts ────────────────────────────────────
New-Item -ItemType Directory -Force -Path "src\app\auth\login" | Out-Null
[System.IO.File]::WriteAllText("$PWD\src\app\auth\login\login.component.ts", @'
import { Component } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from "@angular/forms";
import { Router, RouterLink } from "@angular/router";
import { AuthService } from "../../services/auth.service";

@Component({
  selector: "app-login", standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: "./login.component.html",
  styleUrls: ["./login.component.css"]
})
export class LoginComponent {
  loginForm: FormGroup;
  loading = false; serverError = ""; showPassword = false;

  constructor(private fb: FormBuilder, private auth: AuthService, private router: Router) {
    if (this.auth.isLoggedIn()) this.router.navigate(["/dashboard"]);
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
      next: () => { this.router.navigate(["/dashboard"]); },
      error: err => { this.serverError = err?.error?.error || "Invalid username or password"; this.loading = false; }
    });
  }
}
'@, $utf8)
Write-Host "  [OK] login.component.ts - all roles -> /dashboard" -ForegroundColor Green

# ── 14. register.component.ts ─────────────────────────────────
New-Item -ItemType Directory -Force -Path "src\app\auth\register" | Out-Null
[System.IO.File]::WriteAllText("$PWD\src\app\auth\register\register.component.ts", @'
import { Component } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule, AbstractControl, ValidationErrors } from "@angular/forms";
import { Router, RouterLink } from "@angular/router";
import { AuthService } from "../../services/auth.service";

function passwordMatch(form: AbstractControl): ValidationErrors | null {
  return form.get("password")?.value === form.get("confirmPassword")?.value ? null : { passwordMismatch: true };
}

@Component({
  selector: "app-register", standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: "./register.component.html",
  styleUrls: ["./register.component.css"]
})
export class RegisterComponent {
  registerForm: FormGroup;
  loading = false; serverError = ""; successMsg = "";

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
      next: () => { this.successMsg = "Account created! Redirecting..."; setTimeout(() => this.router.navigate(["/login"]), 2000); this.loading = false; },
      error: err => { this.serverError = err.status === 409 ? (err.error?.error || "Username or email taken") : "Registration failed."; this.loading = false; }
    });
  }
}
'@, $utf8)
Write-Host "  [OK] register.component.ts" -ForegroundColor Green

# ── 15. main-dashboard.component.ts ──────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\dashboard\main\main-dashboard.component.ts", @'
import { Component, OnInit, AfterViewInit, OnDestroy } from "@angular/core";
import { CommonModule } from "@angular/common";
import { Router } from "@angular/router";
import { AuthService }  from "../../services/auth.service";
import { ScopeService } from "../../services/scope.service";
import { NAV_ITEMS, NavItem } from "../../models/nav.model";

@Component({
  selector: "app-main-dashboard", standalone: true,
  imports: [CommonModule],
  templateUrl: "./main-dashboard.component.html",
  styleUrls: ["./main-dashboard.component.css"]
})
export class MainDashboardComponent implements OnInit, AfterViewInit, OnDestroy {

  username = ""; userInitials = ""; role = "";
  sidebarCollapsed = false;
  visibleNavItems: NavItem[] = [];

  isSuperAdmin = false; isAdmin = false; isViewer = false; isAccountant = false;
  canViewUsers = false; canViewInvoices = false; canViewPayments = false;
  canViewReports = false; canViewLedger = false; canViewCustomers = false;
  canManageSettings = false; canCreateAny = false; canEditAny = false; canDeleteAny = false;

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

  private animationId: number | null = null;

  constructor(private auth: AuthService, public scope: ScopeService, private router: Router) {}

  ngOnInit(): void {
    this.username     = this.auth.getUsername() || "User";
    this.role         = this.auth.getRole()     || "";
    this.userInitials = this.username.split(" ").map((w: string) => w.charAt(0).toUpperCase()).slice(0,2).join("");

    this.isSuperAdmin = this.scope.isSuperAdmin();
    this.isAdmin      = this.scope.isAdmin();
    this.isAccountant = this.scope.isAccountant();
    this.isViewer     = this.scope.isViewer();

    this.canViewUsers      = this.scope.can("VIEW_USER");
    this.canViewInvoices   = this.scope.can("VIEW_INVOICE");
    this.canViewPayments   = this.scope.can("VIEW_PAYMENT");
    this.canViewReports    = this.scope.can("VIEW_REPORT");
    this.canViewLedger     = this.scope.can("VIEW_LEDGER");
    this.canViewCustomers  = this.scope.can("VIEW_CUSTOMER");
    this.canManageSettings = this.scope.can("MANAGE_SETTINGS");
    this.canCreateAny      = this.scope.canCreate();
    this.canEditAny        = this.scope.canEdit();
    this.canDeleteAny      = this.scope.canDelete();

    this.visibleNavItems = NAV_ITEMS.filter(item =>
      item.scopes.length === 0 || this.scope.hasAnyScope(item.scopes) || this.isSuperAdmin
    );
  }

  ngAfterViewInit(): void { this.initShader(); }
  ngOnDestroy(): void { if (this.animationId !== null) cancelAnimationFrame(this.animationId); }

  toggleSidebar(): void { this.sidebarCollapsed = !this.sidebarCollapsed; }
  goToSettings():  void { this.router.navigate(["/settings"]); }
  logout():        void { this.auth.logout(); this.router.navigate(["/login"]); }
  navigate(route: string): void { if (route && route !== "#") this.router.navigate([route]); }

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
    const mk = (type: number, src: string) => { const s = gl.createShader(type)!; gl.shaderSource(s,src); gl.compileShader(s); return s; };
    const p = gl.createProgram()!;
    gl.attachShader(p, mk(gl.VERTEX_SHADER, vs));
    gl.attachShader(p, mk(gl.FRAGMENT_SHADER, fs));
    gl.linkProgram(p); gl.useProgram(p);
    const buf = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buf);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1,-1,1,-1,-1,1,1,1]), gl.STATIC_DRAW);
    const al = gl.getAttribLocation(p, "a");
    gl.enableVertexAttribArray(al); gl.vertexAttribPointer(al, 2, gl.FLOAT, false, 0, 0);
    const tl = gl.getUniformLocation(p, "t");
    const rl = gl.getUniformLocation(p, "r");
    const draw = (ms: number) => {
      sync(); gl.viewport(0,0,canvas.width,canvas.height);
      if(tl) gl.uniform1f(tl, ms*.001);
      if(rl) gl.uniform2f(rl, canvas.width, canvas.height);
      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
      this.animationId = requestAnimationFrame(draw);
    };
    draw(0);
  }
}
'@, $utf8)
Write-Host "  [OK] main-dashboard.component.ts" -ForegroundColor Green

# ── 16. main-dashboard.component.html ────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\dashboard\main\main-dashboard.component.html", @'
<div class="dashboard-wrapper">
  <canvas id="shader-canvas" class="shader-bg"></canvas>

  <button class="sidebar-toggle" (click)="toggleSidebar()">
    <span class="ham-line"></span><span class="ham-line"></span><span class="ham-line"></span>
  </button>

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
      <button class="add-lead-btn" *ngIf="canCreateAny">+ Add New Lead</button>
    </div>

    <nav class="sidebar-nav">
      <a class="nav-item" *ngFor="let item of visibleNavItems" (click)="navigate(item.route)">
        <span class="nav-label">{{ item.label }}</span>
      </a>
    </nav>

    <div class="sidebar-footer">
      <a class="nav-item" (click)="goToSettings()"><span class="nav-label">Settings</span></a>
      <a class="nav-item logout" (click)="logout()"><span class="nav-label">Logout</span></a>
    </div>
  </aside>

  <main class="main-content" [class.expanded]="sidebarCollapsed">
    <header class="top-header" [class.expanded]="sidebarCollapsed">
      <div class="header-left">
        <div class="search-wrapper">
          <input type="text" class="search-input" placeholder="Global Search..." />
        </div>
        <nav class="header-nav">
          <a class="hnav-item active">Overview</a>
          <a class="hnav-item" *ngIf="canViewReports">Reports</a>
          <a class="hnav-item">Activity</a>
        </nav>
      </div>
      <div class="header-right">
        <button class="import-btn"   *ngIf="canViewReports">Export</button>
        <button class="primary-btn"  *ngIf="canCreateAny && canViewCustomers">Add Customer</button>
        <button class="settings-btn" (click)="goToSettings()">Settings</button>
      </div>
    </header>

    <div class="readonly-bar" *ngIf="isViewer">
      Read-only access. Contact your administrator for additional permissions.
    </div>

    <div class="dashboard-body">

      <div class="metrics-grid">
        <div class="metric-card"><p class="metric-label">TOTAL INCOME</p><p class="metric-value">BDT 12.4M</p></div>
        <div class="metric-card"><p class="metric-label">TOTAL EXPENSE</p><p class="metric-value">BDT 8.2M</p></div>
        <div class="metric-card border-green"><p class="metric-label">INCOME TODAY</p><p class="metric-value">BDT 45,000</p></div>
        <div class="metric-card border-red"><p class="metric-label">EXPENSE TODAY</p><p class="metric-value">BDT 12,500</p></div>
        <div class="metric-card"><p class="metric-label">INCOME THIS MONTH</p><p class="metric-value">BDT 840,000</p></div>
        <div class="metric-card"><p class="metric-label">EXPENSE THIS MONTH</p><p class="metric-value">BDT 320,000</p></div>
      </div>

      <div class="section-row">
        <div class="summary-col">
          <div class="summary-card blue-tint" *ngIf="canViewUsers">
            <div class="summary-top"><span class="summary-val">47</span></div>
            <p class="summary-label">CUSTOMERS</p>
          </div>
          <div class="summary-card">
            <div class="summary-top"><span class="summary-val">1</span></div>
            <p class="summary-label">COMPANIES</p>
          </div>
          <div class="summary-card">
            <p class="summary-val red-text">-BDT 11,395,628</p>
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

      <div class="two-col-row">
        <div class="glass-card table-card" *ngIf="canViewCustomers">
          <div class="table-header">
            <h3 class="card-title">Recent Clients</h3>
            <button class="small-btn" *ngIf="canCreateAny && scope.can('CREATE_CUSTOMER')">+ Add</button>
          </div>
          <table class="data-table">
            <thead>
              <tr>
                <th>IMAGE</th><th>NAME</th><th class="text-right">CREATED</th>
                <th class="text-right" *ngIf="canEditAny">ACTIONS</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><div class="avatar blue-av">IM</div></td>
                <td class="font-semi">Integrated Marketing Service Ltd.</td>
                <td class="text-right muted">07/04/2026</td>
                <td class="text-right" *ngIf="canEditAny">
                  <button class="tbl-btn" *ngIf="scope.can('EDIT_CUSTOMER')">Edit</button>
                  <button class="tbl-btn danger" *ngIf="canDeleteAny && scope.can('DELETE_CUSTOMER')">Delete</button>
                </td>
              </tr>
              <tr>
                <td><div class="avatar purple-av">BI</div></td>
                <td class="font-semi">Believe Int. Pvt. Ltd.</td>
                <td class="text-right muted">06/01/2026</td>
                <td class="text-right" *ngIf="canEditAny">
                  <button class="tbl-btn" *ngIf="scope.can('EDIT_CUSTOMER')">Edit</button>
                  <button class="tbl-btn danger" *ngIf="canDeleteAny && scope.can('DELETE_CUSTOMER')">Delete</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="glass-card table-card" *ngIf="canViewInvoices">
          <div class="table-header">
            <h3 class="card-title">Recent Invoices</h3>
            <div class="invoice-meta">
              <div class="progress-bar-wrap"><div class="progress-fill" style="width:31%"></div></div>
              <span class="meta-text">31% Paid</span>
            </div>
          </div>
          <table class="data-table">
            <thead>
              <tr>
                <th>#</th><th>ACCOUNT</th><th class="text-right">STATUS</th>
                <th class="text-right" *ngIf="canEditAny">ACTIONS</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td class="inv-id">INV-Jun090652026_Linnex</td>
                <td>Linnex Electronics Bangladesh</td>
                <td class="text-right"><span class="badge unpaid">Unpaid</span></td>
                <td class="text-right" *ngIf="canEditAny">
                  <button class="tbl-btn" *ngIf="scope.can('APPROVE_INVOICE')">Approve</button>
                </td>
              </tr>
              <tr>
                <td class="inv-id">INV-Jun090652026_Somatec</td>
                <td>SOMATEC PHARMACEUTICALS LTD.</td>
                <td class="text-right"><span class="badge unpaid">Unpaid</span></td>
                <td class="text-right" *ngIf="canEditAny">
                  <button class="tbl-btn" *ngIf="scope.can('APPROVE_INVOICE')">Approve</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div class="three-col-row">
        <div class="glass-card">
          <div class="table-header">
            <h3 class="card-title">Latest Expense</h3>
            <button class="small-btn" *ngIf="scope.can('CREATE_PAYMENT')">+ Add</button>
          </div>
          <div class="expense-list">
            <div class="expense-item" *ngFor="let item of latestExpenses">
              <div><p class="exp-date">{{ item.date }}</p><p class="exp-desc">{{ item.desc }}</p></div>
              <p class="exp-amount">BDT {{ item.amount }}</p>
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
              <span class="acc-name">{{ acc.name }}</span>
              <span class="acc-amount">{{ acc.amount }}</span>
            </div>
          </div>
        </div>
      </div>

      <div class="two-col-row">
        <div class="glass-card sales-card" *ngIf="canViewReports">
          <h3 class="card-title">Sales Distribution</h3>
          <div class="donut-wrapper">
            <svg class="donut-svg" viewBox="0 0 100 100">
              <circle cx="50" cy="50" r="40" fill="transparent" stroke="rgba(255,255,255,0.2)" stroke-width="8"/>
              <circle cx="50" cy="50" r="40" fill="transparent" stroke="#003874" stroke-width="8"
                      stroke-dasharray="251.2" stroke-dashoffset="60" stroke-linecap="round" transform="rotate(-90 50 50)"/>
            </svg>
            <div class="donut-center"><span class="donut-label">Total Sales</span><span class="donut-value">1.4k</span></div>
          </div>
          <div class="sales-stats">
            <div class="stat-box"><p class="stat-label">COUNT</p><p class="stat-val">842</p></div>
            <div class="stat-box"><p class="stat-label">VOLUME</p><p class="stat-val">BDT 4.2M</p></div>
          </div>
        </div>
        <div class="glass-card calendar-card">
          <div class="cal-header">
            <h3 class="card-title">JUNE 2026</h3>
            <div class="cal-nav">
              <button class="cal-btn">Today</button>
              <button class="cal-nav-btn">&#8249;</button>
              <button class="cal-nav-btn">&#8250;</button>
            </div>
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
Write-Host "  [OK] main-dashboard.component.html" -ForegroundColor Green

# ── 17. main-dashboard.component.css ─────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\dashboard\main\main-dashboard.component.css", @'
@import url("https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap");
*{box-sizing:border-box;margin:0;padding:0}
:host{--p:#003874;--pc:#1a4f95;--os:#1a1c20;--osv:#424751;--ok:#10B981;--od:#EF4444;--ow:#F59E0B;font-family:"Inter","Segoe UI",sans-serif}
.shader-bg{position:fixed;inset:0;width:100%;height:100%;z-index:-1}
.dashboard-wrapper{display:flex;min-height:100vh}
.sidebar-toggle{position:fixed;top:14px;left:14px;width:36px;height:36px;background:rgba(255,255,255,.45);backdrop-filter:blur(16px);border:1px solid rgba(255,255,255,.5);border-radius:8px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:4px;cursor:pointer;z-index:60}
.ham-line{width:16px;height:2px;background:var(--p);border-radius:2px}
.sidebar{position:fixed;left:0;top:0;width:200px;height:100vh;display:flex;flex-direction:column;background:rgba(255,255,255,.18);backdrop-filter:blur(24px);border-right:1px solid rgba(255,255,255,.2);z-index:40;overflow-y:auto;transition:transform .3s}
.sidebar.collapsed{transform:translateX(-200px)}
.sidebar-logo{padding:20px 16px 16px;border-bottom:1px solid rgba(255,255,255,.2)}
.logo-text{font-size:16px;font-weight:800;color:var(--pc);letter-spacing:.05em}
.sidebar-profile{padding:12px;border-bottom:1px solid rgba(255,255,255,.15);display:flex;flex-direction:column;gap:10px}
.profile-card{display:flex;align-items:center;gap:10px;padding:10px;background:rgba(255,255,255,.35);border:1px solid rgba(255,255,255,.4);border-radius:12px}
.profile-avatar{width:36px;height:36px;border-radius:50%;background:var(--p);color:white;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;flex-shrink:0}
.profile-name{font-size:12px;font-weight:600;color:var(--os)}
.profile-role{font-size:10px;color:var(--osv);text-transform:capitalize}
.add-lead-btn{width:100%;padding:10px;background:var(--p);color:white;border:none;border-radius:10px;font-size:12px;font-weight:700;cursor:pointer;transition:all .2s}
.add-lead-btn:hover{background:var(--pc)}
.sidebar-nav{flex:1;padding:10px 8px;display:flex;flex-direction:column;gap:2px;overflow-y:auto}
.nav-item{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:0 24px 24px 0;font-size:12px;font-weight:500;color:var(--osv);cursor:pointer;transition:all .2s}
.nav-item:hover{background:rgba(255,255,255,.15);color:var(--os)}
.nav-item.logout{color:var(--od)}
.nav-item.logout:hover{background:rgba(239,68,68,.1)}
.nav-label{font-size:13px}
.sidebar-footer{padding:8px;border-top:1px solid rgba(255,255,255,.2)}
.main-content{margin-left:200px;flex:1;min-height:100vh;display:flex;flex-direction:column;transition:margin-left .3s}
.main-content.expanded{margin-left:0}
.top-header{position:fixed;top:0;right:0;left:200px;height:60px;display:flex;align-items:center;justify-content:space-between;padding:0 24px 0 60px;background:rgba(255,255,255,.12);backdrop-filter:blur(12px);border-bottom:1px solid rgba(255,255,255,.15);z-index:50;transition:left .3s}
.top-header.expanded{left:0}
.header-left{display:flex;align-items:center;gap:24px}
.search-input{padding:7px 14px;background:rgba(255,255,255,.25);border:1px solid rgba(255,255,255,.35);border-radius:24px;font-size:13px;outline:none;width:220px;font-family:inherit;color:var(--os)}
.header-nav{display:flex;gap:20px}
.hnav-item{font-size:13px;font-weight:500;color:var(--osv);cursor:pointer;padding-bottom:2px}
.hnav-item.active{color:var(--p);font-weight:700;border-bottom:2px solid var(--p)}
.header-right{display:flex;align-items:center;gap:10px}
.import-btn{padding:7px 16px;background:rgba(255,255,255,.4);border:1px solid rgba(255,255,255,.5);border-radius:8px;font-size:12px;font-weight:700;color:var(--p);cursor:pointer;font-family:inherit}
.primary-btn{padding:7px 16px;background:var(--p);color:white;border:none;border-radius:8px;font-size:12px;font-weight:700;cursor:pointer;font-family:inherit;transition:all .2s}
.primary-btn:hover{background:var(--pc)}
.settings-btn{padding:7px 16px;background:rgba(255,255,255,.3);color:var(--p);border:1px solid rgba(255,255,255,.5);border-radius:8px;font-size:12px;font-weight:700;cursor:pointer;font-family:inherit}
.readonly-bar{background:#fffbeb;border-bottom:1px solid #fde68a;padding:10px 24px;font-size:13px;color:#92400e;font-weight:500;margin-top:60px}
.dashboard-body{padding:80px 24px 32px;display:flex;flex-direction:column;gap:20px}
.glass-card{background:rgba(255,255,255,.38);backdrop-filter:blur(20px);border:1px solid rgba(255,255,255,.35);border-radius:16px;box-shadow:0 8px 32px rgba(31,38,135,.07);padding:20px;transition:transform .3s}
.glass-card:hover{transform:translateY(-3px)}
.card-title{font-size:14px;font-weight:700;color:var(--os)}
.metrics-grid{display:grid;grid-template-columns:repeat(6,1fr);gap:12px}
.metric-card{background:rgba(255,255,255,.38);backdrop-filter:blur(20px);border:1px solid rgba(255,255,255,.35);border-radius:12px;padding:14px;text-align:center;transition:transform .3s}
.metric-card:hover{transform:translateY(-3px)}
.metric-card.border-green{border-left:4px solid var(--ok)}
.metric-card.border-red{border-left:4px solid var(--od)}
.metric-label{font-size:9px;font-weight:700;color:var(--osv);text-transform:uppercase;letter-spacing:.05em;margin-bottom:4px}
.metric-value{font-size:15px;font-weight:700;color:var(--os)}
.section-row{display:grid;grid-template-columns:220px 1fr;gap:16px;align-items:start}
.summary-col{display:flex;flex-direction:column;gap:12px}
.summary-card{background:rgba(255,255,255,.38);backdrop-filter:blur(20px);border:1px solid rgba(255,255,255,.35);border-radius:14px;padding:16px;transition:transform .3s}
.summary-card:hover{transform:translateY(-2px)}
.summary-card.blue-tint{background:rgba(0,56,116,.08)}
.summary-top{display:flex;justify-content:space-between;align-items:center;margin-bottom:4px}
.summary-val{font-size:22px;font-weight:700;color:var(--os)}
.summary-label{font-size:10px;font-weight:700;color:var(--osv);text-transform:uppercase;letter-spacing:.05em}
.red-text{color:var(--od)}
.net-worth-foot{display:flex;justify-content:space-between;margin-top:8px;font-size:11px;color:var(--osv)}
.trend-card{padding:20px}
.trend-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:16px}
.legend-row{display:flex;gap:14px}
.legend-item{display:flex;align-items:center;gap:6px;font-size:11px;color:var(--osv)}
.legend-dot{width:10px;height:10px;border-radius:50%}
.legend-dot.navy{background:var(--p)}
.legend-dot.orange{background:var(--ow)}
.chart-area{height:200px}
.trend-svg{width:100%;height:100%}
.chart-labels{display:flex;justify-content:space-between;font-size:10px;color:var(--osv);font-weight:700;padding:4px}
.two-col-row{display:grid;grid-template-columns:1fr 1fr;gap:16px}
.table-card{padding:0;overflow:hidden}
.table-header{display:flex;justify-content:space-between;align-items:center;padding:14px 18px;background:rgba(255,255,255,.15);border-bottom:1px solid rgba(255,255,255,.2)}
.invoice-meta{display:flex;align-items:center;gap:8px}
.progress-bar-wrap{width:80px;height:6px;background:rgba(255,255,255,.3);border-radius:99px;overflow:hidden}
.progress-fill{height:100%;background:var(--ok);border-radius:99px}
.meta-text{font-size:10px;font-weight:700;color:var(--osv)}
.data-table{width:100%;border-collapse:collapse;font-size:12px}
.data-table thead tr{background:rgba(255,255,255,.18)}
.data-table th{padding:10px 18px;font-size:9px;font-weight:700;text-transform:uppercase;letter-spacing:.05em;color:var(--osv);text-align:left}
.data-table tbody tr{border-bottom:1px solid rgba(255,255,255,.12);transition:background .15s}
.data-table tbody tr:hover{background:rgba(255,255,255,.2)}
.data-table td{padding:12px 18px;color:var(--os);font-size:12px}
.text-right{text-align:right!important}
.muted{color:var(--osv)}
.font-semi{font-weight:600}
.avatar{width:30px;height:30px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:9px;font-weight:700}
.blue-av{background:#dbeafe;color:#1d4ed8}
.purple-av{background:#ede9fe;color:#7c3aed}
.inv-id{font-size:10px;color:var(--p);font-weight:500}
.badge{display:inline-block;padding:2px 8px;border-radius:4px;font-size:10px;font-weight:700}
.badge.unpaid{background:#ffdad6;color:#ba1a1a}
.badge.paid{background:#dcfce7;color:#15803d}
.small-btn{padding:4px 10px;background:var(--p);color:white;border:none;border-radius:6px;font-size:11px;font-weight:700;cursor:pointer}
.tbl-btn{padding:3px 8px;background:rgba(255,255,255,.3);border:1px solid rgba(255,255,255,.4);border-radius:4px;font-size:10px;font-weight:600;cursor:pointer;margin-left:4px;color:var(--p)}
.tbl-btn.danger{color:var(--od);border-color:rgba(239,68,68,.3);background:rgba(239,68,68,.08)}
.three-col-row{display:grid;grid-template-columns:1fr 1.4fr 1fr;gap:16px}
.expense-list{display:flex;flex-direction:column;gap:8px;margin-top:12px}
.expense-item{display:flex;justify-content:space-between;align-items:center;padding:8px 10px;background:rgba(255,255,255,.18);border-radius:8px}
.exp-date{font-size:10px;font-weight:700;color:var(--p)}
.exp-desc{font-size:11px;color:var(--osv);margin-top:2px}
.exp-amount{font-size:13px;font-weight:700;color:var(--os);white-space:nowrap;margin-left:8px}
.category-list{display:flex;flex-direction:column;gap:14px}
.category-item{display:flex;flex-direction:column;gap:5px}
.cat-header{display:flex;justify-content:space-between;font-size:10px;font-weight:700;text-transform:uppercase;color:var(--osv)}
.cat-bar-bg{height:6px;background:rgba(255,255,255,.25);border-radius:99px;overflow:hidden}
.cat-bar-fill{height:100%;border-radius:99px}
.balance-list{display:flex;flex-direction:column}
.balance-item{display:flex;justify-content:space-between;align-items:center;padding:10px 0;border-bottom:1px solid rgba(255,255,255,.15)}
.balance-item:last-child{border-bottom:none}
.acc-name,.acc-amount{font-size:12px;color:var(--os)}
.acc-amount{font-weight:700}
.sales-card{display:flex;flex-direction:column;align-items:center;gap:16px}
.donut-wrapper{position:relative;width:140px;height:140px}
.donut-svg{width:100%;height:100%}
.donut-center{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center}
.donut-label{font-size:9px;font-weight:700;text-transform:uppercase;color:var(--osv)}
.donut-value{font-size:20px;font-weight:700;color:var(--os)}
.sales-stats{display:grid;grid-template-columns:1fr 1fr;gap:10px;width:100%}
.stat-box{text-align:center;padding:10px;background:rgba(255,255,255,.2);border-radius:10px}
.stat-label{font-size:9px;font-weight:700;text-transform:uppercase;color:var(--osv);letter-spacing:.05em;margin-bottom:4px}
.stat-val{font-size:15px;font-weight:700;color:var(--os)}
.cal-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:16px}
.cal-nav{display:flex;gap:6px}
.cal-btn{padding:4px 10px;background:rgba(255,255,255,.25);border:none;border-radius:6px;font-size:10px;font-weight:700;cursor:pointer;font-family:inherit}
.cal-nav-btn{width:26px;height:26px;background:rgba(255,255,255,.25);border:none;border-radius:6px;font-size:14px;cursor:pointer}
.cal-grid{display:grid;grid-template-columns:repeat(7,1fr);gap:6px}
.cal-day-name{text-align:center;font-size:9px;font-weight:700;text-transform:uppercase;color:var(--osv);padding:6px 0}
.cal-day{height:52px;border:1px solid rgba(255,255,255,.15);border-radius:8px;background:rgba(255,255,255,.06);font-size:11px;padding:4px 6px;color:var(--os);cursor:pointer}
.cal-day.empty{opacity:.35}
.cal-day.today{background:rgba(26,79,149,.25);border:2px solid var(--p);font-weight:700}
@media(max-width:1100px){.metrics-grid{grid-template-columns:repeat(3,1fr)}.three-col-row{grid-template-columns:1fr 1fr}.section-row{grid-template-columns:1fr}}
@media(max-width:768px){.sidebar{width:60px}.main-content{margin-left:60px}.top-header{left:60px}.two-col-row{grid-template-columns:1fr}.metrics-grid{grid-template-columns:repeat(2,1fr)}}
'@, $utf8)
Write-Host "  [OK] main-dashboard.component.css" -ForegroundColor Green

# ── 18. settings component ────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\settings\settings.component.ts", @'
import { Component, OnInit } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";
import { Router } from "@angular/router";
import { HttpClient, HttpHeaders } from "@angular/common/http";
import { AuthService }  from "../services/auth.service";
import { ScopeService } from "../services/scope.service";

interface UserDto  { id: number; username: string; email: string; roleName: string; roleId: number; active: boolean; }
interface RoleDto  { id: number; roleName: string; }
interface ScopeDto { id: number; name: string; }

@Component({
  selector: "app-settings", standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: "./settings.component.html",
  styleUrls: ["./settings.component.css"]
})
export class SettingsComponent implements OnInit {
  private api = "http://localhost:8080/api";
  currentUsername = ""; currentRole = ""; userInitials = "";
  activeTab = "account";
  accountForm = { fullName: "", email: "" };
  savingAccount = false;
  users: UserDto[] = []; roles: RoleDto[] = []; loadingUsers = false; userError = "";
  scopes: ScopeDto[] = []; showAddScope = false; creatingScope = false;
  newScope = { scopeName: "", targetRoleId: 0 };

  constructor(private http: HttpClient, private auth: AuthService, public scopeSvc: ScopeService, private router: Router) {}

  ngOnInit(): void {
    this.currentUsername      = this.auth.getUsername() || "User";
    this.currentRole          = this.auth.getRole() || "";
    this.userInitials         = this.getInitials(this.currentUsername);
    this.accountForm.fullName = this.currentUsername;

    if (this.scopeSvc.canSeeUserManagement()) { this.loadUsers(); this.loadRoles(); this.activeTab = "users"; }
    if (this.scopeSvc.canSeeScopesTab())      { this.loadScopes(); }
  }

  goBack(): void { this.router.navigate(["/dashboard"]); }
  getInitials(n: string): string { return n.split(" ").map(w => w[0].toUpperCase()).slice(0,2).join(""); }
  private h(): HttpHeaders { return new HttpHeaders({ Authorization: `Bearer ${this.auth.getAccessToken()}` }); }
  saveAccount(): void { this.savingAccount = true; setTimeout(() => this.savingAccount = false, 800); }

  loadUsers(): void {
    this.loadingUsers = true; this.userError = "";
    this.http.get<UserDto[]>(`${this.api}/users`, { headers: this.h() }).subscribe({
      next: u => { this.users = u; this.loadingUsers = false; },
      error: () => { this.userError = "Failed to load users."; this.loadingUsers = false; }
    });
  }

  loadRoles(): void {
    this.http.get<RoleDto[]>(`${this.api}/roles`, { headers: this.h() }).subscribe({ next: r => this.roles = r });
  }

  loadScopes(): void {
    this.http.get<ScopeDto[]>(`${this.api}/scopes`, { headers: this.h() }).subscribe({ next: s => this.scopes = s });
  }

  onRoleChange(u: UserDto): void {
    this.http.put(`${this.api}/users/${u.id}/role`, { roleId: Number(u.roleId) }, { headers: this.h(), responseType: "text" }).subscribe({
      next: () => { u.roleName = this.roles.find(r => r.id == u.roleId)?.roleName || ""; },
      error: err => { alert(err?.error || "Failed to update role."); this.loadUsers(); }
    });
  }

  onStatusChange(u: UserDto): void {
    const isActive = String(u.active) === "true";
    u.active = isActive;
    this.http.put(`${this.api}/users/${u.id}/status`, { active: isActive }, { headers: this.h(), responseType: "text" }).subscribe({
      error: () => { alert("Failed to update status."); this.loadUsers(); }
    });
  }

  deleteUser(u: UserDto): void {
    if (!confirm(`Delete "${u.username}"?`)) return;
    this.http.delete(`${this.api}/users/${u.id}`, { headers: this.h(), responseType: "text" }).subscribe({
      next: () => { this.users = this.users.filter(x => x.id !== u.id); },
      error: err => { alert(err?.error || "Failed to delete."); }
    });
  }

  createScope(): void {
    if (!this.newScope.scopeName.trim() || !this.newScope.targetRoleId) { alert("Fill all fields."); return; }
    this.creatingScope = true;
    this.http.post<ScopeDto>(`${this.api}/scopes`,
      { scopeName: this.newScope.scopeName.toUpperCase().trim(), targetRoleId: Number(this.newScope.targetRoleId) },
      { headers: this.h() }).subscribe({
      next: s => { this.scopes.push(s); this.newScope = { scopeName: "", targetRoleId: 0 }; this.showAddScope = false; this.creatingScope = false; },
      error: err => { alert(err?.error?.error || "Failed to create scope."); this.creatingScope = false; }
    });
  }

  deleteScope(s: ScopeDto): void {
    if (!confirm(`Delete scope "${s.name}"?`)) return;
    this.http.delete(`${this.api}/scopes/${s.id}`, { headers: this.h(), responseType: "text" }).subscribe({
      next: () => { this.scopes = this.scopes.filter(x => x.id !== s.id); },
      error: () => { alert("Failed to delete scope."); }
    });
  }
}
'@, $utf8)
Write-Host "  [OK] settings.component.ts" -ForegroundColor Green

# ── 19. settings.component.html ───────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\settings\settings.component.html", @'
<div class="settings-page">
  <aside class="settings-sidebar">
    <div class="sidebar-profile">
      <div class="avatar-sm">{{ userInitials }}</div>
      <div class="profile-text">
        <p class="profile-name-sm">{{ currentUsername }}</p>
        <p class="profile-role-sm">{{ currentRole }}</p>
      </div>
    </div>
    <nav class="sidebar-tabs">
      <a class="tab-link" [class.active]="activeTab==='account'" (click)="activeTab='account'">Account</a>
      <a class="tab-link" *ngIf="scopeSvc.canSeeUserManagement()" [class.active]="activeTab==='users'" (click)="activeTab='users'">User Management</a>
      <a class="tab-link" *ngIf="scopeSvc.canSeeScopesTab()" [class.active]="activeTab==='scopes'" (click)="activeTab='scopes'">Scopes and Roles</a>
    </nav>
    <button class="back-btn" (click)="goBack()">Back to Dashboard</button>
  </aside>

  <main class="settings-main">

    <section *ngIf="activeTab==='account'" class="panel">
      <h1 class="panel-title">Account</h1>
      <p class="panel-subtitle">Update your personal information.</p>
      <div class="card">
        <div class="field-row">
          <div class="field-group">
            <label class="field-label">Full Name</label>
            <input type="text" class="field-input" [(ngModel)]="accountForm.fullName" />
          </div>
          <div class="field-group">
            <label class="field-label">Email Address</label>
            <input type="email" class="field-input" [(ngModel)]="accountForm.email" />
          </div>
        </div>
        <div class="card-actions">
          <button class="link-btn">Change Password</button>
          <button class="primary-btn" (click)="saveAccount()">{{ savingAccount ? "Saving..." : "Save Changes" }}</button>
        </div>
      </div>
    </section>

    <section *ngIf="activeTab==='users' && scopeSvc.canSeeUserManagement()" class="panel">
      <h1 class="panel-title">User Management</h1>
      <p class="panel-subtitle">Control roles and access for every registered user.</p>
      <div *ngIf="loadingUsers" class="loading-text">Loading users...</div>
      <div *ngIf="userError" class="error-banner">{{ userError }}</div>
      <div class="card no-pad" *ngIf="!loadingUsers && !userError">
        <table class="user-table">
          <thead>
            <tr>
              <th>USER</th><th>EMAIL</th><th>ROLE</th><th>STATUS</th>
              <th class="text-right" *ngIf="scopeSvc.canDeleteUsers()">ACTIONS</th>
            </tr>
          </thead>
          <tbody>
            <tr *ngFor="let u of users">
              <td>
                <div class="user-cell">
                  <div class="user-avatar">{{ getInitials(u.username) }}</div>
                  <span class="user-name">{{ u.username }}</span>
                </div>
              </td>
              <td class="muted">{{ u.email }}</td>
              <td>
                <ng-container *ngIf="scopeSvc.canManageUsers(); else roleRO">
                  <select class="role-select" [(ngModel)]="u.roleId" (change)="onRoleChange(u)">
                    <option *ngFor="let r of roles" [value]="r.id">{{ r.roleName }}</option>
                  </select>
                </ng-container>
                <ng-template #roleRO><span class="role-badge">{{ u.roleName }}</span></ng-template>
              </td>
              <td>
                <ng-container *ngIf="scopeSvc.canManageUsers(); else statusRO">
                  <select class="status-select"
                    [class.status-active]="u.active===true || u.active.toString()==='true'"
                    [class.status-inactive]="u.active===false || u.active.toString()==='false'"
                    [(ngModel)]="u.active" (change)="onStatusChange(u)">
                    <option [ngValue]="true">Active</option>
                    <option [ngValue]="false">Inactive</option>
                  </select>
                </ng-container>
                <ng-template #statusRO>
                  <span class="status-ro" [class.status-active]="u.active">{{ u.active ? "Active" : "Inactive" }}</span>
                </ng-template>
              </td>
              <td class="text-right" *ngIf="scopeSvc.canDeleteUsers()">
                <button class="icon-btn-sm danger" (click)="deleteUser(u)">Delete</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section *ngIf="activeTab==='scopes' && scopeSvc.canSeeScopesTab()" class="panel">
      <div class="panel-header-row">
        <div>
          <h1 class="panel-title">Scopes and Roles</h1>
          <p class="panel-subtitle">Manage permissions assigned to each role.</p>
        </div>
        <button class="primary-btn" (click)="showAddScope=!showAddScope">{{ showAddScope ? "Cancel" : "+ Add Scope" }}</button>
      </div>
      <div class="card" *ngIf="showAddScope">
        <div class="field-row">
          <div class="field-group">
            <label class="field-label">Scope Name (must match ScopeEnum)</label>
            <input type="text" class="field-input" [(ngModel)]="newScope.scopeName" placeholder="e.g. EXPORT_REPORT" />
          </div>
          <div class="field-group">
            <label class="field-label">Assign To Role</label>
            <select class="field-input" [(ngModel)]="newScope.targetRoleId">
              <option [value]="0" disabled>Select role...</option>
              <option *ngFor="let r of roles" [value]="r.id">{{ r.roleName }}</option>
            </select>
          </div>
        </div>
        <p class="hint-text">SUPER_ADMIN is automatically granted this scope.</p>
        <div class="card-actions">
          <span></span>
          <button class="primary-btn" (click)="createScope()">{{ creatingScope ? "Creating..." : "Create Scope" }}</button>
        </div>
      </div>
      <div class="card no-pad">
        <table class="user-table">
          <thead><tr><th>SCOPE NAME</th><th class="text-right">ACTIONS</th></tr></thead>
          <tbody>
            <tr *ngFor="let s of scopes">
              <td><span class="scope-pill">{{ s.name }}</span></td>
              <td class="text-right"><button class="icon-btn-sm danger" (click)="deleteScope(s)">Delete</button></td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

  </main>
</div>
'@, $utf8)
Write-Host "  [OK] settings.component.html" -ForegroundColor Green

# ── 20. settings.component.css ────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\app\settings\settings.component.css", @'
@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap");
*{box-sizing:border-box;margin:0;padding:0}
:host{--p:#003874;--pl:#d0e1fb;--os:#1a1c20;--osv:#424751;--b:#e2e8f0;--bg:#f9f9ff;display:block;font-family:"Inter","Segoe UI",sans-serif}
.settings-page{display:flex;min-height:100vh;background:var(--bg)}
.settings-sidebar{width:220px;background:white;border-right:1px solid var(--b);display:flex;flex-direction:column;padding:20px 14px;gap:24px}
.sidebar-profile{display:flex;align-items:center;gap:10px;padding:10px;background:#f8fafc;border-radius:10px}
.avatar-sm{width:36px;height:36px;border-radius:50%;background:var(--p);color:white;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;flex-shrink:0}
.profile-text{overflow:hidden}
.profile-name-sm{font-size:13px;font-weight:600;color:var(--os);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.profile-role-sm{font-size:11px;color:var(--osv);text-transform:capitalize}
.sidebar-tabs{display:flex;flex-direction:column;gap:2px;flex:1}
.tab-link{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:8px;font-size:13px;font-weight:500;color:var(--osv);cursor:pointer;transition:all .2s}
.tab-link:hover{background:#f1f5f9;color:var(--os)}
.tab-link.active{background:var(--pl);color:var(--p);font-weight:700}
.back-btn{background:none;border:none;font-size:13px;font-weight:600;color:var(--p);cursor:pointer;text-align:left;padding:10px 12px;border-radius:8px;transition:background .2s;font-family:inherit}
.back-btn:hover{background:#f1f5f9}
.settings-main{flex:1;padding:32px 40px}
.panel-title{font-size:24px;font-weight:700;color:var(--p);margin-bottom:4px}
.panel-subtitle{font-size:14px;color:var(--osv);margin-bottom:24px}
.panel-header-row{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:24px}
.panel-header-row .panel-title,.panel-header-row .panel-subtitle{margin-bottom:4px}
.card{background:white;border:1px solid var(--b);border-radius:12px;padding:24px;margin-bottom:20px}
.card.no-pad{padding:0;overflow:hidden}
.field-row{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:16px}
.field-group{display:flex;flex-direction:column;gap:6px}
.field-label{font-size:12px;font-weight:700;color:var(--os)}
.field-input{width:100%;padding:10px 13px;border:1px solid var(--b);border-radius:8px;font-size:13px;font-family:inherit;color:var(--os);outline:none;transition:all .2s}
.field-input:focus{border-color:var(--p);box-shadow:0 0 0 3px rgba(0,56,116,.08)}
.hint-text{font-size:12px;color:var(--osv);margin-bottom:16px}
.card-actions{display:flex;justify-content:space-between;align-items:center;padding-top:16px;border-top:1px solid var(--b)}
.link-btn{background:none;border:none;color:var(--p);font-size:13px;font-weight:700;cursor:pointer;font-family:inherit}
.link-btn:hover{text-decoration:underline}
.primary-btn{padding:10px 20px;background:var(--p);color:white;border:none;border-radius:8px;font-size:13px;font-weight:700;cursor:pointer;transition:all .2s;font-family:inherit}
.primary-btn:hover{background:#1a4f95}
.user-table{width:100%;border-collapse:collapse}
.user-table thead tr{background:#f8fafc;border-bottom:1px solid var(--b)}
.user-table th{padding:12px 18px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.05em;color:var(--osv);text-align:left}
.user-table tbody tr{border-bottom:1px solid var(--b)}
.user-table tbody tr:last-child{border-bottom:none}
.user-table tbody tr:hover{background:#f8fafc}
.user-table td{padding:12px 18px;font-size:13px;color:var(--os)}
.text-right{text-align:right!important}
.muted{color:var(--osv)}
.user-cell{display:flex;align-items:center;gap:10px}
.user-avatar{width:28px;height:28px;border-radius:50%;background:var(--pl);color:var(--p);display:flex;align-items:center;justify-content:center;font-size:10px;font-weight:700}
.user-name{font-weight:600}
.role-select{padding:6px 10px;border:1px solid var(--b);border-radius:6px;font-size:12px;font-family:inherit;color:var(--os);background:white;cursor:pointer;outline:none}
.role-badge{display:inline-block;padding:3px 10px;background:var(--pl);color:var(--p);border-radius:6px;font-size:12px;font-weight:600}
.status-select{padding:5px 10px;border:none;border-radius:6px;font-size:12px;font-weight:700;font-family:inherit;cursor:pointer;outline:none;appearance:none}
.status-select.status-active{background:#dcfce7;color:#15803d}
.status-select.status-inactive{background:#ffdad6;color:#ba1a1a}
.status-ro{display:inline-block;padding:3px 10px;border-radius:6px;font-size:12px;font-weight:700}
.status-ro.status-active{background:#dcfce7;color:#15803d}
.scope-pill{display:inline-block;padding:4px 12px;background:var(--pl);color:var(--p);border-radius:6px;font-size:12px;font-weight:600;font-family:"Courier New",monospace}
.icon-btn-sm{background:none;border:none;font-size:13px;cursor:pointer;padding:5px 10px;border-radius:6px;transition:background .2s;font-family:inherit;font-weight:600}
.icon-btn-sm.danger{color:#ba1a1a}
.icon-btn-sm.danger:hover{background:#ffdad6}
.loading-text{font-size:13px;color:var(--osv);padding:20px;text-align:center}
.error-banner{background:#ffdad6;color:#ba1a1a;padding:12px 16px;border-radius:8px;font-size:13px;margin-bottom:16px}
.placeholder-text{font-size:13px;color:var(--osv)}
@media(max-width:768px){.settings-page{flex-direction:column}.settings-sidebar{width:100%}.field-row{grid-template-columns:1fr}}
'@, $utf8)
Write-Host "  [OK] settings.component.css" -ForegroundColor Green

# ── 21. styles.css ────────────────────────────────────────────
[System.IO.File]::WriteAllText("$PWD\src\styles.css", @'
@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap");
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:"Inter","Segoe UI",Arial,sans-serif;background:#f9f9ff;color:#1a1c20}
'@, $utf8)
Write-Host "  [OK] styles.css" -ForegroundColor Green

# ── 22. Fix BOM on everything ─────────────────────────────────
Get-ChildItem -Path "src" -Recurse -Include "*.ts","*.html","*.css" | ForEach-Object {
  $c = Get-Content $_.FullName -Raw
  if ($c) { [System.IO.File]::WriteAllText($_.FullName, $c.TrimStart([char]0xFEFF), $utf8) }
}
Write-Host "  [OK] BOM removed from all files" -ForegroundColor Green

Write-Host ""
Write-Host "Single dynamic dashboard complete!" -ForegroundColor Cyan
Write-Host "Run: ng serve" -ForegroundColor Yellow
Write-Host ""
Write-Host "Role behaviour summary:" -ForegroundColor White
Write-Host "  SUPER_ADMIN  -> Full access, all nav, all buttons" -ForegroundColor Green
Write-Host "  ADMIN        -> No SUPER_ADMIN users visible, all else same" -ForegroundColor Green
Write-Host "  ACCOUNTANT   -> Scope-based nav, can add scopes, no user edit/delete" -ForegroundColor Green
Write-Host "  VIEWER       -> Read-only bar, no create/edit/delete buttons, Account tab only in settings" -ForegroundColor Green
