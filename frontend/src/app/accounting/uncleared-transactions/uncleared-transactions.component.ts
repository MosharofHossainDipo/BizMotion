import { Component } from "@angular/core";
import { CommonModule } from "@angular/common";
import { Router } from "@angular/router";

@Component({
  selector: "app-uncleared-transactions",
  standalone: true,
  imports: [CommonModule],
  templateUrl: "./uncleared-transactions.component.html",
  styleUrls: ["./uncleared-transactions.component.css"]
})
export class UnclearedTransactionsComponent {
  constructor(private router: Router) {}
  goBack(): void { this.router.navigate(["/dashboard"]); }
}