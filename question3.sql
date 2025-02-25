CREATE TABLE IF NOT EXISTS suppliers (
    Supplier_ID INT AUTO_INCREMENT,
    Supplier_Name VARCHAR(50) NOT NULL,
    Contact_Name VARCHAR(50),
    Address VARCHAR(100),
    Contact_Number VARCHAR(20),
    Email VARCHAR(50),
    PRIMARY KEY (Supplier_ID),
    UNIQUE KEY (Supplier_Name)
);
-- testing table suppliers
DROP table suppliers;
Select * from suppliers;
-- group by;

INSERT INTO suppliers (Supplier_Name, Contact_Name, Address, Contact_Number, Email)
SELECT DISTINCT 
    TRIM(SUPPLIER_NAME) as Supplier_Name,
    MAX(SUPP_CONTACT_NAME) as Contact_Name,
    MAX(SUPP_ADDRESS) as Address,
    MAX(SUPP_CONTACT_NUMBER) as Contact_Number,
    MAX(SUPP_EMAIL) as Email
FROM bcm_order_mgt
GROUP BY TRIM(SUPPLIER_NAME);

-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    Order_Ref VARCHAR(20),
    Order_Date VARCHAR(30),
    Supplier_ID INT,
    Order_Total_Amount DECIMAL(10,2),
    Order_Description TEXT,
    Order_Status ENUM('received', 'closed', 'open', 'paid', 'Cancelled'),
    PRIMARY KEY (Order_Ref),
    FOREIGN KEY (Supplier_ID) REFERENCES suppliers(Supplier_ID),
    INDEX idx_supplier (Supplier_ID)
);
-- testing table orders
DROP table orders;
Select * from orders;

INSERT INTO orders (Order_Ref, Order_Date, Supplier_ID, Order_Total_Amount, Order_Description, Order_Status)
SELECT DISTINCT
    b.ORDER_REF,
    MAX(b.ORDER_DATE) as Order_Date,
    MAX(s.Supplier_ID) as Supplier_ID,
    MAX(CAST(REPLACE(REPLACE(COALESCE(b.ORDER_TOTAL_AMOUNT, '0'), ',', ''), ' ', '') AS DECIMAL(10,2))) as Order_Total_Amount,
    MAX(b.ORDER_DESCRIPTION) as Order_Description,
    MAX(b.ORDER_STATUS) as Order_Status
FROM bcm_order_mgt b
JOIN suppliers s ON TRIM(b.SUPPLIER_NAME) = s.Supplier_Name
WHERE b.ORDER_REF IS NOT NULL
GROUP BY b.ORDER_REF;
-- ----------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS order_lines (
    Line_ID INT AUTO_INCREMENT,
    Order_Ref VARCHAR(20),
    Order_Line_Amount DECIMAL(10,2),
    PRIMARY KEY (Line_ID),
    FOREIGN KEY (Order_Ref) REFERENCES orders(Order_Ref),
    INDEX idx_order (Order_Ref)
);
DROP table order_lines;
Select * from order_lines;
INSERT INTO order_lines (Order_Ref, Order_Line_Amount)
SELECT 
    ORDER_REF,
    CAST(REPLACE(REPLACE(REPLACE(COALESCE(ORDER_LINE_AMOUNT, '0'), ',', ''), 'S', '5'), 'I', '1') AS DECIMAL(10,2)) as Order_Line_Amount
FROM bcm_order_mgt
WHERE ORDER_REF IS NOT NULL 
AND ORDER_LINE_AMOUNT IS NOT NULL;

