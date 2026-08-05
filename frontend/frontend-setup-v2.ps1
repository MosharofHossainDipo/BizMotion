# BizMotion Frontend Setup Script
# Run from D:\rbca-frontend
# Creates all auth components, services, guards

$src = "src\app"

Write-Host "Creating BizMotion frontend files..." -ForegroundColor Cyan

# ── Create folders ────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path "$src\auth\login"
New-Item -ItemType Directory -Force -Path "$src\auth\register"
New-Item -ItemType Directory -Force -Path "$src\dashboard\admin"
New-Item -ItemType Directory -Force -Path "$src\dashboard\user"
New-Item -ItemType Directory -Force -Path "$src\guards"
New-Item -ItemType Directory -Force -Path "$src\services"
New-Item -ItemType Directory -Force -Path "$src\models"
New-Item -ItemType Directory -Force -Path "$src\interceptors"
Write-Host "  [OK] Folders created" -ForegroundColor Green

# ── models/auth.model.ts ──────────────────────────────────────
@'
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
  accessToken: string;
  refreshToken: string;
  role: string;
}
'@ | Set-Content "$src\models\auth.model.ts" -Encoding ASCII
Write-Host "  [OK] auth.model.ts" -ForegroundColor Green

# ── services/auth.service.ts ──────────────────────────────────
@'
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { LoginRequest, RegisterRequest, AuthResponse } from '../models/auth.model';

@Injectable({ providedIn: 'root' })
export class AuthService {

  private baseUrl = 'http://localhost:8080/api/auth';

  constructor(private http: HttpClient) {}

  // ── Register ────────────────────────────────────────────────
  register(data: RegisterRequest): Observable<string> {
    return this.http.post<string>(`${this.baseUrl}/register`, data, { responseType: 'text' as 'json' });
  }

  // ── Login ───────────────────────────────────────────────────
  login(data: LoginRequest): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.baseUrl}/login`, data);
  }

  // ── Refresh ─────────────────────────────────────────────────
  refresh(refreshToken: string): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.baseUrl}/refresh`, { refreshToken });
  }

  // ── Token helpers ────────────────────────────────────────────
  saveTokens(res: AuthResponse): void {
    sessionStorage.setItem('accessToken', res.accessToken);
    sessionStorage.setItem('refreshToken', res.refreshToken);
    sessionStorage.setItem('role', res.role);
  }

  getAccessToken(): string | null {
    return sessionStorage.getItem('accessToken');
  }

  getRefreshToken(): string | null {
    return sessionStorage.getItem('refreshToken');
  }

  getRole(): string | null {
    return sessionStorage.getItem('role');
  }

  isLoggedIn(): boolean {
    return !!this.getAccessToken();
  }

  logout(): void {
    sessionStorage.clear();
  }
}
'@ | Set-Content "$src\services\auth.service.ts" -Encoding ASCII
Write-Host "  [OK] auth.service.ts" -ForegroundColor Green

# ── interceptors/jwt.interceptor.ts ──────────────────────────
@'
import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, switchMap, throwError } from 'rxjs';
import { AuthService } from '../services/auth.service';
import { Router } from '@angular/router';

export const jwtInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  const token = authService.getAccessToken();

  // Attach token to every request
  const authReq = token
    ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
    : req;

  return next(authReq).pipe(
    catchError((error: HttpErrorResponse) => {
      // If 401 — try refresh token
      if (error.status === 401) {
        const refreshToken = authService.getRefreshToken();
        if (refreshToken) {
          return authService.refresh(refreshToken).pipe(
            switchMap(res => {
              authService.saveTokens(res);
              // Retry original request with new token
              const retryReq = req.clone({
                setHeaders: { Authorization: `Bearer ${res.accessToken}` }
              });
              return next(retryReq);
            }),
            catchError(() => {
              // Refresh also failed — logout
              authService.logout();
              router.navigate(['/login']);
              return throwError(() => error);
            })
          );
        }
        authService.logout();
        router.navigate(['/login']);
      }
      return throwError(() => error);
    })
  );
};
'@ | Set-Content "$src\interceptors\jwt.interceptor.ts" -Encoding ASCII
Write-Host "  [OK] jwt.interceptor.ts" -ForegroundColor Green

# ── guards/auth.guard.ts ──────────────────────────────────────
@'
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const authGuard: CanActivateFn = () => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isLoggedIn()) {
    return true;
  }
  router.navigate(['/login']);
  return false;
};
'@ | Set-Content "$src\guards\auth.guard.ts" -Encoding ASCII
Write-Host "  [OK] auth.guard.ts" -ForegroundColor Green

