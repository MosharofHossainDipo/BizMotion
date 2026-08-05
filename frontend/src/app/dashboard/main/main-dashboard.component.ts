import { Component, OnInit, ChangeDetectorRef } from "@angular/core";
import { CommonModule } from "@angular/common";
import { Router } from "@angular/router";
import { ScopeService } from "../../services/scope.service";
import { CustomerService } from "../../services/customer.service";

@Component({
  selector: "app-main-dashboard",
  standalone: true,
  imports: [CommonModule],
  templateUrl: "./main-dashboard.component.html",
  styleUrls: ["./main-dashboard.component.css"]
})
export class MainDashboardComponent implements OnInit {

  canEdit=false; canCreate=false; canDelete=false; canViewReports=true;
  totalCustomers=0; totalCompanies=0; loadingStats=false;
  recentCustomers: any[]=[];

  latestExpenses=[
    {date:"11/06/2026",desc:"Shahiur Bua May 26 salary",amount:"5,500"},
    {date:"11/06/2026",desc:"Lawyer payment for audit",amount:"25,000"},
    {date:"10/06/2026",desc:"Arafat bhai may 26 salary",amount:"35,000"},
  ];
  expenseCategories=[
    {name:"As Salary",amount:"18,206,088",percent:"85%",color:"#003874"},
    {name:"Misc",amount:"6,253,292",percent:"40%",color:"#505f76"},
    {name:"Server Bill",amount:"4,133,435",percent:"25%",color:"#5e2b00"},
    {name:"Office Rent",amount:"3,144,675",percent:"20%",color:"#1a4f95"},
  ];
  accountBalances=[
    {name:"BRAC Bank Limited",amount:"BDT 1.2M"},
    {name:"Connect Informatics",amount:"BDT 450K"},
    {name:"Petty cash",amount:"BDT 12K"},
    {name:"Payoneer Account",amount:"BDT 85K"},
  ];
  dayNames=["SUN","MON","TUE","WED","THU","FRI","SAT"];
  calDays=Array.from({length:20},(_,i)=>i+1);

  constructor(
    public  scope: ScopeService,
    private cSvc:  CustomerService,
    private router:Router,
    private cdr:   ChangeDetectorRef
  ){}

  ngOnInit():void{
    this.canCreate=!this.scope.isViewer();
    this.canEdit=!this.scope.isViewer();
    this.canDelete=this.scope.canDelete();
    this.loadStats();
  }

  loadStats():void{
    this.loadingStats=true;
    this.cdr.detectChanges();
    this.cSvc.getAll().subscribe({
      next:(customers)=>{
        this.totalCustomers=customers.length;
        const cos=new Set(customers.map((c:any)=>c.company).filter((c:any)=>c&&c.trim()!==""));
        this.totalCompanies=cos.size;
        this.recentCustomers=[...customers].reverse().slice(0,3);
        this.loadingStats=false;
        this.cdr.detectChanges();
      },
      error:()=>{
        this.totalCustomers=0; this.totalCompanies=0;
        this.recentCustomers=[]; this.loadingStats=false;
        this.cdr.detectChanges();
      }
    });
  }

  getInitials(name:string):string{ return (name||"?").split(" ").map((w:string)=>w[0]?.toUpperCase()).slice(0,2).join(""); }
  avatarClass(name:string):string{
    const map:Record<string,string>={I:"blue-av",B:"purple-av",E:"orange-av",L:"green-av",S:"pink-av",W:"teal-av"};
    return map[(name||"?").charAt(0).toUpperCase()]||"blue-av";
  }
  navigateTo(route:string):void{ this.router.navigate([route]); }
}