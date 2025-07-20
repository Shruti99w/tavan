DROP TABLE IF EXISTS DynamicDataMaskExample;
-- Step 1: Create the table
CREATE TABLE DynamicDataMaskExample (
  ID INT AUTO_INCREMENT PRIMARY KEY,
  Full_Name VARCHAR(20),
  Phone BIGINT,
  Email VARCHAR(30)
);

-- Step 2: Insert data into the table
INSERT INTO DynamicDataMaskExample (Full_Name, Phone, Email)
VALUES 
  ('Emily Stone', 9123456789, 'emily.stone@google.com'),
  ('Ryan Lewis', 8234567890, 'ryan.lewis@google.org');
  
CREATE VIEW MaskedUserData AS
SELECT
  ID,
  -- Full mask of name
  'XXXX' AS Masked_Name,
  -- Partial mask of phone (keep last 4 digits)
  CONCAT('XXXXXX', RIGHT(Phone, 4)) AS Masked_Phone,
  -- Partial email mask: first letter, then Xs, then domain
  CONCAT(
    LEFT(Email, 1),
    'XXXXX',
    SUBSTRING(Email, LOCATE('@', Email))
  ) AS Masked_Email
FROM DynamicDataMaskExample;

SELECT * FROM MaskedUserData;