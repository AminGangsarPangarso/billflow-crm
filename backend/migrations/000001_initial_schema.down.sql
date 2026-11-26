BEGIN;

DROP TABLE invoice_logs;
DROP TABLE payments;
DROP TABLE transaction_items;
DROP TABLE transactions;
DROP TABLE products;
DROP TABLE customers;
DROP TABLE companies;
DROP TABLE users;
DROP FUNCTION billflow_set_updated_at();

COMMIT;
