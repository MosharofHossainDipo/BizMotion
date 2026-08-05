import { Component, OnInit } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";
import { Router } from "@angular/router";
import { CustomerService } from "../../services/customer.service";

@Component({
  selector: "app-add-customer",
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: "./add-customer.component.html",
  styleUrls: ["./add-customer.component.css"]
})
export class AddCustomerComponent implements OnInit {

  saving        = false;
  success       = false;
  serverError   = "";
  portalEnabled = false;
  customerCode  = "";

  form = {
    name: "", customerType: "Enterprise", industry: "",
    email: "", phone: "", company: "", website: "",
    address: "", customerGroup: "", preferredLanguage: "English (US)",
    notes: "", portalAccess: false, portalUsername: ""
  };

  customerTypes = ["Enterprise","SMB","Startup","Government","Non-Profit","Individual"];
  languages     = ["English (US)","English (UK)","Bengali","Arabic","French","Spanish"];

  constructor(public router: Router, private api: CustomerService) {}

  ngOnInit(): void {
    const year = new Date().getFullYear();
    const num  = Math.floor(Math.random() * 9999).toString().padStart(4, "0");
    this.customerCode = `CUS-${year}-${num}`;
  }

  togglePortal(): void {
    this.portalEnabled     = !this.portalEnabled;
    this.form.portalAccess = this.portalEnabled;
    if (this.portalEnabled && this.form.email) this.form.portalUsername = this.form.email;
  }

  onEmailChange(): void {
    if (this.portalEnabled) this.form.portalUsername = this.form.email;
  }

  cancel(): void { this.router.navigate(["/customers/list"]); }

  save(): void {
    if (!this.form.name.trim())  { alert("Full name is required.");  return; }
    if (!this.form.email.trim()) { alert("Email is required.");       return; }

    this.saving      = true;
    this.serverError = "";

    // Safety timeout: if API takes > 10s show error
    const timeout: any = setTimeout(() => {
      if (this.saving) {
        this.saving      = false;
        this.serverError = "Request timed out. Please check backend is running on port 8080.";
      }
    }, 10000);

    this.api.create(this.form).subscribe({
      next: (customer) => {
        clearTimeout(timeout);
        this.saving  = false;
        this.success = true;
        // Auto redirect to list after 2 seconds
        setTimeout(() => {
          this.router.navigate(["/customers/list"]);
        }, 2000);
      },
      error: (err) => {
        clearTimeout(timeout);
        this.saving = false;
        if (err.status === 0) {
          this.serverError = "Cannot connect to backend. Make sure the Spring Boot server is running on port 8080.";
        } else if (err.status === 409) {
          this.serverError = "A customer with this email already exists.";
        } else if (err.status === 403) {
          this.serverError = "You do not have permission to create customers.";
        } else if (err.status === 401) {
          this.serverError = "Session expired. Please login again.";
          setTimeout(() => this.router.navigate(["/login"]), 2000);
        } else {
          this.serverError = err?.error?.error || err?.error?.message || `Error ${err.status}: Failed to save customer.`;
        }
      }
    });
  }

  // ---- UI-only helper, purely additive — does not affect save()/backend logic ----
  get profileCompletion(): number {
    const trackedFields = [
      this.form.name,
      this.form.email,
      this.form.customerType,
      this.form.industry,
      this.form.company,
      this.form.customerGroup,
      this.form.phone,
      this.form.website,
      this.form.address,
      this.form.notes
    ];
    const filled = trackedFields.filter(v => (v ?? "").toString().trim().length > 0).length;
    return Math.round((filled / trackedFields.length) * 100);
  }
}