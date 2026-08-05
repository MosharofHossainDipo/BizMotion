import { Component, OnInit, ChangeDetectorRef } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";
import { CustomerService, CustomerDto } from "../../services/customer.service";

interface CompanyRow { id:number; name:string; industry:string; country:string; customers:number; status:string; }

@Component({
  selector: "app-companies", standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: "./companies.component.html",
  styleUrls: ["./companies.component.css"]
})
export class CompaniesComponent implements OnInit {
  search=""; showAdd=false; loading=true; error="";
  newCompany={name:"",industry:"",country:"Bangladesh",website:""};
  companies: CompanyRow[]=[];

  constructor(private api: CustomerService, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void { this.load(); }

  load(): void {
    this.loading=true; this.error="";
    this.cdr.detectChanges();
    this.api.getAll().subscribe({
      next: (customers: CustomerDto[]) => {
        const map = new Map<string,{industry:string;count:number}>();
        customers.forEach(c => {
          const co = c.company?.trim();
          if (!co) return;
          if (map.has(co)) map.get(co)!.count++;
          else map.set(co, {industry: c.industry||"-", count:1});
        });
        this.companies = Array.from(map.entries()).map(([name,d],i) => ({
          id:i+1, name, industry:d.industry, country:"Bangladesh", customers:d.count, status:"Active"
        }));
        this.loading=false;
        this.cdr.detectChanges();
      },
      error: () => { this.error="Failed to load."; this.loading=false; this.cdr.detectChanges(); }
    });
  }

  get filtered() {
    const s=this.search.toLowerCase();
    return this.companies.filter(c=>c.name.toLowerCase().includes(s)||c.industry.toLowerCase().includes(s));
  }
  getInitials(n:string):string { return n.split(" ").map(w=>w[0].toUpperCase()).slice(0,2).join(""); }
  addCompany():void {
    if(!this.newCompany.name.trim())return;
    this.companies.push({id:Date.now(),name:this.newCompany.name,industry:this.newCompany.industry,country:this.newCompany.country,customers:0,status:"Active"});
    this.newCompany={name:"",industry:"",country:"Bangladesh",website:""};
    this.showAdd=false; this.cdr.detectChanges();
  }
  delete(id:number):void { if(confirm("Remove?")){ this.companies=this.companies.filter(c=>c.id!==id); this.cdr.detectChanges(); }}
}