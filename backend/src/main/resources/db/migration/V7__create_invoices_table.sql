CREATE TABLE invoices (
    id                 NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_number     VARCHAR2(50)   NOT NULL,
    customer_id        NUMBER         NOT NULL,
    billing_address    VARCHAR2(1000),
    status             VARCHAR2(20)   DEFAULT 'Draft' NOT NULL,
    invoice_type       VARCHAR2(20)   DEFAULT 'Onetime' NOT NULL,
    currency           VARCHAR2(10)   DEFAULT 'BDT' NOT NULL,
    payment_terms      VARCHAR2(100),
    invoice_date       DATE           NOT NULL,
    due_date           DATE,
    subtotal           NUMBER(14,2)   DEFAULT 0 NOT NULL,
    tax_total          NUMBER(14,2)   DEFAULT 0 NOT NULL,
    grand_total        NUMBER(14,2)   DEFAULT 0 NOT NULL,
    notes_to_customer  VARCHAR2(2000),
    internal_remarks   VARCHAR2(2000),
    created_by         NUMBER,
    created_at         TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    updated_at         TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT inv_number_uk UNIQUE (invoice_number),
    CONSTRAINT fk_invoice_customer FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE invoice_items (
    id              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_id      NUMBER         NOT NULL,
    description     VARCHAR2(2000),
    qty             NUMBER(12,2)   DEFAULT 1 NOT NULL,
    unit_price      NUMBER(14,2)   DEFAULT 0 NOT NULL,
    discount_value  NUMBER(14,2)   DEFAULT 0 NOT NULL,
    discount_type   VARCHAR2(10)   DEFAULT 'percent' NOT NULL,
    tax_percent     NUMBER(5,2)    DEFAULT 0 NOT NULL,
    line_total      NUMBER(14,2)   DEFAULT 0 NOT NULL,
    sort_order      NUMBER         DEFAULT 0 NOT NULL,
    CONSTRAINT fk_item_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);