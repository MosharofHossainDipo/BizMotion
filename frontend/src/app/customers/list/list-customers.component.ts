import { Component, OnInit, ChangeDetectorRef } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";
import { Router } from "@angular/router";
import { CustomerService, CustomerDto, CustomerImportResult } from "../../services/customer.service";
import { ScopeService } from "../../services/scope.service";

@Component({
  selector: "app-list-customers",
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: "./list-customers.component.html",
  styleUrls: ["./list-customers.component.css"]
})
export class ListCustomersComponent implements OnInit {

  search        = "";
  customers: CustomerDto[] = [];
  loading       = true;
  error         = "";
  deletingId: number | null = null;
  canCreate = false;
  canEdit   = false;
  canDelete = false;

  showImportModal = false;
  importing = false;
  importError = "";
  importResult: CustomerImportResult | null = null;
  selectedFile: File | null = null;
  isDragOver = false;

  get filtered() {
    if (!this.search.trim()) return this.customers;
    const s = this.search.toLowerCase();
    return this.customers.filter(c =>
      c.name.toLowerCase().includes(s) ||
      c.email.toLowerCase().includes(s) ||
      (c.customerCode||"").toLowerCase().includes(s) ||
      (c.company||"").toLowerCase().includes(s)
    );
  }

  constructor(
    private api:  CustomerService,
    private scope: ScopeService,
    private router: Router,
    private cdr:  ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.canCreate = this.scope.can("CREATE_CUSTOMER");
    this.canEdit   = this.scope.can("EDIT_CUSTOMER");
    this.canDelete = this.scope.can("DELETE_CUSTOMER");
    this.load();
  }

  load(): void {
    this.loading = true;
    this.error   = "";
    this.cdr.detectChanges();

    this.api.getAll().subscribe({
      next: (data) => {
        this.customers = Array.isArray(data) ? data : [];
        this.loading   = false;
        this.error     = "";
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.loading = false;
        if (err.status === 403) {
          this.error = "Access denied - no VIEW_CUSTOMER permission.";
        } else if (err.status === 0) {
          this.error = "Cannot connect to backend on port 8080.";
        } else {
          this.error = `Error ${err.status}: Failed to load customers.`;
        }
        this.cdr.detectChanges();
      }
    });
  }

  addNew(): void { this.router.navigate(["/customers/add"]); }

  toggleStatus(c: CustomerDto): void {
    this.api.setStatus(c.id, c.status !== "Active").subscribe({
      next: () => {
        c.status = c.status === "Active" ? "Inactive" : "Active";
        this.cdr.detectChanges();
      },
      error: () => alert("Failed to update status.")
    });
  }

  delete(c: CustomerDto): void {
    if (!confirm(`Delete "${c.name}"?`)) return;
    this.deletingId = c.id;
    this.api.delete(c.id).subscribe({
      next: () => {
        this.customers  = this.customers.filter(x => x.id !== c.id);
        this.deletingId = null;
        this.cdr.detectChanges();
      },
      error: () => { alert("Failed to delete."); this.deletingId = null; }
    });
  }

  getInitials(name: string): string {
    return (name||"?").split(" ").map((w:string) => w[0]?.toUpperCase()).slice(0,2).join("");
  }

  avatarClass(name: string): string {
    const map: Record<string,string> = {
      I:"av-blue", B:"av-purple", E:"av-orange",
      L:"av-green", S:"av-pink",  W:"av-teal"
    };
    return map[(name||"?").charAt(0).toUpperCase()] || "av-blue";
  }

  openImportModal(): void {
    this.showImportModal = true;
    this.selectedFile = null;
    this.importError = "";
    this.importResult = null;
  }

  closeImportModal(): void {
    if (this.importing) return;
    this.showImportModal = false;
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.selectedFile = input.files[0];
      this.importError = "";
    }
  }

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    this.isDragOver = true;
  }

  onDragLeave(event: DragEvent): void {
    event.preventDefault();
    this.isDragOver = false;
  }

  onDrop(event: DragEvent): void {
    event.preventDefault();
    this.isDragOver = false;
    if (event.dataTransfer?.files?.length) {
      this.selectedFile = event.dataTransfer.files[0];
      this.importError = "";
    }
  }

  downloadTemplate(): void {
    this.api.downloadTemplate().subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = "customer_import_template.csv";
        a.click();
        window.URL.revokeObjectURL(url);
      },
      error: () => alert("Failed to download template.")
    });
  }

  runImport(): void {
    if (!this.selectedFile) {
      this.importError = "Please select a file first.";
      this.cdr.detectChanges();
      return;
    }
    this.importing = true;
    this.importError = "";
    this.importResult = null;
    this.cdr.detectChanges();

    this.api.importCustomers(this.selectedFile).subscribe({
      next: (result) => {
        this.importing = false;
        this.importResult = result;
        this.cdr.detectChanges();
        if (result.imported > 0) this.load();
      },
      error: (err) => {
        this.importing = false;
        this.importError = err?.error?.error || err?.error?.message || "Import failed.";
        this.cdr.detectChanges();
      }
    });
  }
}