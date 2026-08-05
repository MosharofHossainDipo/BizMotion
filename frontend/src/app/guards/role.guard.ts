import { inject } from "@angular/core";
import { CanActivateFn, Router, ActivatedRouteSnapshot } from "@angular/router";
import { AuthService } from "../services/auth.service";

export const roleGuard: CanActivateFn = (route: ActivatedRouteSnapshot) => {
  const auth   = inject(AuthService);
  const router = inject(Router);
  const roles: string[] = route.data["roles"] || [];
  const userRole = auth.getRole();
  if (userRole && roles.includes(userRole)) return true;
  router.navigate(["/dashboard"]);
  return false;
};