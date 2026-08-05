import { Component } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";

@Component({ selector:"app-files", standalone:true, imports:[CommonModule,FormsModule], templateUrl:"./files.component.html", styleUrls:["./files.component.css"] })
export class FilesComponent {
  search="";
  files=[
    {id:1,name:"IMS_Contract_2026.pdf",    type:"PDF", size:"2.4 MB",customer:"IMS Ltd.",   date:"07/04/2026",icon:"pdf"},
    {id:2,name:"Linnex_Invoice_June.xlsx", type:"XLSX",size:"1.1 MB",customer:"Linnex",     date:"09/06/2026",icon:"xls"},
    {id:3,name:"SOMATEC_Agreement.docx",   type:"DOCX",size:"0.8 MB",customer:"SOMATEC",    date:"09/06/2026",icon:"doc"},
    {id:4,name:"ETI_PurchaseOrder.pdf",    type:"PDF", size:"1.6 MB",customer:"ETI Ltd.",   date:"01/06/2026",icon:"pdf"},
    {id:5,name:"WhiteHorse_Report.pdf",    type:"PDF", size:"3.2 MB",customer:"White Horse",date:"07/06/2026",icon:"pdf"},
  ];
  get filtered(){const s=this.search.toLowerCase();return this.files.filter(f=>f.name.toLowerCase().includes(s)||f.customer.toLowerCase().includes(s));}
  delete(id:number):void{if(confirm("Delete this file?"))this.files=this.files.filter(f=>f.id!==id);}
  iconColor(i:string):string{return i==="pdf"?"#ef4444":i==="xls"?"#16a34a":"#1d4ed8";}
  iconBg(i:string):string{return i==="pdf"?"#fef2f2":i==="xls"?"#f0fdf4":"#eff6ff";}
}