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