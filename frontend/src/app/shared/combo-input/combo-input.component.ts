import { Component, Input, forwardRef, ElementRef, HostListener } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule, ControlValueAccessor, NG_VALUE_ACCESSOR } from "@angular/forms";

@Component({
  selector: "app-combo-input",
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: "./combo-input.component.html",
  styleUrls: ["./combo-input.component.css"],
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => ComboInputComponent),
    multi: true
  }]
})
export class ComboInputComponent implements ControlValueAccessor {
  @Input() options: string[] = [];
  @Input() placeholder = "";

  value = "";
  open = false;
  disabled = false;

  private onChange: (val: string) => void = () => {};
  private onTouched: () => void = () => {};

  constructor(private elRef: ElementRef) {}

  get filteredOptions(): string[] {
    if (!this.value) return this.options;
    const q = this.value.toLowerCase();
    return this.options.filter(o => o.toLowerCase().includes(q));
  }

  writeValue(val: string): void { this.value = val || ""; }
  registerOnChange(fn: any): void { this.onChange = fn; }
  registerOnTouched(fn: any): void { this.onTouched = fn; }
  setDisabledState(isDisabled: boolean): void { this.disabled = isDisabled; }

  onInput(val: string): void {
    this.value = val;
    this.onChange(this.value);
    this.open = true;
  }

  toggleOpen(): void {
    if (this.disabled) return;
    this.open = !this.open;
  }

  selectOption(opt: string): void {
    this.value = opt;
    this.onChange(this.value);
    this.open = false;
    this.onTouched();
  }

  onFocus(): void { this.open = true; }

  @HostListener("document:click", ["$event"])
  handleOutsideClick(event: MouseEvent): void {
    if (!this.elRef.nativeElement.contains(event.target)) {
      this.open = false;
      this.onTouched();
    }
  }
}