export interface NavItem {
  label:     string;
  icon:      string;
  route:     string;
  scopes:    string[];
  children?: NavItem[];
}

export const NAV_ITEMS: NavItem[] = [
  { label: "Dashboard",  icon: "", route: "/dashboard", scopes: [] },
  {
    label: "Customers", icon: "", route: "/customers/list", scopes: [],
    children: [
      { label: "Add Customer",   icon: "", route: "/customers/add",       scopes: [] },
      { label: "List Customers", icon: "", route: "/customers/list",      scopes: [] },
      { label: "Companies",      icon: "", route: "/customers/companies", scopes: [] },
      { label: "Groups",         icon: "", route: "/customers/groups",    scopes: [] },
      { label: "Files",          icon: "", route: "/customers/files",     scopes: [] },
    ]
  },
  {
    label: "Accounting", icon: "", route: "/accounting/accounts", scopes: [],
    children: [
      { label: "New Deposit",            icon: "", route: "/accounting/new-deposit",            scopes: [] },
      { label: "New Expense",            icon: "", route: "/accounting/new-expense",            scopes: [] },
      { label: "Transfer",               icon: "", route: "/accounting/transfer",               scopes: [] },
      { label: "Bills",                  icon: "", route: "/accounting/bills",                  scopes: [] },
      { label: "View Transactions",      icon: "", route: "/accounting/view-transactions",      scopes: [] },
      { label: "Uncleared Transactions", icon: "", route: "/accounting/uncleared-transactions", scopes: [] },
      { label: "Accounts",               icon: "", route: "/accounting/accounts",               scopes: [] },
      { label: "New Account",            icon: "", route: "/accounting/new-account",            scopes: [] },
    ]
  },
  {
    label: "Sales", icon: "", route: "/sales/invoices", scopes: [],
    children: [
      { label: "Invoices",              icon: "", route: "/sales/invoices",              scopes: [] },
      { label: "New Invoice",           icon: "", route: "/sales/new-invoice",           scopes: [] },
      { label: "POS",                   icon: "", route: "/sales/pos",                   scopes: [] },
      { label: "Recurring Invoices",    icon: "", route: "/sales/recurring-invoices",    scopes: [] },
      { label: "New Recurring Invoice", icon: "", route: "/sales/new-recurring-invoice", scopes: [] },
      { label: "Quotes",                icon: "", route: "/sales/quotes",                scopes: [] },
      { label: "Create New Quote",      icon: "", route: "/sales/create-new-quote",      scopes: [] },
      { label: "Payments",              icon: "", route: "/sales/payments",              scopes: [] },
    ]
  },
  { label: "Invoices",   icon: "", route: "/sales/invoices",  scopes: [] },
  { label: "Payments",   icon: "", route: "/sales/payments",  scopes: [] },
  {
    label: "Reports", icon: "", route: "#", scopes: [],
    children: [
      { label: "View Reports", icon: "", route: "#", scopes: [] },
      { label: "Generate",     icon: "", route: "#", scopes: [] },
      { label: "Export",       icon: "", route: "#", scopes: [] },
    ]
  },
  { label: "Support",    icon: "", route: "#", scopes: [] },
  { label: "HRM",        icon: "", route: "#", scopes: [] },
  { label: "Documents",  icon: "", route: "#", scopes: [] },
  { label: "Tasks",      icon: "", route: "#", scopes: [] },
  { label: "Calendar",   icon: "", route: "#", scopes: [] },
  { label: "Audit Logs", icon: "", route: "#", scopes: [] },
];