# ── guards/role.guard.ts ──────────────────────────────────────
@'
import { inject } from '@angular/core';
import { CanActivateFn, Router, ActivatedRouteSnapshot } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const roleGuard: CanActivateFn = (route: ActivatedRouteSnapshot) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  const requiredRoles: string[] = route.data['roles'] || [];
  const userRole = authService.getRole();

  if (userRole && requiredRoles.includes(userRole)) {
    return true;
  }
  router.navigate(['/dashboard']);
  return false;
};
'@ | Set-Content "$src\guards\role.guard.ts" -Encoding ASCII
Write-Host "  [OK] role.guard.ts" -ForegroundColor Green

# ── login component HTML ──────────────────────────────────────
@'
<div class="login-wrapper">

  <!-- Left branding panel -->
  <div class="brand-panel">
    <div class="brand-content">
      <div class="brand-logo">BM</div>
      <h1 class="brand-name">BizMotion</h1>
      <p class="brand-sub">Accounting System</p>
      <div class="brand-features">
        <div class="feature">Role-Based Access Control</div>
        <div class="feature">Secure JWT Authentication</div>
        <div class="feature">Enterprise Accounting</div>
      </div>
    </div>
  </div>

  <!-- Right form panel -->
  <div class="form-panel">
    <div class="form-container">
      <h2 class="form-title">Welcome Back</h2>
      <p class="form-subtitle">Sign in to your account</p>

      <form [formGroup]="loginForm" (ngSubmit)="onLogin()">

        <!-- Username field -->
        <div class="field-group">
          <label class="field-label">Username</label>
          <input
            formControlName="username"
            type="text"
            class="field-input"
            [class.error]="f['username'].invalid && f['username'].touched"
            placeholder="Enter your username"
          />
          <span class="field-error" *ngIf="f['username'].invalid && f['username'].touched">
            Username is required
          </span>
        </div>

        <!-- Password field -->
        <div class="field-group">
          <label class="field-label">Password</label>
          <input
            formControlName="password"
            type="password"
            class="field-input"
            [class.error]="f['password'].invalid && f['password'].touched"
            placeholder="Enter your password"
          />
          <span class="field-error" *ngIf="f['password'].invalid && f['password'].touched">
            Password is required
          </span>
        </div>

        <!-- Server error -->
        <div class="server-error" *ngIf="serverError">
          {{ serverError }}
        </div>

        <!-- Submit button -->
        <button
          type="submit"
          class="submit-btn"
          [disabled]="loginForm.invalid || loading"
        >
          <span *ngIf="!loading">Sign In</span>
          <span *ngIf="loading">Signing in...</span>
        </button>

        <!-- Register link -->
        <p class="form-link">
          Don't have an account?
          <a routerLink="/register">Register here</a>
        </p>

      </form>
    </div>
  </div>

</div>
'@ | Set-Content "$src\auth\login\login.component.html" -Encoding ASCII
Write-Host "  [OK] login.component.html" -ForegroundColor Green

# ── login component CSS ───────────────────────────────────────
@'
/* ── Layout ─────────────────────────────────────────────────── */
.login-wrapper {
  display: flex;
  height: 100vh;
  font-family: 'Segoe UI', Arial, sans-serif;
}

