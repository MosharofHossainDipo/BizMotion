import { Component } from "@angular/core";
import { CommonModule } from "@angular/common";
import { Router } from "@angular/router";

@Component({
  selector: "app-bills",
  standalone: true,
  imports: [CommonModule],
  templateUrl: "./bills.component.html",
  styleUrls: ["./bills.component.css"]
})
export class BillsComponent {
  constructor(private router: Router) {}
  goBack(): void { this.router.navigate(["/dashboard"]); }
}