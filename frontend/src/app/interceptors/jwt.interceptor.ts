import { HttpInterceptorFn, HttpErrorResponse } from "@angular/common/http";
import { inject } from "@angular/core";
import { catchError, switchMap, throwError } from "rxjs";
import { AuthService } from "../services/auth.service";
import { Router } from "@angular/router";

export const jwtInterceptor: HttpInterceptorFn = (req, next) => {
  const auth   = inject(AuthService);
  const router = inject(Router);
  const token  = auth.getAccessToken();

  // Attach token to every request
  const authReq = token
    ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
    : req;

  return next(authReq).pipe(
    catchError((err: HttpErrorResponse) => {
      if (err.status === 401) {
        const rt = auth.getRefreshToken();
        if (rt) {
          return auth.refresh(rt).pipe(
            switchMap(res => {
              const retryReq = req.clone({
                setHeaders: { Authorization: `Bearer ${res.accessToken}` }
              });
              return next(retryReq);
            }),
            catchError(() => {
              auth.logout();
              router.navigate(["/login"]);
              return throwError(() => err);
            })
          );
        }
        auth.logout();
        router.navigate(["/login"]);
      }
      return throwError(() => err);
    })
  );
};