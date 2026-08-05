import { Component } from "@angular/core";
import { CommonModule } from "@angular/common";
import { Router } from "@angular/router";

@Component({
  selector: "app-recurring-invoices",
  standalone: true,
  imports: [CommonModule],
  templateUrl: "./recurring-invoices.component.html",
  styleUrls: ["./recurring-invoices.component.css"]
})
export class RecurringInvoicesComponent {
  constructor(private router: Router) {}
  goBack(): void { this.router.navigate(["/dashboard"]); }
}