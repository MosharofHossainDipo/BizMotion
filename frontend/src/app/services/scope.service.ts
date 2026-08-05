import { Injectable } from "@angular/core";
import { AuthService } from "./auth.service";

@Injectable({ providedIn: "root" })
export class ScopeService {
  constructor(private auth: AuthService) {}

  hasScope(s: string):         boolean { return this.auth.getScopes().includes(s); }
  hasAnyScope(ss: string[]):   boolean { return ss.length === 0 || ss.some(s => this.auth.getScopes().includes(s)); }
  isSuperAdmin(): boolean { return this.auth.getRole() === "SUPER_ADMIN"; }
  isAdmin():      boolean { return this.auth.getRole() === "ADMIN"; }
  isAccountant(): boolean { return this.auth.getRole() === "ACCOUNTANT"; }
  isViewer():     boolean { return this.auth.getRole() === "VIEWER"; }

  can(scope: string):   boolean { return this.isSuperAdmin() || this.hasScope(scope); }
  canCreate():          boolean { return !this.isViewer(); }
  canEdit():            boolean { return !this.isViewer(); }
  canDelete():          boolean { return this.isSuperAdmin() || this.isAdmin(); }
  canManageUsers():     boolean { return this.can("EDIT_USER"); }
  canDeleteUsers():     boolean { return this.can("DELETE_USER"); }
  canSeeUserManagement(): boolean { return this.can("VIEW_USER"); }
  canSeeScopesTab():    boolean { return this.can("MANAGE_SETTINGS"); }
}