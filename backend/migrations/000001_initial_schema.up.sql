BEGIN;

CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL CHECK (email <> '' AND email = btrim(email)),
    password_hash TEXT NOT NULL CHECK (btrim(password_hash) <> ''),
    role TEXT NOT NULL DEFAULT 'staff' CHECK (role IN ('admin', 'staff')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX users_email_unique_idx ON users (lower(email));

CREATE TABLE companies (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    address TEXT,
    logo_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE customers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id BIGINT NOT NULL,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT customers_company_fk FOREIGN KEY (company_id)
        REFERENCES companies (id) ON DELETE RESTRICT,
    CONSTRAINT customers_company_id_unique UNIQUE (company_id, id)
);

CREATE INDEX customers_company_name_idx
    ON customers (company_id, lower(name) text_pattern_ops);
CREATE INDEX customers_company_email_idx
    ON customers (company_id, lower(email) text_pattern_ops);

CREATE TABLE products (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price BIGINT NOT NULL CHECK (price >= 0),
    type TEXT NOT NULL CHECK (type IN ('product', 'service')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE transactions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    invoice_number TEXT NOT NULL UNIQUE CHECK (btrim(invoice_number) <> ''),
    total_amount BIGINT NOT NULL CHECK (total_amount >= 0),
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'issued', 'cancelled')),
    payment_status TEXT NOT NULL DEFAULT 'unpaid'
        CHECK (payment_status IN ('unpaid', 'pending', 'paid', 'failed', 'expired', 'refunded', 'partially_refunded')),
    payment_url TEXT,
    notes TEXT,
    issued_at TIMESTAMPTZ,
    due_date DATE,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT transactions_customer_company_fk FOREIGN KEY (company_id, customer_id)
        REFERENCES customers (company_id, id) ON DELETE RESTRICT,
    CONSTRAINT transactions_issued_at_check CHECK (status <> 'issued' OR issued_at IS NOT NULL),
    CONSTRAINT transactions_paid_at_check CHECK (
        payment_status NOT IN ('paid', 'refunded', 'partially_refunded') OR paid_at IS NOT NULL
    )
);

CREATE INDEX transactions_company_customer_idx ON transactions (company_id, customer_id);
CREATE INDEX transactions_company_issued_at_idx ON transactions (company_id, issued_at);

CREATE TABLE transaction_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price BIGINT NOT NULL CHECK (price >= 0),
    subtotal BIGINT GENERATED ALWAYS AS (quantity * price) STORED CHECK (subtotal >= 0),
    CONSTRAINT transaction_items_transaction_fk FOREIGN KEY (transaction_id)
        REFERENCES transactions (id) ON DELETE RESTRICT,
    CONSTRAINT transaction_items_product_fk FOREIGN KEY (product_id)
        REFERENCES products (id) ON DELETE RESTRICT
);

CREATE INDEX transaction_items_transaction_idx ON transaction_items (transaction_id);
CREATE INDEX transaction_items_product_idx ON transaction_items (product_id);

CREATE TABLE payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    midtrans_order_id TEXT NOT NULL UNIQUE CHECK (btrim(midtrans_order_id) <> ''),
    gross_amount BIGINT NOT NULL CHECK (gross_amount >= 0),
    payment_type TEXT,
    transaction_status TEXT NOT NULL CHECK (btrim(transaction_status) <> ''),
    fraud_status TEXT,
    signature_key TEXT CHECK (signature_key ~ '^[0-9A-Fa-f]{128}$'),
    raw_response JSONB,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT payments_transaction_fk FOREIGN KEY (transaction_id)
        REFERENCES transactions (id) ON DELETE RESTRICT,
    -- Permit only selected scalar webhook metadata. Values must be sanitized at ingestion.
    CONSTRAINT payments_raw_response_check CHECK (
        CASE WHEN raw_response IS NULL THEN true
            WHEN jsonb_typeof(raw_response) <> 'object' THEN false
            ELSE raw_response - ARRAY['status_code', 'currency'] = '{}'::jsonb
                AND (NOT (raw_response ? 'status_code') OR (
                    jsonb_typeof(raw_response -> 'status_code') = 'string'
                    AND raw_response ->> 'status_code' ~ '^[1-5][0-9]{2}$'
                ))
                AND (NOT (raw_response ? 'currency') OR raw_response -> 'currency' = '"IDR"'::jsonb)
        END
    )
);

CREATE INDEX payments_transaction_idx ON payments (transaction_id);

CREATE TABLE invoice_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    action TEXT NOT NULL CHECK (btrim(action) <> ''),
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT invoice_logs_transaction_fk FOREIGN KEY (transaction_id)
        REFERENCES transactions (id) ON DELETE RESTRICT
);

CREATE INDEX invoice_logs_transaction_created_at_idx ON invoice_logs (transaction_id, created_at, id);

CREATE FUNCTION billflow_set_updated_at() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := statement_timestamp();
    RETURN NEW;
END;
$$;

CREATE TRIGGER users_set_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION billflow_set_updated_at();
CREATE TRIGGER companies_set_updated_at BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION billflow_set_updated_at();
CREATE TRIGGER customers_set_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION billflow_set_updated_at();
CREATE TRIGGER products_set_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION billflow_set_updated_at();
CREATE TRIGGER transactions_set_updated_at BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION billflow_set_updated_at();
CREATE TRIGGER payments_set_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION billflow_set_updated_at();

COMMIT;
