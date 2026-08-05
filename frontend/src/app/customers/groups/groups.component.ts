import { Component, OnInit, ChangeDetectorRef } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";
import { CustomerService, CustomerDto } from "../../services/customer.service";

interface GroupRow { id:number; name:string; description:string; members:number; color:string; }

@Component({
  selector: "app-groups", standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: "./groups.component.html",
  styleUrls: ["./groups.component.css"]
})
export class GroupsComponent implements OnInit {
  showAdd=false; loading=true; error="";
  newGroup={name:"",description:"",color:"#003874"};
  groups: GroupRow[]=[];
  private colorMap: Record<string,string> = {
    VIP:"#7c3aed",Regular:"#003874",Wholesale:"#059669",New:"#d97706",Enterprise:"#0891b2"
  };

  constructor(private api: CustomerService, private cdr: ChangeDetectorRef) {}
  ngOnInit(): void { this.load(); }

  load(): void {
    this.loading=true; this.error="";
    this.cdr.detectChanges();
    this.api.getAll().subscribe({
      next: (customers: CustomerDto[]) => {
        const map=new Map<string,number>();
        customers.forEach(c=>{ const g=c.customerGroup?.trim(); if(g) map.set(g,(map.get(g)||0)+1); });
        if(map.size>0) {
          this.groups=Array.from(map.entries()).map(([name,count],i)=>({
            id:i+1,name,description:`${name} customer segment`,members:count,color:this.colorMap[name]||"#003874"
          }));
        } else {
          this.groups=[
            {id:1,name:"VIP",description:"High-value customers",members:0,color:"#7c3aed"},
            {id:2,name:"Regular",description:"Standard customer tier",members:0,color:"#003874"},
            {id:3,name:"Wholesale",description:"Bulk purchase customers",members:0,color:"#059669"},
          ];
        }
        this.loading=false;
        this.cdr.detectChanges();
      },
      error: ()=>{ this.error="Failed to load."; this.loading=false; this.cdr.detectChanges(); }
    });
  }

  addGroup():void {
    if(!this.newGroup.name.trim())return;
    this.groups.push({id:Date.now(),...this.newGroup,members:0});
    this.newGroup={name:"",description:"",color:"#003874"};
    this.showAdd=false; this.cdr.detectChanges();
  }
  delete(id:number):void { if(confirm("Delete?")){ this.groups=this.groups.filter(g=>g.id!==id); this.cdr.detectChanges(); }}
}