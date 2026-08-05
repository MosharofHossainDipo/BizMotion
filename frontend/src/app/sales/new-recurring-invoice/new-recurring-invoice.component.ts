import { Component } from "@angular/core";
import { CommonModule } from "@angular/common";
import { Router } from "@angular/router";

@Component({
  selector: "app-new-recurring-invoice",
  standalone: true,
  imports: [CommonModule],
  templateUrl: "./new-recurring-invoice.component.html",
  styleUrls: ["./new-recurring-invoice.component.css"]
})
export class NewRecurringInvoiceComponent {
  constructor(private router: Router) {}
  goBack(): void { this.router.navigate(["/dashboard"]); }
}