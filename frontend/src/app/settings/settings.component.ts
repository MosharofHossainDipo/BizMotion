import { Component, OnInit } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";
import { Router } from "@angular/router";
import { HttpClient, HttpHeaders } from "@angular/common/http";
import { AuthService }  from "../services/auth.service";
import { ScopeService } from "../services/scope.service";

interface UserDto  { id: number; username: string; email: string; roleName: string; roleId: number; active: boolean; }
interface RoleDto  { id: number; roleName: string; }
interface ScopeDto { id: number; name: string; }
interface RoleScopeMap { role: RoleDto; scopeNames: string[]; expanded: boolean; }

@Component({
  selector: "app-settings",
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: "./settings.component.html",
  styleUrls: ["./settings.component.css"]
})
export class SettingsComponent implements OnInit {
  private api = "http://localhost:8080/api";

  currentUsername = ""; currentRole = ""; userInitials = "";
  activeTab = "users";
  accountForm = { fullName: "", email: "" };
  savingAccount = false;

  users: UserDto[]  = []; roles: RoleDto[]  = []; scopes: ScopeDto[] = [];
  loadingUsers = false; userError = "";

  roleScopeMaps: RoleScopeMap[] = [];
  loadingRoleScopes = false;

  showAssignScope = false;
  selectedRoleForScope: RoleDto | null = null;
  selectedScopeIds: number[] = [];
  assigningScope = false;

  showAddScope = false; creatingScope = false;
  newScope = { scopeName: "", targetRoleId: 0 };

  showAddRole = false; newRoleName = ""; creatingRole = false;
  roleSuccessMsg = ""; roleErrorMsg = "";

  constructor(
    private http: HttpClient,
    private auth: AuthService,
    public  scopeSvc: ScopeService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.currentUsername      = this.auth.getUsername() || "User";
    this.currentRole          = this.auth.getRole() || "";
    this.userInitials         = this.getInitials(this.currentUsername);
    this.accountForm.fullName = this.currentUsername;

    if (this.scopeSvc.canSeeUserManagement()) { this.loadUsers(); this.loadRoles(); this.activeTab = "users"; }
    if (this.scopeSvc.canSeeScopesTab())      { this.loadScopes(); this.loadRoleScopeMaps(); }
  }

  goBack(): void { this.router.navigate(["/dashboard"]); }
  getInitials(n: string): string { return n.split(" ").map(w => w[0].toUpperCase()).slice(0,2).join(""); }
  private h(): HttpHeaders { return new HttpHeaders({ Authorization: `Bearer ${this.auth.getAccessToken()}` }); }
  saveAccount(): void { this.savingAccount = true; setTimeout(() => this.savingAccount = false, 800); }

  loadUsers(): void {
    this.loadingUsers = true; this.userError = "";
    this.http.get<UserDto[]>(`${this.api}/users`, { headers: this.h() }).subscribe({
      next: u => { this.users = u; this.loadingUsers = false; },
      error: () => { this.userError = "Failed to load users."; this.loadingUsers = false; }
    });
  }

  loadRoles(): void {
    this.http.get<RoleDto[]>(`${this.api}/roles`, { headers: this.h() }).subscribe({ next: r => { this.roles = r; } });
  }

  loadScopes(): void {
    this.http.get<ScopeDto[]>(`${this.api}/scopes`, { headers: this.h() }).subscribe({ next: s => { this.scopes = s; } });
  }

  loadRoleScopeMaps(): void {
    this.loadingRoleScopes = true;
    this.http.get<RoleDto[]>(`${this.api}/roles`, { headers: this.h() }).subscribe({
      next: roles => {
        const maps: RoleScopeMap[] = [];
        let pending = roles.length;
        if (pending === 0) { this.roleScopeMaps = []; this.loadingRoleScopes = false; return; }
        roles.forEach(role => {
          this.http.get<string[]>(`${this.api}/roles/${role.id}/scopes`, { headers: this.h() }).subscribe({
            next: scopeNames => {
              maps.push({ role, scopeNames, expanded: false });
              pending--;
              if (pending === 0) {
                this.roleScopeMaps = maps;
                this.loadingRoleScopes = false;
              }
            },
            error: () => { pending--; if (pending === 0) this.loadingRoleScopes = false; }
          });
        });
      }
    });
  }

  onRoleChange(u: UserDto): void {
    this.http.put(`${this.api}/users/${u.id}/role`, { roleId: Number(u.roleId) },
      { headers: this.h(), responseType: "text" }).subscribe({
      next: () => { u.roleName = this.roles.find(r => r.id == u.roleId)?.roleName || ""; },
      error: err => { alert(err?.error || "Failed to update role."); this.loadUsers(); }
    });
  }

  onStatusChange(u: UserDto): void {
    const isActive = String(u.active) === "true";
    u.active = isActive;
    this.http.put(`${this.api}/users/${u.id}/status`, { active: isActive },
      { headers: this.h(), responseType: "text" }).subscribe({
      error: () => { alert("Failed to update status."); this.loadUsers(); }
    });
  }

  deleteUser(u: UserDto): void {
    if (!confirm(`Delete "${u.username}"?`)) return;
    this.http.delete(`${this.api}/users/${u.id}`, { headers: this.h(), responseType: "text" }).subscribe({
      next: () => { this.users = this.users.filter(x => x.id !== u.id); },
      error: err => { alert(err?.error || "Failed to delete."); }
    });
  }

