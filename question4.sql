
DELIMITER $$
CREATE or FUNCTION FORMAT_NAME(name VARCHAR(100))
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    DECLARE result VARCHAR(100);
    SET result = CONCAT(
        UPPER(SUBSTRING(name, 1, 1)),
        LOWER(SUBSTRING(name, 2))
    );
    RETURN result;
END ;
DELIMITER $$
CREATE or FUNCTION EXTRACT_ORDER_NUMBER(order_ref VARCHAR(20))
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN CAST(REPLACE(order_ref, 'PO', '') AS SIGNED);
END ;
DELIMITER $$
CREATE OR REPLACE FUNCTION FORMAT_ORDER_PERIOD(order_date VARCHAR(30))
RETURNS VARCHAR(7)
DETERMINISTIC
BEGIN
    DECLARE year VARCHAR(4);
    DECLARE month VARCHAR(2);
    
    -- Extract year and month from date string (assuming format DD-MON-YYYY)
    SET year = SUBSTRING_INDEX(order_date, '-', -1);
    SET month = LPAD(
        FIELD(UPPER(SUBSTRING_INDEX(SUBSTRING_INDEX(order_date, '-', 2), '-', -1)),
            'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
            'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'),
        2, '0'
    );
    
    RETURN CONCAT(year, '-', month);
END ;
DELIMITER $$
CREATE OR REPLACE FUNCTION EXTRACT_REGION(address VARCHAR(100))
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE region VARCHAR(50);
    -- Extract text after the last comma or before first comma if multiple exists
    IF address LIKE '%,%' THEN
        SET region = TRIM(SUBSTRING_INDEX(address, ',', -1));
        IF region = '' THEN
            SET region = TRIM(SUBSTRING_INDEX(address, ',', 1));
        END IF;
    ELSE
        SET region = TRIM(address);
    END IF;
    RETURN region;
END ;
DELIMITER $$
CREATE OR REPLACE PROCEDURE GetOrderInvoiceSummaryByRegion()
BEGIN
    WITH InvoiceStatus AS (
        SELECT 
            o.Order_Ref,
            CASE 
                WHEN COUNT(i.Invoice_Status) = 0 THEN 'To verify'
                WHEN SUM(CASE WHEN i.Invoice_Status = 'Pending' THEN 1 ELSE 0 END) > 0 THEN 'To follow up'
                WHEN SUM(CASE WHEN i.Invoice_Status = 'paid' THEN 1 ELSE 0 END) = COUNT(i.Invoice_Status) THEN 'No Action'
                ELSE 'To verify'
            END as Action_Status
        FROM orders o
        LEFT JOIN order_invoice oi ON o.Order_Ref = oi.Order_Ref
        LEFT JOIN invoices i ON oi.Invoice_ID = i.Invoice_ID
        GROUP BY o.Order_RefGetOrderInvoiceSummaryByRegion
    )
    SELECT 
        EXTRACT_REGION(s.Address) as Region,
        EXTRACT_ORDER_NUMBER(o.Order_Ref) as 'Order Reference',
        FORMAT_ORDER_PERIOD(o.Order_Date) as 'Order Period',
        CONCAT(
            FORMAT_NAME(SUBSTRING_INDEX(s.Supplier_Name, ' ', 1)),
            CASE 
                WHEN CHAR_LENGTH(s.Supplier_Name) - CHAR_LENGTH(REPLACE(s.Supplier_Name, ' ', '')) > 0
                THEN CONCAT(' ', FORMAT_NAME(SUBSTRING_INDEX(s.Supplier_Name, ' ', -1)))
                ELSE ''
            END
        ) as 'Supplier Name',GetOrderInvoiceSummaryByRegion
        FORMAT(o.Order_Total_Amount, 2) as 'Order Total Amount',
        o.Order_Status as 'Order Status',
        GROUP_CONCAT(DISTINCT i.Invoice_Reference ORDER BY i.Invoice_Reference) as 'Invoice Reference',
        FORMAT(SUM(DISTINCT i.Invoice_Amount), 2) as 'Invoice Total Amount',
        MAX(ist.Action_Status) as 'Action'
    FROM orders o
    JOIN suppliers s ON o.Supplier_ID = s.Supplier_ID
    LEFT JOIN order_invoice oi ON o.Order_Ref = oi.Order_Ref
    LEFT JOIN invoices i ON oi.Invoice_ID = i.Invoice_ID
    JOIN InvoiceStatus ist ON o.Order_Ref = ist.Order_Ref
    WHERE s.Address IS NOT NULL
    GROUP BY 
        EXTRACT_REGION(s.Address),
        o.Order_Ref,
        o.Order_Date,
        s.Supplier_Name,
        o.Order_Total_Amount,
        o.Order_Status
    ORDER BY 
        EXTRACT_REGION(s.Address),
        o.Order_Total_Amount DESC;
END ;

DELIMITER ;
call GetOrderInvoiceSummaryByRegion();
