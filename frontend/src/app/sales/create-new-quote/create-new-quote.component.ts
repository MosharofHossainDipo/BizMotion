import { Component } from "@angular/core";
import { CommonModule } from "@angular/common";
import { Router } from "@angular/router";

@Component({
  selector: "app-create-new-quote",
  standalone: true,
  imports: [CommonModule],
  templateUrl: "./create-new-quote.component.html",
  styleUrls: ["./create-new-quote.component.css"]
})
export class CreateNewQuoteComponent {
  constructor(private router: Router) {}
  goBack(): void { this.router.navigate(["/dashboard"]); }
}