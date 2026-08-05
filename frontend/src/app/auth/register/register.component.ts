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
  loading = false; serverError = ""; showSuccess = false; countdown = 3;
  private countdownInterval: any;

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
      next: () => {
        this.loading = false;
        this.showSuccess = true;
        this.countdown = 3;
        this.countdownInterval = setInterval(() => {
          this.countdown--;
          if (this.countdown === 0) {
            clearInterval(this.countdownInterval);
            this.router.navigate(["/login"]);
          }
        }, 1000);
      },
      error: err => {
        this.serverError = err.status === 409 ? (err.error?.error || "Username or email taken") : "Registration failed.";
        this.loading = false;
      }
    });
  }

  goToLogin(): void {
    clearInterval(this.countdownInterval);
    this.router.navigate(["/login"]);
  }
}