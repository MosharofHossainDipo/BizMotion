import { Routes } from "@angular/router";
import { authGuard } from "./guards/auth.guard";

export const routes: Routes = [
  { path: "", redirectTo: "login", pathMatch: "full" },
  { path: "login",                 loadComponent: () => import("./auth/login/login.component").then(m => m.LoginComponent) },
  { path: "register",              loadComponent: () => import("./auth/register/register.component").then(m => m.RegisterComponent) },
  { path: "unauthorized",          loadComponent: () => import("./unauthorized/unauthorized.component").then(m => m.UnauthorizedComponent) },
  { path: "invoice-pdf/:id",       loadComponent: () => import("./sales/pdf-view/pdf-view.component").then(m => m.PdfViewComponent), canActivate: [authGuard] },

  {
    // AppShellComponent is the authenticated layout authGuard runs ONCE here
    path: "",
    loadComponent: () => import("./layout/app-shell/app-shell.component").then(m => m.AppShellComponent),
    canActivate: [authGuard],
    children: [
      { path: "dashboard", loadComponent: () => import("./dashboard/main/main-dashboard.component").then(m => m.MainDashboardComponent) },
      { path: "settings",  loadComponent: () => import("./settings/settings.component").then(m => m.SettingsComponent) },

      {
        path: "customers",
        children: [
          { path: "",          redirectTo: "list", pathMatch: "full" },
          { path: "add",       loadComponent: () => import("./customers/add/add-customer.component").then(m => m.AddCustomerComponent) },
          { path: "list",      loadComponent: () => import("./customers/list/list-customers.component").then(m => m.ListCustomersComponent) },
          { path: "companies", loadComponent: () => import("./customers/companies/companies.component").then(m => m.CompaniesComponent) },
          { path: "groups",    loadComponent: () => import("./customers/groups/groups.component").then(m => m.GroupsComponent) },
          { path: "files",     loadComponent: () => import("./customers/files/files.component").then(m => m.FilesComponent) },
        ]
      },

      {
        path: "accounting",
        children: [
          { path: "",                       redirectTo: "accounts", pathMatch: "full" },
          { path: "new-deposit",            loadComponent: () => import("./accounting/new-deposit/new-deposit.component").then(m => m.NewDepositComponent) },
          { path: "new-expense",            loadComponent: () => import("./accounting/new-expense/new-expense.component").then(m => m.NewExpenseComponent) },
          { path: "transfer",               loadComponent: () => import("./accounting/transfer/transfer.component").then(m => m.TransferComponent) },
          { path: "bills",                  loadComponent: () => import("./accounting/bills/bills.component").then(m => m.BillsComponent) },
          { path: "view-transactions",      loadComponent: () => import("./accounting/view-transactions/view-transactions.component").then(m => m.ViewTransactionsComponent) },
          { path: "uncleared-transactions", loadComponent: () => import("./accounting/uncleared-transactions/uncleared-transactions.component").then(m => m.UnclearedTransactionsComponent) },
          { path: "accounts",               loadComponent: () => import("./accounting/accounts/accounts.component").then(m => m.AccountsComponent) },
          { path: "new-account",            loadComponent: () => import("./accounting/new-account/new-account.component").then(m => m.NewAccountComponent) },
        ]
      },

      {
        path: "sales",
        children: [
          { path: "",                      redirectTo: "invoices", pathMatch: "full" },
          { path: "invoices",              loadComponent: () => import("./sales/invoices/invoices.component").then(m => m.InvoicesComponent) },
          { path: "new-invoice",           loadComponent: () => import("./sales/new-invoice/new-invoice.component").then(m => m.NewInvoiceComponent) },
	        { path: "edit-invoice/:id",      loadComponent: () => import("./sales/new-invoice/new-invoice.component").then(m => m.NewInvoiceComponent) },
          { path: "pos",                   loadComponent: () => import("./sales/pos/pos.component").then(m => m.PosComponent) },
          { path: "recurring-invoices",    loadComponent: () => import("./sales/recurring-invoices/recurring-invoices.component").then(m => m.RecurringInvoicesComponent) },
          { path: "new-recurring-invoice", loadComponent: () => import("./sales/new-recurring-invoice/new-recurring-invoice.component").then(m => m.NewRecurringInvoiceComponent) },
          { path: "quotes",                loadComponent: () => import("./sales/quotes/quotes.component").then(m => m.QuotesComponent) },
          { path: "create-new-quote",      loadComponent: () => import("./sales/create-new-quote/create-new-quote.component").then(m => m.CreateNewQuoteComponent) },
          { path: "payments",              loadComponent: () => import("./sales/payments/payments.component").then(m => m.PaymentsComponent) },
          { path: "invoices/:id",          loadComponent: () => import("./sales/view-invoice/view-invoice.component").then(m => m.ViewInvoiceComponent) },
        ]
      },
    ]
  },

  { path: "**", redirectTo: "login" }
];