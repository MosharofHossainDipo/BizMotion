import { Injectable } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { Observable } from "rxjs";

export interface CustomerDto {
  id:                number;
  customerCode:      string;
  name:              string;
  customerType:      string;
  industry:          string;
  email:             string;
  phone:             string;
  company:           string;
  website:           string;
  address:           string;
  customerGroup:     string;
  preferredLanguage: string;
  notes:             string;
  portalAccess:      boolean;
  portalUsername:    string;
  status:            string;
  createdAt:         string;
}

export interface CreateCustomerRequest {
  name:               string;
  customerType:       string;
  email:              string;
  industry?:          string;
  phone?:             string;
  company?:           string;
  website?:           string;
  address?:           string;
  customerGroup?:     string;
  preferredLanguage?: string;
  notes?:             string;
  portalAccess?:      boolean;
  portalUsername?:    string;
}

export interface CustomerImportResult {
  totalRows:  number;
  imported:   number;
  duplicates: number;
  invalid:    number;
  errors:     string[];
}

@Injectable({ providedIn: "root" })
export class CustomerService {

  private api = "http://localhost:8080/api/customers";

  constructor(private http: HttpClient) {}

  // No manual headers needed — JWT interceptor handles Authorization header automatically

  getAll(): Observable<CustomerDto[]> {
    return this.http.get<CustomerDto[]>(this.api);
  }

  getById(id: number): Observable<CustomerDto> {
    return this.http.get<CustomerDto>(`${this.api}/${id}`);
  }

  create(req: CreateCustomerRequest): Observable<CustomerDto> {
    return this.http.post<CustomerDto>(this.api, req);
  }

  update(id: number, req: CreateCustomerRequest): Observable<CustomerDto> {
    return this.http.put<CustomerDto>(`${this.api}/${id}`, req);
  }

  setStatus(id: number, active: boolean): Observable<string> {
    return this.http.put(`${this.api}/${id}/status`, { active },
      { responseType: "text" });
  }

  delete(id: number): Observable<string> {
    return this.http.delete(`${this.api}/${id}`,
      { responseType: "text" });
  }

  importCustomers(file: File): Observable<CustomerImportResult> {
    const formData = new FormData();
    formData.append("file", file);
    return this.http.post<CustomerImportResult>(`${this.api}/import`, formData);
  }

  downloadTemplate(): Observable<Blob> {
    return this.http.get(`${this.api}/import/template`, { responseType: "blob" });
  }
}