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