/* ── Brand Panel (left) ──────────────────────────────────────── */
.brand-panel {
  flex: 1;
  background: linear-gradient(135deg, #1E3A5F 0%, #2980B9 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px;
}

.brand-content {
  text-align: center;
  color: white;
}

.brand-logo {
  width: 80px;
  height: 80px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
  font-weight: 700;
  margin: 0 auto 20px;
  letter-spacing: 2px;
}

.brand-name {
  font-size: 42px;
  font-weight: 700;
  margin: 0 0 8px;
  letter-spacing: 1px;
}

.brand-sub {
  font-size: 16px;
  color: rgba(255, 255, 255, 0.75);
  margin: 0 0 40px;
}

.brand-features {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.feature {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  padding: 10px 20px;
  font-size: 14px;
  color: rgba(255, 255, 255, 0.9);
}

/* ── Form Panel (right) ──────────────────────────────────────── */
.form-panel {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f8fafc;
  padding: 40px;
}

.form-container {
  width: 100%;
  max-width: 420px;
  background: white;
  border-radius: 16px;
  padding: 48px 40px;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.08);
}

.form-title {
  font-size: 28px;
  font-weight: 700;
  color: #1E3A5F;
  margin: 0 0 8px;
}

.form-subtitle {
  font-size: 15px;
  color: #64748b;
  margin: 0 0 32px;
}

/* ── Fields ──────────────────────────────────────────────────── */
.field-group {
  margin-bottom: 20px;
}

.field-label {
  display: block;
  font-size: 14px;
  font-weight: 600;
  color: #374151;
  margin-bottom: 6px;
}

.field-input {
  width: 100%;
  padding: 12px 16px;
  border: 1.5px solid #e2e8f0;
  border-radius: 8px;
  font-size: 15px;
  color: #1a202c;
  background: #f8fafc;
  outline: none;
  transition: border-color 0.2s;
  box-sizing: border-box;
}

.field-input:focus {
  border-color: #2980B9;
  background: white;
}

.field-input.error {
  border-color: #ef4444;
}

.field-error {
  display: block;
  font-size: 12px;
  color: #ef4444;
  margin-top: 4px;
}

/* ── Server error ────────────────────────────────────────────── */
.server-error {
  background: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 8px;
  padding: 12px 16px;
  font-size: 14px;
  color: #dc2626;
  margin-bottom: 16px;
}

/* ── Submit button ───────────────────────────────────────────── */
.submit-btn {
  width: 100%;
  padding: 14px;
  background: linear-gradient(135deg, #1E3A5F 0%, #2980B9 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s, transform 0.1s;
  margin-bottom: 20px;
}

.submit-btn:hover:not(:disabled) {
  opacity: 0.92;
  transform: translateY(-1px);
}

.submit-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

/* ── Link ────────────────────────────────────────────────────── */
.form-link {
  text-align: center;
  font-size: 14px;
  color: #64748b;
  margin: 0;
}

.form-link a {
  color: #2980B9;
  text-decoration: none;
  font-weight: 600;
}

.form-link a:hover {
  text-decoration: underline;
}

/* ── Responsive ──────────────────────────────────────────────── */
@media (max-width: 768px) {
  .brand-panel { display: none; }
  .form-panel { background: white; }
}
'@ | Set-Content "$src\auth\login\login.component.css" -Encoding ASCII
Write-Host "  [OK] login.component.css" -ForegroundColor Green

# ── login component TS ────────────────────────────────────────
@'
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent {

  loginForm: FormGroup;
  loading = false;
  serverError = '';

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {
    // Redirect if already logged in
    if (this.authService.isLoggedIn()) {
      this.redirectByRole();
    }

    this.loginForm = this.fb.group({
      username: ['', [Validators.required]],
      password: ['', [Validators.required]]
    });
  }

  // Shortcut to access form controls in template
  get f() { return this.loginForm.controls; }

  onLogin(): void {
    if (this.loginForm.invalid) return;

    this.loading = true;
    this.serverError = '';

    this.authService.login(this.loginForm.value).subscribe({
      next: (res) => {
        this.authService.saveTokens(res);
        this.redirectByRole();
      },
      error: () => {
        this.serverError = 'Invalid username or password';
        this.loading = false;
      }
    });
  }

  private redirectByRole(): void {
    const role = this.authService.getRole();
    if (role === 'SUPER_ADMIN' || role === 'ADMIN') {
      this.router.navigate(['/admin']);
    } else {
      this.router.navigate(['/dashboard']);
    }
  }
}
'@ | Set-Content "$src\auth\login\login.component.ts" -Encoding ASCII
Write-Host "  [OK] login.component.ts" -ForegroundColor Green

# ── register component HTML ───────────────────────────────────
@'
<div class="login-wrapper">

  <!-- Left branding panel -->
  <div class="brand-panel">
    <div class="brand-content">
      <div class="brand-logo">BM</div>
      <h1 class="brand-name">BizMotion</h1>
      <p class="brand-sub">Accounting System</p>
      <div class="brand-features">
        <div class="feature">Create your account</div>
        <div class="feature">Secure & Encrypted</div>
        <div class="feature">Start in seconds</div>
      </div>
    </div>
  </div>

  <!-- Right form panel -->
  <div class="form-panel">
    <div class="form-container">
      <h2 class="form-title">Create Account</h2>
      <p class="form-subtitle">Register to get started</p>

      <!-- Success message -->
      <div class="success-msg" *ngIf="successMsg">
        {{ successMsg }}
        <br><a routerLink="/login">Click here to login</a>
      </div>

      <form [formGroup]="registerForm" (ngSubmit)="onRegister()" *ngIf="!successMsg">

        <!-- Username -->
        <div class="field-group">
          <label class="field-label">Username</label>
          <input
            formControlName="username"
            type="text"
            class="field-input"
            [class.error]="f['username'].invalid && f['username'].touched"
            placeholder="Min 4 characters, no spaces"
          />
          <span class="field-error" *ngIf="f['username'].errors?.['required'] && f['username'].touched">
            Username is required
          </span>
          <span class="field-error" *ngIf="f['username'].errors?.['minlength'] && f['username'].touched">
            Username must be at least 4 characters
          </span>
          <span class="field-error" *ngIf="f['username'].errors?.['pattern'] && f['username'].touched">
            Username cannot contain spaces
          </span>
        </div>

        <!-- Email -->
        <div class="field-group">
          <label class="field-label">Email</label>
          <input
            formControlName="email"
            type="email"
            class="field-input"
            [class.error]="f['email'].invalid && f['email'].touched"
            placeholder="Enter your email"
          />
          <span class="field-error" *ngIf="f['email'].invalid && f['email'].touched">
            Enter a valid email address
          </span>
        </div>

        <!-- Password -->
        <div class="field-group">
          <label class="field-label">Password</label>
          <input
            formControlName="password"
            type="password"
            class="field-input"
            [class.error]="f['password'].invalid && f['password'].touched"
            placeholder="Min 8 chars, 1 number, 1 special char"
          />
          <span class="field-error" *ngIf="f['password'].errors?.['required'] && f['password'].touched">
            Password is required
          </span>
          <span class="field-error" *ngIf="f['password'].errors?.['minlength'] && f['password'].touched">
            Password must be at least 8 characters
          </span>
          <span class="field-error" *ngIf="f['password'].errors?.['pattern'] && f['password'].touched">
            Password must contain at least 1 number and 1 special character
          </span>
        </div>

        <!-- Confirm Password -->
        <div class="field-group">
          <label class="field-label">Confirm Password</label>
          <input
            formControlName="confirmPassword"
            type="password"
            class="field-input"
            [class.error]="f['confirmPassword'].invalid && f['confirmPassword'].touched"
            placeholder="Re-enter your password"
          />
          <span class="field-error" *ngIf="f['confirmPassword'].errors?.['required'] && f['confirmPassword'].touched">
            Please confirm your password
          </span>
          <span class="field-error" *ngIf="registerForm.errors?.['passwordMismatch'] && f['confirmPassword'].touched">
            Passwords do not match
          </span>
        </div>

        <!-- Server error -->
        <div class="server-error" *ngIf="serverError">{{ serverError }}</div>

        <!-- Submit -->
        <button type="submit" class="submit-btn" [disabled]="registerForm.invalid || loading">
          <span *ngIf="!loading">Create Account</span>
          <span *ngIf="loading">Creating account...</span>
        </button>

        <p class="form-link">
          Already have an account? <a routerLink="/login">Sign in</a>
        </p>

      </form>
    </div>
  </div>

</div>
'@ | Set-Content "$src\auth\register\register.component.html" -Encoding ASCII
Write-Host "  [OK] register.component.html" -ForegroundColor Green

# ── register component CSS ────────────────────────────────────
@'
/* Same layout as login — shared styles */
.login-wrapper { display: flex; height: 100vh; font-family: "Segoe UI", Arial, sans-serif; }
.brand-panel { flex: 1; background: linear-gradient(135deg, #1E3A5F 0%, #1E8449 100%); display: flex; align-items: center; justify-content: center; padding: 40px; }
.brand-content { text-align: center; color: white; }
.brand-logo { width: 80px; height: 80px; background: rgba(255,255,255,0.2); border-radius: 20px; display: flex; align-items: center; justify-content: center; font-size: 32px; font-weight: 700; margin: 0 auto 20px; }
.brand-name { font-size: 42px; font-weight: 700; margin: 0 0 8px; }
.brand-sub { font-size: 16px; color: rgba(255,255,255,0.75); margin: 0 0 40px; }
.brand-features { display: flex; flex-direction: column; gap: 12px; }
.feature { background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.2); border-radius: 8px; padding: 10px 20px; font-size: 14px; }
.form-panel { flex: 1; display: flex; align-items: center; justify-content: center; background: #f8fafc; padding: 40px; overflow-y: auto; }
.form-container { width: 100%; max-width: 420px; background: white; border-radius: 16px; padding: 40px; box-shadow: 0 4px 24px rgba(0,0,0,0.08); }
.form-title { font-size: 28px; font-weight: 700; color: #1E3A5F; margin: 0 0 8px; }
.form-subtitle { font-size: 15px; color: #64748b; margin: 0 0 24px; }
.field-group { margin-bottom: 16px; }
.field-label { display: block; font-size: 14px; font-weight: 600; color: #374151; margin-bottom: 6px; }
.field-input { width: 100%; padding: 11px 14px; border: 1.5px solid #e2e8f0; border-radius: 8px; font-size: 14px; outline: none; transition: border-color 0.2s; box-sizing: border-box; background: #f8fafc; }
.field-input:focus { border-color: #1E8449; background: white; }
.field-input.error { border-color: #ef4444; }
.field-error { display: block; font-size: 12px; color: #ef4444; margin-top: 3px; }
.server-error { background: #fef2f2; border: 1px solid #fecaca; border-radius: 8px; padding: 10px 14px; font-size: 13px; color: #dc2626; margin-bottom: 14px; }
.success-msg { background: #f0fdf4; border: 1px solid #86efac; border-radius: 8px; padding: 16px; font-size: 14px; color: #16a34a; text-align: center; }
.success-msg a { color: #1E3A5F; font-weight: 600; }
.submit-btn { width: 100%; padding: 13px; background: linear-gradient(135deg, #1E3A5F 0%, #1E8449 100%); color: white; border: none; border-radius: 8px; font-size: 15px; font-weight: 600; cursor: pointer; transition: opacity 0.2s; margin-bottom: 16px; }
.submit-btn:hover:not(:disabled) { opacity: 0.9; }
.submit-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.form-link { text-align: center; font-size: 14px; color: #64748b; margin: 0; }
.form-link a { color: #2980B9; text-decoration: none; font-weight: 600; }
@media (max-width: 768px) { .brand-panel { display: none; } }
'@ | Set-Content "$src\auth\register\register.component.css" -Encoding ASCII
Write-Host "  [OK] register.component.css" -ForegroundColor Green

# ── register component TS ────────────────────────────────────
@'
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule, AbstractControl, ValidationErrors } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../services/auth.service';

// Custom validator: passwords must match
function passwordMatchValidator(form: AbstractControl): ValidationErrors | null {
  const password = form.get('password')?.value;
  const confirm  = form.get('confirmPassword')?.value;
  return password === confirm ? null : { passwordMismatch: true };
}

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './register.component.html',
  styleUrls: ['./register.component.css']
})
export class RegisterComponent {

  registerForm: FormGroup;
  loading    = false;
  serverError = '';
  successMsg  = '';

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {
    this.registerForm = this.fb.group({
      username: ['', [
        Validators.required,
        Validators.minLength(4),
        Validators.pattern(/^\S+$/)
      ]],
      email: ['', [Validators.required, Validators.email]],
      password: ['', [
        Validators.required,
        Validators.minLength(8),
        Validators.pattern(/^(?=.*[0-9])(?=.*[!@#$%^&*])/)
      ]],
      confirmPassword: ['', Validators.required]
    }, { validators: passwordMatchValidator });
  }

  get f() { return this.registerForm.controls; }

  onRegister(): void {
    if (this.registerForm.invalid) return;

    this.loading = true;
    this.serverError = '';

    this.authService.register(this.registerForm.value).subscribe({
      next: () => {
        this.successMsg = 'Account created successfully!';
        this.loading = false;
      },
      error: (err) => {
        if (err.status === 409) {
          this.serverError = err.error?.error || 'Username or email already taken';
        } else {
          this.serverError = 'Registration failed. Please try again.';
        }
        this.loading = false;
      }
    });
  }
}
'@ | Set-Content "$src\auth\register\register.component.ts" -Encoding ASCII
Write-Host "  [OK] register.component.ts" -ForegroundColor Green

# ── admin dashboard ───────────────────────────────────────────
@'
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../services/auth.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div style="padding:40px;font-family:Arial">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:32px">
        <div>
          <h1 style="color:#1E3A5F;margin:0">Admin Dashboard</h1>
          <p style="color:#64748b;margin:4px 0 0">BizMotion Accounting System</p>
        </div>
        <button (click)="logout()"
          style="padding:10px 20px;background:#ef4444;color:white;border:none;border-radius:8px;cursor:pointer;font-size:14px;font-weight:600">
          Logout
        </button>
      </div>
      <div style="background:#dbeafe;border:1px solid #93c5fd;border-radius:12px;padding:20px">
        <h3 style="color:#1E3A5F;margin:0 0 8px">Logged in as: {{ role }}</h3>
        <p style="color:#1d4ed8;margin:0">Full admin access granted. User management and scope control available.</p>
      </div>
    </div>
  `
})
export class AdminDashboardComponent {
  role = this.authService.getRole();
  constructor(private authService: AuthService, private router: Router) {}
  logout() { this.authService.logout(); this.router.navigate(['/login']); }
}
'@ | Set-Content "$src\dashboard\admin\admin-dashboard.component.ts" -Encoding ASCII
Write-Host "  [OK] admin-dashboard.component.ts" -ForegroundColor Green

# ── user dashboard ────────────────────────────────────────────
@'
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../services/auth.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-user-dashboard',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div style="padding:40px;font-family:Arial">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:32px">
        <div>
          <h1 style="color:#1E3A5F;margin:0">User Dashboard</h1>
          <p style="color:#64748b;margin:4px 0 0">BizMotion Accounting System</p>
        </div>
        <button (click)="logout()"
          style="padding:10px 20px;background:#ef4444;color:white;border:none;border-radius:8px;cursor:pointer;font-size:14px;font-weight:600">
          Logout
        </button>
      </div>
      <div style="background:#dcfce7;border:1px solid #86efac;border-radius:12px;padding:20px">
        <h3 style="color:#15803d;margin:0 0 8px">Logged in as: {{ role }}</h3>
        <p style="color:#166534;margin:0">Welcome! You have standard user access.</p>
      </div>
    </div>
  `
})
export class UserDashboardComponent {
  role = this.authService.getRole();
  constructor(private authService: AuthService, private router: Router) {}
  logout() { this.authService.logout(); this.router.navigate(['/login']); }
}
'@ | Set-Content "$src\dashboard\user\user-dashboard.component.ts" -Encoding ASCII
Write-Host "  [OK] user-dashboard.component.ts" -ForegroundColor Green

# ── app.routes.ts ─────────────────────────────────────────────
@'
import { Routes } from '@angular/router';
import { authGuard } from './guards/auth.guard';
import { roleGuard } from './guards/role.guard';

export const routes: Routes = [
  { path: '', redirectTo: 'login', pathMatch: 'full' },
  {
    path: 'login',
    loadComponent: () => import('./auth/login/login.component').then(m => m.LoginComponent)
  },
  {
    path: 'register',
    loadComponent: () => import('./auth/register/register.component').then(m => m.RegisterComponent)
  },
  {
    path: 'admin',
    loadComponent: () => import('./dashboard/admin/admin-dashboard.component').then(m => m.AdminDashboardComponent),
    canActivate: [authGuard, roleGuard],
    data: { roles: ['SUPER_ADMIN', 'ADMIN'] }
  },
  {
    path: 'dashboard',
    loadComponent: () => import('./dashboard/user/user-dashboard.component').then(m => m.UserDashboardComponent),
    canActivate: [authGuard]
  },
  { path: '**', redirectTo: 'login' }
];
'@ | Set-Content "$src\app.routes.ts" -Encoding ASCII
Write-Host "  [OK] app.routes.ts" -ForegroundColor Green

# ── app.config.ts ─────────────────────────────────────────────
@'
import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { routes } from './app.routes';
import { jwtInterceptor } from './interceptors/jwt.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(withInterceptors([jwtInterceptor]))
  ]
};
'@ | Set-Content "$src\app.config.ts" -Encoding ASCII
Write-Host "  [OK] app.config.ts" -ForegroundColor Green

# ── app.component.ts ──────────────────────────────────────────
@'
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  template: '<router-outlet />'
})
export class AppComponent {}
'@ | Set-Content "$src\app.component.ts" -Encoding ASCII
Write-Host "  [OK] app.component.ts" -ForegroundColor Green

# ── global styles ─────────────────────────────────────────────
@'
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: "Segoe UI", Arial, sans-serif;
  background: #f8fafc;
  color: #1a202c;
}
'@ | Set-Content "src\styles.css" -Encoding ASCII
Write-Host "  [OK] styles.css" -ForegroundColor Green

Write-Host ""
Write-Host "All frontend files created!" -ForegroundColor Cyan
Write-Host "Now run: ng serve" -ForegroundColor Yellow