-- ------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS invoices (
    Invoice_ID INT AUTO_INCREMENT,
    Invoice_Reference TEXT,
    Invoice_Date VARCHAR(20),
    Invoice_Status ENUM('Pending', 'paid'),
    Invoice_Hold_Reason TEXT,
    Invoice_Amount DECIMAL(10,2),
    Invoice_Description TEXT,
    PRIMARY KEY (Invoice_ID),
    UNIQUE KEY (Invoice_Reference(255))
);
-- -------------testing table invoices
DROP table invoices;
Select * from invoices;
INSERT INTO invoices (Invoice_Reference, Invoice_Date, Invoice_Status, Invoice_Hold_Reason, Invoice_Amount, Invoice_Description)
SELECT DISTINCT
    INVOICE_REFERENCE,
    MAX(INVOICE_DATE) as Invoice_Date,
    MAX(INVOICE_STATUS) as Invoice_Status,
    MAX(INVOICE_HOLD_REASON) as Invoice_Hold_Reason,
    MAX(INVOICE_AMOUNT) as Invoice_Amount,
    MAX(INVOICE_DESCRIPTION) as Invoice_Description
FROM bcm_order_mgt
WHERE INVOICE_REFERENCE IS NOT NULL
GROUP BY INVOICE_REFERENCE;
-- --------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_invoice (
    Order_Ref VARCHAR(20),
    Invoice_ID INT,
    PRIMARY KEY (Order_Ref, Invoice_ID),
    FOREIGN KEY (Order_Ref) REFERENCES orders(Order_Ref),
    FOREIGN KEY (Invoice_ID) REFERENCES invoices(Invoice_ID),
    INDEX idx_invoice (Invoice_ID)
);
DROP table order_invoice;
Select * from order_invoice;
INSERT INTO order_invoice (Order_Ref, Invoice_ID)
SELECT DISTINCT
    b.ORDER_REF,
    i.Invoice_ID
FROM bcm_order_mgt b
JOIN invoices i ON b.INVOICE_REFERENCE = i.Invoice_Reference
WHERE b.ORDER_REF IS NOT NULL 
AND b.INVOICE_REFERENCE IS NOT NULL;
-- -------------------------------------------------------------------------------------------------------------------



INSERT INTO orders (Order_Ref, Order_Date, Supplier_ID, Order_Total_Amount, Order_Description, Order_Status)
SELECT DISTINCT
    b.ORDER_REF,
    b.ORDER_DATE,
    s.Supplier_ID,
    CAST(REPLACE(REPLACE(b.ORDER_TOTAL_AMOUNT, ',', ''), ' ', '') AS DECIMAL(10,2)),
    b.ORDER_DESCRIPTION,
    b.ORDER_STATUS
FROM bcm_order_mgt b
JOIN suppliers s ON TRIM(b.SUPPLIER_NAME) = s.Supplier_Name
WHERE b.ORDER_REF IS NOT NULL;

-- ------------------------------------


INSERT INTO invoices (Invoice_Reference, Invoice_Date, Invoice_Status, Invoice_Hold_Reason, Invoice_Amount, Invoice_Description)
SELECT DISTINCT
    INVOICE_REFERENCE,
    MAX(INVOICE_DATE) as Invoice_Date,
    MAX(INVOICE_STATUS) as Invoice_Status,
    MAX(INVOICE_HOLD_REASON) as Invoice_Hold_Reason,
    MAX(INVOICE_AMOUNT) as Invoice_Amount,
    MAX(INVOICE_DESCRIPTION) as Invoice_Description
FROM bcm_order_mgt
WHERE INVOICE_REFERENCE IS NOT NULL
GROUP BY INVOICE_REFERENCE;
-- ------------------------------------------



-- -------------testing table order_lines
DROP table order_lines;
Select * from order_lines;
-- -------------
INSERT INTO order_lines (Order_Ref, Order_Line_Amount)
SELECT 
    ORDER_REF,
    CAST(REPLACE(REPLACE(REPLACE(COALESCE(ORDER_LINE_AMOUNT, '0'), ',', ''), 'S', '5'), 'I', '1') AS DECIMAL(10,2)) as Order_Line_Amount
FROM bcm_order_mgt
WHERE ORDER_REF IS NOT NULL 
AND ORDER_LINE_AMOUNT IS NOT NULL;






