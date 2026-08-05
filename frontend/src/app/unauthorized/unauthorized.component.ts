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