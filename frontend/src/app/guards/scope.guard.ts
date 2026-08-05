import { inject } from "@angular/core";
import { CanActivateFn, Router, ActivatedRouteSnapshot } from "@angular/router";
import { ScopeService } from "../services/scope.service";

/**
 * Scope-based route guard.
 * Add to route: canActivate: [authGuard, scopeGuard]
 * Route data:   data: { scopes: ["MANAGE_SETTINGS"] }
 *
 * SUPER_ADMIN bypasses all scope checks automatically.
 */
export const scopeGuard: CanActivateFn = (route: ActivatedRouteSnapshot) => {
  const scopeService = inject(ScopeService);
  const router       = inject(Router);

  const required: string[] = route.data["scopes"] || [];

  if (required.length === 0) return true;
  if (scopeService.isSuperAdmin()) return true;
  if (scopeService.hasAnyScope(required)) return true;

  router.navigate(["/unauthorized"]);
  return false;
};