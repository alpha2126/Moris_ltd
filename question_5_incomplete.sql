
DELIMITER $$
CREATE PROCEDURE GetMedianOrderTotal()
BEGIN
    SELECT 
        OrderTotalAmount 
    FROM (
        SELECT OrderTotalAmount, 
               ROW_NUMBER() OVER (ORDER BY OrderTotalAmount) AS row_num,
               COUNT(*) OVER () AS total_rows
        FROM Orders
    ) t
    WHERE row_num IN (FLOOR((total_rows + 1) / 2), CEIL((total_rows + 1) / 2));
END $$
DELIMITER ;

DELIMITER $$
CREATE FUNCTION EXTRACT_ORDER_NUMBER(order_ref VARCHAR(20))
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN CAST(REPLACE(order_ref, 'PO', '') AS SIGNED);
END ;
