import { Component } from "@angular/core";
import { CommonModule } from "@angular/common";
import { Router } from "@angular/router";

@Component({
  selector: "app-quotes",
  standalone: true,
  imports: [CommonModule],
  templateUrl: "./quotes.component.html",
  styleUrls: ["./quotes.component.css"]
})
export class QuotesComponent {
  constructor(private router: Router) {}
  goBack(): void { this.router.navigate(["/dashboard"]); }
}