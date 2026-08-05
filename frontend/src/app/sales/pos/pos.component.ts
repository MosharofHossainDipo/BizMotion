import { Component } from "@angular/core";
import { CommonModule } from "@angular/common";
import { Router } from "@angular/router";

@Component({
  selector: "app-pos",
  standalone: true,
  imports: [CommonModule],
  templateUrl: "./pos.component.html",
  styleUrls: ["./pos.component.css"]
})
export class PosComponent {
  constructor(private router: Router) {}
  goBack(): void { this.router.navigate(["/dashboard"]); }
}