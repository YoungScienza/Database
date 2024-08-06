-- Calculate total Purchase Order value
-- Environment: This function is designed to run on Microsoft SQL Server
-- Tools: Developed and tested using SQL Server Management Studio 20 (SSMS)

CREATE FUNCTION CalculateTot (
    @MANDT VARCHAR(3), -- Customer number
    @EBELN VARCHAR(10), -- PO Number
    @D_DATE DATE -- Date considered
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @TOTAL_NETWR DECIMAL(18, 2);
    DECLARE @ORDER_DATE DATE;

    -- Get the order creation date from EKKO
    SELECT @ORDER_DATE = AEDAT
    FROM [Challange].[dbo].[EKKO]
    WHERE MANDT = @MANDT AND EBELN = @EBELN;

    -- If the given date is before the order creation date, return 0
    IF @D_DATE < @ORDER_DATE
    BEGIN
        RETURN 0;
    END;

	-- First we select all the element for the client number and the PO number from EKPO
    WITH InitialValues AS (
        SELECT MANDT, EBELN, EBELP, CAST(NETWR AS DECIMAL(18, 2)) AS NETWR
        FROM [Challange].[dbo].[EKPO]
        WHERE MANDT = @MANDT AND EBELN = @EBELN
    ),
	-- Then we merge CDPOS_clean and CDHDR to look for any changes in our order
    Changes AS (
        SELECT 
            CDPOS.MANDANT,
            CDPOS.TABKEY,
            CAST(CDPOS.VALUE_NEW AS DECIMAL(18, 2)) AS NEW_NETWR,
            CAST(CDPOS.VALUE_OLD AS DECIMAL(18, 2)) AS OLD_NETWR,
            CDHDR.UDATE, -- UDATE allows us to track when these changes happened
            CDHDR.UTIME, -- UTIME is important because they may be multiple entries on the same day at different times
            ROW_NUMBER() OVER (PARTITION BY CDPOS.TABKEY ORDER BY CDHDR.UDATE DESC, CDHDR.UTIME DESC) AS rn -- We introduce this partition by TABKEY to keep track of time changes for each item and list them in time order
        FROM [Challange].[dbo].[CDPOS_clean] CDPOS
        JOIN [Challange].[dbo].[CDHDR] ON CDPOS.CHANGENR = [Challange].[dbo].[CDHDR].CHANGENR
          AND CDPOS.MANDANT = [Challange].[dbo].[CDHDR].MANDANT
        WHERE CDPOS.TABNAME = 'EKPO'
          AND CDPOS.FNAME = 'NETWR'  --	Select only the entry related to NETWR
          AND CDPOS.MANDANT = @MANDT
          AND CDPOS.TABKEY LIKE @MANDT + @EBELN + '%' -- Look for all the items
          AND [Challange].[dbo].[CDHDR].UDATE <= @D_DATE -- For same date or before the provided one
    ),
	-- We update the values by merging EKPO and CDPOS/CDHDR
    UpdatedValues AS (
        SELECT 
            I.EBELP,
            I.NETWR AS INITIAL_NETWR,
            C.NEW_NETWR,
            C.OLD_NETWR,
            C.UDATE,
            C.UTIME,
            COALESCE(C.NEW_NETWR, I.NETWR) AS UPDATED_NETWR -- COALESCE here allows us to select either the new PO value or, if NULL, the original one (see also left join below)
        FROM InitialValues I		-- The left join ensures us to always refer to the elements listed in EKPO, if no update privided the new values for them will be NULL
        LEFT JOIN Changes C ON CONCAT(I.MANDT, I.EBELN, I.EBELP) = C.TABKEY 
        AND I.MANDT = C.MANDANT
        WHERE (C.rn = 1 OR C.rn IS NULL)  -- Here the partition we used above comes in place allowing us to either select the closest NETWR value or the orginal from EKPO
          AND I.MANDT = @MANDT 
          AND I.EBELN = @EBELN
    )
    SELECT @TOTAL_NETWR = SUM(UPDATED_NETWR) -- We finally sum the obtained NETWR values
    FROM UpdatedValues;

    RETURN @TOTAL_NETWR;
END; 



/*Here I will try to summarize the most important decisions I took in the design of this function for quering PO.
Regarding data preprocessing I did not not do much since I was asked to work with SQL and also not being expert of the data I wanted to avoid any corruptions in their
structure. The only pre processing step I was forced to do is to clean CDPOS columns VALUE_OLD and VALUE_NEW because there were some forbidden characters that my SQL SMS 
could not read causing the whole table creation to fail, for this reason I am using CDPOS_clean. See the Python notebook attached for more info.
Regarding the design:

1) I added an if statement to return 0 if the date provided (D_DATE) is prior to the order creation date (AEDAT) in EKKO

2) I noticed that there were some entires IN CDPOS/CDHDR, from the last part of TABKEY that is the item nuber (EBELP), that are not registered in EKPO. I decided not 
to account for these items since, their item number, usally 00030, registered only  two times in EKPO made me think that they may be some inconsistencies in the data
or they might have been obtained in different times, not accounting for the changhes in between.

3) I did not account for 'CHNGID = I' for the same reasons of 2): not all insertions are registered in EKPO. 
Another missing value for CHNGID is either 'E' or 'D' that states for eliminated/deleted.
These inconsitency make me think that the problem is in CDPOS/CDHDR itself and so I decided that my item list will be EKPO since evry entry in it should be registered in
CDPOS/CDHDR and not viceversa. 

4) The function uses the most recent change before or on the given date, using ROW_NUMBER() to rank changes.

5) The initial net order value from EKPO is used if no changes are recorded in CDPOS.

Here is a test run of the function

DECLARE @TotalNetwr DECIMAL(18, 2);
SET @TotalNetwr = dbo.CalculateTot('010', '0072115700', '2022-10-09');
SELECT @TotalNetwr;
*/