  openAssignScope(rsm: RoleScopeMap): void {
    this.selectedRoleForScope = rsm.role;
    this.selectedScopeIds = this.scopes.filter(s => rsm.scopeNames.includes(s.name)).map(s => s.id);
    this.showAssignScope = true;
  }

  toggleScopeSelection(scopeId: number): void {
    const idx = this.selectedScopeIds.indexOf(scopeId);
    if (idx === -1) this.selectedScopeIds.push(scopeId);
    else this.selectedScopeIds.splice(idx, 1);
  }

  isScopeSelected(scopeId: number): boolean { return this.selectedScopeIds.includes(scopeId); }

  saveAssignScope(): void {
    if (!this.selectedRoleForScope) return;
    this.assigningScope = true;
    this.http.put(`${this.api}/roles/${this.selectedRoleForScope.id}/scopes`,
      { scopeIds: this.selectedScopeIds }, { headers: this.h(), responseType: "text" }).subscribe({
      next: () => { this.assigningScope = false; this.showAssignScope = false; this.loadRoleScopeMaps(); },
      error: err => { alert(err?.error || "Failed."); this.assigningScope = false; }
    });
  }

  createScope(): void {
    if (!this.newScope.scopeName.trim() || !this.newScope.targetRoleId) { alert("Fill all fields."); return; }
    this.creatingScope = true;
    this.http.post<ScopeDto>(`${this.api}/scopes`,
      { scopeName: this.newScope.scopeName.toUpperCase().trim(), targetRoleId: Number(this.newScope.targetRoleId) },
      { headers: this.h() }).subscribe({
      next: s => { this.scopes.push(s); this.newScope = { scopeName: "", targetRoleId: 0 }; this.showAddScope = false; this.creatingScope = false; this.loadRoleScopeMaps(); },
      error: err => { alert(err?.error?.error || "Failed."); this.creatingScope = false; }
    });
  }

  deleteScope(s: ScopeDto): void {
    if (!confirm(`Delete scope "${s.name}"?`)) return;
    this.http.delete(`${this.api}/scopes/${s.id}`, { headers: this.h(), responseType: "text" }).subscribe({
      next: () => { this.scopes = this.scopes.filter(x => x.id !== s.id); this.loadRoleScopeMaps(); },
      error: () => { alert("Failed."); }
    });
  }

  createRole(): void {
    if (!this.newRoleName.trim()) { this.roleErrorMsg = "Enter a role name."; return; }
    this.creatingRole = true; this.roleSuccessMsg = ""; this.roleErrorMsg = "";
    this.http.post<RoleDto>(`${this.api}/roles`, { roleName: this.newRoleName.toUpperCase().trim() },
      { headers: this.h() }).subscribe({
      next: r => {
        this.roles.push(r); this.newRoleName = ""; this.showAddRole = false; this.creatingRole = false;
        this.roleSuccessMsg = `Role "${r.roleName}" created successfully!`;
        this.loadRoleScopeMaps();
        setTimeout(() => this.roleSuccessMsg = "", 4000);
      },
      error: err => { this.roleErrorMsg = err?.error?.error || "Failed."; this.creatingRole = false; setTimeout(() => this.roleErrorMsg = "", 4000); }
    });
  }

  isBuiltInRole(roleName: string): boolean { return ["SUPER_ADMIN","ADMIN","ACCOUNTANT","VIEWER"].includes(roleName); }

  getRoleScopeCountByRoleId(roleId: number): number {
    const rsm = this.roleScopeMaps.find(r => r.role.id === roleId);
    return rsm ? rsm.scopeNames.length : 0;
  }

  getAssignedScopesInCat(rsm: RoleScopeMap, catScopes: ScopeDto[]): ScopeDto[] {
    return catScopes.filter(s => rsm.scopeNames.includes(s.name));
  }

  getScopeCategory(scopeName: string): string {
    if (["CREATE_USER","EDIT_USER","DELETE_USER","VIEW_USER","ASSIGN_ROLE"].includes(scopeName)) return "User Management";
    if (["CREATE_INVOICE","EDIT_INVOICE","DELETE_INVOICE","VIEW_INVOICE","APPROVE_INVOICE"].includes(scopeName)) return "Invoice";
    if (["CREATE_PAYMENT","VIEW_PAYMENT","PROCESS_PAYMENT","REFUND_PAYMENT"].includes(scopeName)) return "Payment";
    if (["VIEW_LEDGER","POST_JOURNAL_ENTRY","CLOSE_PERIOD"].includes(scopeName)) return "Ledger";
    if (["VIEW_REPORT","EXPORT_REPORT","GENERATE_REPORT"].includes(scopeName)) return "Report";
    if (["CREATE_CUSTOMER","EDIT_CUSTOMER","VIEW_CUSTOMER","DELETE_CUSTOMER"].includes(scopeName)) return "Customer";
    if (["VIEW_AUDIT_LOG","MANAGE_SETTINGS"].includes(scopeName)) return "System";
    return "Other";
  }

  getScopesByCategory(): { category: string; scopes: ScopeDto[] }[] {
    const map = new Map<string, ScopeDto[]>();
    this.scopes.forEach(s => {
      const cat = this.getScopeCategory(s.name);
      if (!map.has(cat)) map.set(cat, []);
      map.get(cat)!.push(s);
    });
    return Array.from(map.entries()).map(([category, scopes]) => ({ category, scopes }));
  }
}