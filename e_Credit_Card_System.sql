/* ASG 1 Team 4 
Members:
		 Wong Guo Fung		 S10223160D	  Credit Card Application - Customer
		 Teo Shaoming Jevan	 S10223048J   Credit Card Application - Credit Card
		 Toh Wee Kiat Ernest S10221816B	  Card Transaction & Redeem Reward
		 Mandy Tang Min Yee	 S10218941C   Monthly Credit Card Bill and Payment 
*/


------------------------------------------------------------------------------------------------------------
-- Details of the customer earning rewards for a given month-- Require stored procedure --[uspSearchCustomerEarnReward].
-- Wong Guo Fung S10223160D
IF EXISTS ( SELECT * FROM SYSOBJECTS 
	WHERE Name = 'CustomerEarnRewardView' AND Type = 'V')
		DROP VIEW CustomerEarnRewardView
GO

CREATE VIEW CustomerEarnRewardView 
AS
	SELECT c.CustID,c.CustName, c.CustNRIC, c.CustEmail, c.CustContact, -- Customer Details
    cc.CCNo, ct.CTNo, ct.CTMerchant, ct.CTAmount, ct.CTDate, -- Transcation Details 
    r.RewDesc, r.RewAmount, r.RewValidTill, r.RewRedeemDate, r.RewStatus -- Reward Details FROM CreditCard cc
	FROM CreditCard cc
	INNER JOIN Customer c ON cc.CCCustId = c.CustId
	INNER JOIN CardTransaction ct ON cc.CCNo = ct.CTCCNo
	INNER JOIN Reward r ON cc.CCNo = r.RewCCNo
	WHERE CTAmount > 500.00 -- Eligible for Reward
	
GO
------------------------------------------------------------------------------------------------------------
-- Details of the transactions for a given customer for a given month -- Require stored procedure --[uspSearchCustomerTransaction].
-- Toh Wee Kiat, Ernest S10221816B
IF EXISTS ( SELECT * FROM SYSOBJECTS 
	WHERE Name = 'CustomerCCCTView' AND Type = 'V')
		DROP VIEW CustomerCCCTView
GO
CREATE VIEW CustomerCCCTView
AS
	SELECT c.CustId,c.CustNRIC, FORMAT(CAST(cc.CCNo AS BIGINT) , '####-####-####-####') AS 'CCNo',cc.CCCVV, ct.CTNo,ct.CTStatus,ct.CTMerchant,ct.CTAmount,ct.CTDate FROM CreditCard cc
	INNER JOIN Customer c ON cc.CCCustId = c.CustId
	INNER JOIN CardTransaction ct on ct.CTCCNo = cc.CCNo
GO

-- SELECT * FROM CustomerCCCTView
------------------------------------------------------------------------------------------------------------
-- Most Transaction Merchant View -- Toh Wee Kiat, Ernest S10221816B
IF EXISTS ( SELECT * FROM SYSOBJECTS 
    WHERE Name = 'MostTransactionMerchantView' AND Type = 'V')
        DROP VIEW MostTransactionMerchantView
GO
CREATE VIEW MostTransactionMerchantView 
AS
    SELECT ct.CTMerchant,COUNT(ct.CTAmount) AS 'Total number of transaction processed' FROM CardTransaction ct
    WHERE ct.CTStatus = 'Pending' OR ct.CTStatus = 'Billed'
    GROUP BY ct.CTMerchant
GO

-- SELECT * FROM MostTransactionMerchantView
------------------------------------------------------------------------------------------------------------
-- Details of customers who have not paid their bills last month. Generally, the previous month balance will be brought forward to the current month.
-- Hence, no need input of date, e.g. today is November, a customer have a overdue bill for September, it is brought forward to October. Hence, we will show the October Bill instead.
-- As September CCSTotalAmountDue is 0.00, as it is brought forward to October.
-- Teo Shaoming Jevan S10223048J
IF EXISTS ( SELECT * FROM SYSOBJECTS 
	WHERE Name = 'CustomerUnpaidBillsView' AND Type = 'V')
		DROP VIEW CustomerUnpaidBillsView
GO
CREATE VIEW CustomerUnpaidBillsView 
AS
	SELECT distinct(cc.CCCustId), c.CustName, c.CustContact,c.CustEmail, ccs.CCSDate, ccs.CCSPayDueDate, ccs.CCSTotalAmountDue FROM CardTransaction ct 
	INNER JOIN CreditCardStatement ccs ON ct.CTCCSNo = ccs.CCSNo --Bill Number
	INNER JOIN CreditCard cc ON ct.CTCCNo = cc.CCNo -- Credit Card Number
	INNER JOIN Customer c ON cc.CCCustId = c.CustId
	WHERE ccs.CCSTotalAmountDue != 0.00
GO

------------------------------------------------------------------------------------------------------------
--########################################################################################################--
------------------------------------------------------------------------------------------------------------
/* 
Credit Card Application - Customer
return values:
-101 : Indicating that Customer NRIC already exist in the Table
-102: Indicating that email already exist in the table
-103: No Attributes Entered
-104: Customer not found
-105: Customer status not in option
-106: Month not found

*/

/* Creating Customer */   --- Wong Guo Fung S10223160D
IF EXISTS ( SELECT * FROM SYSOBJECTS 
	WHERE  Name = 'uspCreateCustomer' AND Type = 'P')
		DROP PROC uspCreateCustomer
GO
CREATE PROC uspCreateCustomer 
(@cId CHAR(8), @cNRIC char(9), @cName VARCHAR(50), @cDOB smalldatetime, 
@cAddress VARCHAR(100), @cContact VARCHAR(15), 
@cEmail VARCHAR(50), @cAnnualIncome smallmoney)
AS

-- Check if customer exist in database, as NRIC and email are unique for everyone, hence NRIC and email cannot be the same.
IF EXISTS (SELECT CustId FROM Customer WHERE CustNRIC = @cNRIC) 
	RETURN -101 -- Indicating that Customer NRIC already exist in the Table

ELSE IF EXISTS(SELECT CustId FROM Customer WHERE CustEmail = @cEmail)
	RETURN -102 -- Indicating that email already exist in the table

ELSE
BEGIN
	INSERT INTO Customer (CustId,CustNRIC, CustName, CustDOB, 
	CustAddress, CustContact, 
	CustEmail, CustAnnualIncome, CustJoinDate, CustStatus) 
	VALUES (@cId,@cNRIC, @cName, @cDOB, @cAddress, @cContact, 
	@cEmail, @cAnnualIncome,GETDATE(), 'Pending') -- Default Status
	IF @@ERROR <> 0
	BEGIN
		PRINT 'System Error'
		RETURN -404 -- Can be return by having similar CustID
	END
END
RETURN

GO
------------------------------------------------------------------------------------------------------------ 
/* Update Customer */   --- Wong Guo Fung S10223160D
IF EXISTS ( SELECT * FROM SYSOBJECTS 
	WHERE  Name = 'uspUpdateCustomerDetails' AND Type = 'P')
		DROP PROC uspUpdateCustomerDetails
GO

CREATE PROC uspUpdateCustomerDetails
(@cNRIC char(9), @cName VARCHAR(50) = NULL,
@cAddress VARCHAR(100) = NULL, @cContact VARCHAR(15) = NULL , 
@cEmail VARCHAR(50) = NULL, @cAnnualIncome smallmoney =  NULL)
AS

IF (@cName IS NULL AND @cAddress IS NULL AND @cContact IS NULL AND @cEmail IS NULL AND @cAnnualIncome IS NULL)
	RETURN -103 -- No Attributes Entered

IF NOT EXISTS (SELECT CustNRIC FROM Customer WHERE @cNRIC = CustNRIC) 
	RETURN -104 -- Customer not found

BEGIN
	UPDATE Customer SET CustName = ISNULL(@cName, CustName),
						CustAddress = ISNULL(@cAddress, CustAddress),
						CustContact = ISNULL(@cContact, CustContact),
						CustEmail = ISNULL(@cEmail, CustEmail)
	WHERE CustNRIC = @cNRIC
	IF (@cAnnualIncome IS NOT NULL)
		UPDATE Customer SET CustAnnualIncome = @cAnnualIncome WHERE CustNRIC = @cNRIC
	IF @@ERROR <> 0
		RETURN -404
END
RETURN

GO
------------------------------------------------------------------------------------------------------------ 
/* Update Customer Status -- Checking if they are eligible for applying a credit card */   --- Wong Guo Fung S10223160D
IF EXISTS ( SELECT * FROM SYSOBJECTS 
	WHERE  Name = 'uspUpdateCustomerStatus' AND Type = 'P')
		DROP PROC uspUpdateCustomerStatus
GO

CREATE PROC uspUpdateCustomerStatus (@cNRIC CHAR(9), @cStatus VARCHAR(15))
AS

IF NOT EXISTS (SELECT CustNRIC FROM Customer WHERE @cNRIC = CustNRIC)
	RETURN -104 -- Customer not found

DECLARE @cId CHAR(8)
SET @cId = (SELECT CustId FROM Customer WHERE @cNRIC = CustNRIC)
DECLARE @CustDOB smalldatetime
SET @CustDOB = (SELECT c.CustDOB FROM Customer c WHERE CustNRIC = @cNRIC)
DECLARE @CustAnnualIncome smallmoney
SET @CustAnnualIncome = (SELECT c.CustAnnualIncome FROM Customer c WHERE CustNRIC = @cNRIC)

-- Want to make customer eligible for applying credit card
IF (@cStatus = 'Active')
BEGIN
	IF (((DATEDIFF(year,@CustDOB,GETDATE())) BETWEEN 21 AND 70) AND (@CustAnnualIncome >= 30000.00)) -- Compare today's date with DOB to obtain AGE
	BEGIN
		UPDATE Customer SET CustStatus = 'Active' WHERE CustId = @cId
		PRINT 'Customer status updated to "Active", able to apply for credit card.'
	END
	ELSE
	BEGIN
		PRINT 'Customer not eligible to apply for credit card.'
	END
END

-- In any case bank officer(s) want to suspend or set to pending for a customer. For example, due to bankruptcy, or change in income.
ELSE IF (@cStatus  IN ('Suspended','Pending'))
	BEGIN
	-- Check that customer credit card is not active, if not active -- able to update 

	-- Check if customer have credit card
	IF EXISTS (SELECT * FROM CreditCard WHERE CCCustId = @cId)	
		IF (SELECT CCStatus FROM CreditCard WHERE CCCustId = @cId) <> 'Active' 
			IF (@cStatus = 'Pending')
				UPDATE Customer SET CustStatus = 'Pending' WHERE CustId = @cId
			ELSE
				UPDATE Customer SET CustStatus = 'Suspended' WHERE CustId = @cId
		ELSE 
			PRINT 'Customer credit card still active'
	-- Customer with no credit card, update CustStatus
	ELSE
		IF (@cStatus = 'Pending')
				UPDATE Customer SET CustStatus = 'Pending' WHERE CustId = @cId
			ELSE
				UPDATE Customer SET CustStatus = 'Suspended' WHERE CustId = @cId
	END

-- Status provied not in option
ELSE
	RETURN -105 -- Customer status not in option.

RETURN
GO

------------------------------------------------------------------------------------------------------------ 
/* In continuation to uspSearchCustomerEarnReward, Search Month */   --- Wong Guo Fung S10223160D

IF EXISTS ( SELECT * FROM SYSOBJECTS 
	WHERE  Name = 'uspSearchCustomerEarnReward' AND Type = 'P')
		DROP PROC uspSearchCustomerEarnReward
GO

CREATE PROC uspSearchCustomerEarnReward (@date datetime) -- Date whereby bank officer wants to check 
AS 

BEGIN
	SELECT * FROM CustomerEarnRewardView WHERE MONTH(@date) = MONTH(CTDate) AND YEAR(@date) = YEAR(CTDate)
END
GO
------------------------------------------------------------------------------------------------------------ 
/* Remind Bank Officer to check eligibility of Credit Card Application after each customer is CREATED  */   --- Wong Guo Fung S10223160D
IF EXISTS ( SELECT * FROM SYSOBJECTS 
	WHERE  Name = 'trigInsertCustomer' AND Type = 'TR')
		DROP TRIGGER trigInsertCustomer
GO

CREATE TRIGGER trigInsertCustomer
ON Customer AFTER INSERT
AS

DECLARE @CustID VARCHAR(50)
SET @CustID = (SELECT i.CustId FROM INSERTED i)
PRINT 'A new customer was added successfully, please check if he/she is eligible for credit card application.'

GO
------------------------------------------------------------------------------------------------------------ 
/* Remind Bank Officer to check eligibility of Credit Card Application after each customer is UPDATED */   --- Wong Guo Fung S10223160D
IF EXISTS ( SELECT * FROM SYSOBJECTS 
	WHERE  Name = 'trigUpdateCustomer' AND Type = 'TR')
		DROP TRIGGER trigUpdateCustomer
GO

CREATE TRIGGER trigUpdateCustomer
ON Customer AFTER UPDATE
AS

-- For every update
PRINT 'Customer details is updated.'

IF (UPDATE(CustStatus))
	PRINT 'Customer status is updated.'

-- As these two columns are requirements that will affect the eligibility of credit card application 
IF (UPDATE(CustAnnualIncome)) --Only when CustAnnualIncome column is updated, PRINT
	PRINT 'Annual income of customer is updated, please check if he/she is eligible for credit card application'

GO
------------------------------------------------------------------------------------------------------------ 
/* Stop the delete of customer data, customer data is useful for bank, omit deletion   */   --- Wong Guo Fung S10223160D
IF EXISTS ( SELECT * FROM SYSOBJECTS 
	WHERE  Name = 'trigStopDeleteCustomer' AND Type = 'TR')
		DROP TRIGGER trigStopDeleteCustomer
GO

CREATE TRIGGER trigStopDeleteCustomer
ON Customer INSTEAD OF DELETE
AS

PRINT 'Customer is not deleted, consider changing the customer status instead'
GO
------------------------------------------------------------------------------------------------------------
--########################################################################################################--
------------------------------------------------------------------------------------------------------------
/*
return values:
-201: Customer does not exist
-202:  Customer not eligible for Credit Card
-203:  Credit card valid thru date not more than today's date
-204:  Customer already has an active credit card
-205:  Credit Card does not exist
-206:  No changes applied to credit card
-207:  Wrong CVV for credit card
-251: Customer exists in customer table but not in credit card table
*/

CREATE PROC uspCreateCreditCard -- Teo Shaoming Jevan S10223048J
(@ccValidThru CHAR(7), @ccCustId CHAR(8))
AS

IF (SELECT CustID FROM Customer WHERE CustId = @ccCustId) = (SELECT CCCustId FROM CreditCard WHERE CCCustId = @ccCustId AND CCStatus = 'Active') 
	RETURN -204 -- Customer already has a active credit card  According to ER diagram, one CC for each customer

IF EXISTS(SELECT CustId FROM Customer WHERE CustId = @ccCustId) -- Customer Exist
BEGIN
	IF (SELECT CustStatus FROM Customer WHERE CustId = @ccCustId) = 'Active' -- Customer's status is eligible for CC
	BEGIN
		IF (CONVERT(smalldatetime ,'01/' + @ccValidThru) > GETDATE())  -- ccValidThru Date must be more than today's Date
		BEGIN
			-- Declaration of ccNo and ccVV randomly
			DECLARE @ccNo CHAR(16)
			DECLARE @ccCVV CHAR(3)
			WHILE (1=1)
				BEGIN 
					SET @ccNo = format(FLOOR(RAND() * (9999999999999999 )) + 1 , '0000000000000000')
					IF NOT EXISTS(SELECT CCNo FROM CreditCard WHERE CCNo = @ccNo) -- Random 16 Digit Number Not In Table
						SET @ccCVV = format(FLOOR(RAND() * (999 )) + 1 , '000') -- Random 3 Digit Number (Can Repeat)
						BREAK	
				END
			-- Declaration of ccCreditLimit and ccCurrentBal
			-- ccCreditLimit and ccCurrentBal have the same value as cc was just created (no spending made)
			DECLARE @ccCreditLimit smallmoney
			SET @ccCreditLimit = (SELECT CustAnnualIncome*0.5  FROM Customer WHERE CustId = @ccCustId)
			DECLARE @ccCurrentBal smallmoney 
			SET @ccCurrentBal = (SELECT CustAnnualIncome*0.5  FROM Customer WHERE CustId = @ccCustId)

			INSERT INTO CreditCard (CCNo, CCCVV, CCValidThru, CCCreditLimit, CCCurrentBal, CCStatus, CCCustId)
			VALUES(@ccNo, @ccCVV, @ccValidThru, @ccCreditLimit, @ccCurrentBal, 'Active', @ccCustId)
			PRINT 'A new credit card was added.'
			IF @@ERROR <> 0
				RETURN -404
		END
		ELSE
			RETURN -203 -- Credit Card ValidThru not more than Today's Date
	END
	ELSE
		return -202 -- Customer not Eligible for cc
END
ELSE
	return -201 -- Customer  does not exist
GO

------------------------------------------------------------------------------------------------------------
/* Update CreditCard */ -- Teo Shaoming Jevan S10223048J
-- A SELECT query statement can be run every month to compare today's date with ValidThru date to check if any card is expired 
IF EXISTS ( SELECT * FROM SYSOBJECTS 
	WHERE  Name = 'uspUpdateCreditCardStatus' AND Type = 'P')
		DROP PROC uspUpdateCreditCardStatus
GO

CREATE PROC uspUpdateCreditCardStatus
(@ccNo CHAR(16), @ccStatus VARCHAR(10) = NULL)
AS 

IF NOT EXISTS (SELECT CCNo FROM CreditCard WHERE CCNo = @ccNo)
	RETURN -205 -- Credit Card not exist

IF (@ccStatus = NULL OR @ccStatus = (SELECT CCStatus FROM CreditCard WHERE CCNo = @ccNo)) -- If no status entered or same status entered, no changes
	RETURN -206 -- No Changes Applied to Credit Card

ELSE IF (@ccStatus IN ('Expired','Cancelled','Suspended'))  -- Setting Credit Card to Active is denied as if a CC is Expired, Cancelled or Suspended), should customer want to have CC again, he apply for a new one   
		UPDATE CreditCard SET CCStatus = @ccStatus WHERE CCNo = @ccNo		-- Active : card can be used | Expired: card has expired 
																			-- Cancelled : card been cancelled by customer | Suspended : card has been temporarily suspended
RETURN
GO

------------------------------------------------------------------------------------------------------------
/* Delete Credit Card */ -- Teo Shaoming Jevan S10223048J
IF EXISTS ( SELECT * FROM SYSOBJECTS 
	WHERE  Name = 'uspDeleteCreditCard' AND Type = 'P')
		DROP PROC uspDeleteCreditCard
GO
CREATE PROC uspDeleteCreditCard
(@ccNo CHAR(16), @ccCVV CHAR(3)) 
AS 

IF EXISTS(SELECT CCNo FROM CreditCard WHERE CCNo = @ccNo) -- Ensuring Credit Card exist
	IF (@ccCVV = (SELECT CCCVV FROM CreditCard WHERE CCNo = @ccNo)) -- Check if CCCVV entered matches with Credit Card
		DELETE CreditCard WHERE CCNo = @ccNo AND CCCVV = @ccCVV
	ELSE
		RETURN -207 --Wrong CVV for Credit Card
ELSE
	RETURN -205 -- Credit Card does not exist
RETURN
GO

------------------------------------------------------------------------------------------------------------
/* Delete Trigger For Credit Card  */ -- Teo Shaoming Jevan S10223048J
IF EXISTS ( SELECT * FROM SYSOBJECTS 
	WHERE  Name = 'trigDeleteCreditCard' AND Type = 'TR')
		DROP TRIGGER trigDeleteCreditCard
GO
CREATE TRIGGER trigDeleteCreditCard
on CreditCard
INSTEAD OF DELETE
AS
IF (SELECT d.CCNo FROM DELETED d) NOT IN (SELECT CCNo FROM CreditCard ) 
	PRINT 'Credit Card entered not found' -- Credit Card not in table
-- Allow delete for expired as card holder of CC follow the CC system rules
-- Deleting expired credit card as it may waste space storing them
IF (SELECT d.CCStatus FROM DELETED d) = 'Expired'
	BEGIN
		DELETE CreditCard WHERE CCNo = (SELECT d.CCNo FROM DELETED d)
		PRINT 'Credit Card has been deleted.'
	END
-- Unable to delete active credit card 
ELSE IF (SELECT d.CCStatus FROM DELETED d) = 'Active'
	BEGIN
		PRINT 'Credit Card is not deleted as it is active.'
	END
-- Credit Card status that is Suspended or Cancelled remains in Table as records (Use for Credibility Score)
ELSE IF (SELECT d.CCStatus FROM DELETED d) = 'Suspended'
	BEGIN
		UPDATE CreditCard SET CCStatus = 'Suspended' WHERE CCNo = (SELECT d.CCNo FROM DELETED d)
		PRINT 'Credit Card is not deleted but its status is updated to "Suspended".'
	END
ELSE 
	BEGIN
		UPDATE CreditCard SET CCStatus = 'Cancelled' WHERE CCNo = (SELECT d.CCNo FROM DELETED d)
		PRINT 'Credit Card is not deleted but its status is updated to "Cancelled".'
	END
GO

------------------Create procedure to change limit if there is a update----------------------
-- Teo Shaoming Jevan S10223048J
CREATE PROC uspUpdateCClimit(@CustID CHAR(8) = NULL)
AS
--Check customer first
IF NOT EXISTS(SELECT CustId FROM Customer WHERE CustId = @CustID)
	RETURN -201 --Customer does not exist in customer table
IF NOT EXISTS(SELECT CCCustId FROM CreditCard WHERE CCCustId = @CustID)
	RETURN -251 -- Customer is found in customer table but not in credit card table
ELSE IF @CustID = (SELECT CCCustID FROM CreditCard WHERE CCCustId = @CustID)
	BEGIN
	UPDATE CreditCard SET CCCurrentBal = ((SELECT CustAnnualIncome FROM Customer WHERE CustId = @CustID) / 2) WHERE CCCustId = @CustID
	END
ELSE 
	RETURN -252 --Unknown Error
RETURN
GO

------------------------------------------------------------------------------------------------------------
--########################################################################################################--
------------------------------------------------------------------------------------------------------------
/*
return values:
-301: Credit Card does not exist
-302: Credit Card not active
-303: Reward not available
-601: transaction does not exist
-602: ctstatus not pending
*/
-- Create Transaction Procedure - Toh Wee Kiat, Ernest S10221816B
CREATE PROC uspCreateTransactions
(@ctNo CHAR(10), @ctMerchant VARCHAR(100) ,@ctAmount smallmoney, @ctDate datetime, @ctccNo CHAR(16), @input char(10))
AS

DECLARE @discountedAmount SMALLMONEY
DECLARE @rewardId INT

IF EXISTS(SELECT CCNo FROM CreditCard WHERE CCNo = @ctccNo)  -- Credit Card Exist
BEGIN
    IF (SELECT CCStatus FROM CreditCard WHERE CCNo = @ctccNo) = 'Active'
    BEGIN
		-- Customer want to Claim reward when having card transaction
		IF @input = 'Y'
		BEGIN
			-- Check Reward exist, choose first one only
			IF EXISTS (SELECT TOP 1 * FROM Reward WHERE (RewStatus = 'Available' AND RewCCNo = @ctccNo) AND (RewDesc = @ctMerchant + ' Voucher' AND RewValidTill >= @ctDate)) 
			BEGIN
				-- Setting discounted amount, total amount discounted
				SET @rewardId = (SELECT TOP 1 RewID FROM Reward WHERE (RewStatus = 'Available' AND RewCCNo = @ctccNo) AND (RewDesc = @ctMerchant + ' Voucher' AND RewValidTill >= @ctDate))
				SET @discountedAmount = (SELECT SUM(RewAmount) FROM Reward WHERE RewID = @rewardId AND (RewStatus = 'Available' AND RewCCNo = @ctccNo) AND (RewDesc = @ctMerchant + ' Voucher' AND RewValidTill >= @ctDate))

				IF (@ctAmount - @discountedAmount) < 0 -- If discounted amt is more than total amt
				BEGIN
					SET @ctAmount = 0.00
					SET @discountedAmount = 0.00
				END
				-- Sufficient balance in Credit Card	
				IF (SELECT CCCurrentBal FROM CreditCard WHERE CCNo = @ctccNo) - (@ctAmount - @discountedAmount) >= 0 --Total amt - discounted amt
				BEGIN	
				-- Update Rewards (Date and Status)
					UPDATE Reward SET RewRedeemDate = @ctDate, RewStatus = 'Claimed' WHERE RewID = @rewardId 
				-- Insert CardTransactions
					INSERT INTO CardTransaction (CTNo, CTMerchant, CTAmount, CTDate, CTStatus, CTCCNo, CTCCSNo)
						VALUES (@ctno, @ctMerchant,@ctAmount - @discountedAmount, @ctDate, 'Pending', @ctccNo,NULL) -- Default "Pending" as customer have not paid and NULL as CC statement not out
				-- Update Credit Card Balance 
				UPDATE CreditCard SET CCCurrentBal = CCCurrentBal - (@ctAmount - @discountedAmount) WHERE (CCNo = @ctccNo) 
				PRINT @discountedAmount 
				PRINT @ctAmount 
				END

				-- Insufficient balance in Credit Card	
				ELSE
				BEGIN
				-- Insert CardTransactions
					INSERT INTO CardTransaction (CTNo, CTMerchant, CTAmount, CTDate, CTStatus, CTCCNo, CTCCSNo)
						VALUES (@ctno, @ctMerchant,@ctAmount - @discountedAmount, @ctDate, 'Failed', @ctccNo,NULL) -- Default "Failed" as credit card balance insufficient
				END
			END
			ELSE 
				RETURN -303 -- Reward not available
		END

		-- Customer do not want to claim reward when having transaction
		ELSE IF @input = 'N'
        BEGIN
			-- Check if credit card sufficient to deduct -- Able to deduct 
			IF (SELECT CCCurrentBal FROM CreditCard WHERE CCNo = @ctccNo) - @ctAmount >= 0
			BEGIN
				-- Insert CardTransactions
				INSERT INTO CardTransaction (CTNo, CTMerchant, CTAmount, CTDate, CTStatus, CTCCNo, CTCCSNo)
                    VALUES (@ctno, @ctMerchant, @ctAmount, @ctDate, 'Pending', @ctccNo,NULL) -- Default "Pending" as customer have not paid and NULL as CC statement not out
				-- Update Credit Card Balance 
				UPDATE CreditCard SET CCCurrentBal = CCCurrentBal - @ctAmount WHERE CCNo = @ctccNo
			END
			-- For unsuccessful transactions due to insufficient amount, set status to failed
			ELSE
				INSERT INTO CardTransaction (CTNo, CTMerchant, CTAmount, CTDate, CTStatus, CTCCNo, CTCCSNo)
					VALUES (@ctno, @ctMerchant, @ctAmount, @ctDate, 'Failed', @ctccNo,NULL) -- Default "Pending" as customer have not paid and NULL as CC statement not out
		END
	END
    ELSE
        RETURN -302 -- Credit Card not Active
END
ELSE
	RETURN -301 -- Credit Card does not exist

IF @@ERROR<>0
	RETURN -404

GO
-- Delete Transaction  -- Toh Wee Kiat, Ernest S10221816B
CREATE PROC uspDeleteTransaction
(@CTNo char(10))
AS
IF EXISTS (select CTNo from CardTransaction where CTNo = @CTNo) -- check whether transaction exist
	BEGIN
		IF (SELECT CTStatus from CardTransaction where CTNo = @CTNo) = 'Pending' -- ensure transaction has not gone through
			BEGIN
				DELETE FROM CardTransaction
				WHERE CTNo = @CTNo
			END
		ELSE
			BEGIN 
				RETURN -602 -- ctstatus not pending
			END
	END
ELSE
	RETURN -601 -- transaction does not exist
IF @@ERROR<>0
	RETURN -404
GO


-- Reward -- Toh Wee Kiat, Ernest S10221816B
IF EXISTS ( SELECT * FROM SYSOBJECTS 
    WHERE  Name = 'trigCheckReward' AND Type = 'TR')
        DROP TRIGGER trigCheckReward
GO

CREATE TRIGGER trigCheckReward
ON CardTransaction AFTER INSERT
AS
    DECLARE @TransAmount SMALLMONEY
    DECLARE @CTMerchant VARCHAR(100)
    DECLARE @CTDate DATETIME
    DECLARE @CTCCNo CHAR(16)
    DECLARE @CTStatus VARCHAR(10)

    SET @TransAmount = (SELECT i.CTAmount FROM inserted i)
    SET @CTMerchant  = (SELECT i.CTMerchant FROM inserted i)
    SET @CTDate = (SELECT i.CTDate FROM inserted i)
    SET @CTCCNo = (SELECT i.CTCCNo FROM inserted i)
    SET @CTStatus = (SELECT i.CTStatus FROM inserted i)

    IF @CTStatus <> 'Failed' -- Transaction is successful, reward is eligible 
    BEGIN
        IF @TransAmount BETWEEN 500 AND 999.99
        BEGIN
            INSERT INTO Reward(RewDesc, RewAmount, RewValidTill, RewRedeemDate, RewStatus, RewCCNo) VALUES (@CTMerchant + ' Voucher', 5.00, DATEADD(MONTH, 6, @CTDate), NULL, 'Available', @CTCCNo)
        END 
        ELSE IF @TransAmount >= 1000
        BEGIN
            INSERT INTO Reward(RewDesc, RewAmount, RewValidTill, RewRedeemDate, RewStatus, RewCCNo) VALUES (@CTMerchant + ' Voucher', 10.00, DATEADD(MONTH, 6, @CTDate), NULL, 'Available', @CTCCNo)
        END
    END

GO
-- Delete trigger -- Toh Wee Kiat, Ernest S10221816B
CREATE TRIGGER trigDeleteTransaction
on CardTransaction
INSTEAD OF DELETE
AS
BEGIN
	UPDATE CardTransaction
		SET CTStatus = 'Failed'
		where CTNo = (Select d.CTNo from deleted d)
END
GO
------------------------------------------------------------------------------------------------------------ 
/* In continuation to CustomerCCCTView, Search Customer and Month */   --- Toh Wee Kiat, Ernest S10221816B
IF EXISTS ( SELECT * FROM SYSOBJECTS 
    WHERE  Name = 'uspSearchCustomerTransaction' AND Type = 'P')
        DROP PROC uspSearchCustomerTransaction
GO

CREATE PROC uspSearchCustomerTransaction
(@cNRIC char(9),@ctMonth SMALLINT)
AS
IF NOT EXISTS (SELECT * FROM Customer WHERE CustNRIC = @cNRIC) 
    RETURN -104 -- Customer not found

IF @ctMonth NOT BETWEEN 1 AND 12 or NOT EXISTS (SELECT * FROM CardTransaction WHERE MONTH(CTDATE) = @ctMonth)
    RETURN -106 -- Month not found

SELECT * FROM CustomerCCCTView WHERE MONTH(CTDate) = @ctMonth
RETURN
GO

------------------------------------------------------------------------------------------------------------
--########################################################################################################--
------------------------------------------------------------------------------------------------------------
/*
return values:
-501: Statement does not Exist
-502: Statement Number already exists
-503: No Transactions Available
-504: Statement is Fully Paid
-505: Value Entered Is More Than Amount Due 
*/

-------------------------------------------------------------create a new monthly bill--------------------------------------------------
--Mandy Tang Min Yee S10218941C
--proc is used to make a new monthly bill for the specified creditcard on the specified date for the specified card.
--when a statement is made, the CTStatus in CardTransaction Table will be set from pending to billed
--only those with CTStatus = 'Pending' Should be added. those with CTStatus failed should be left alone

create proc uspCreateMonthlyBill(@StatementNo char(10), @date varchar(15), @cardNo char(16))
as

--check if date added is a valid date, else give error -404
if isdate(convert(datetime, @date)) = 1
begin 

--if statement number already exists, give error code -502
if exists(select * from CreditCardStatement where CCSNo = @StatementNo)
begin
print('Statement Number Already Exists')
return -502
end

-- if there is no transactions with CTStatus = pending for the given card and date, give error status -503
else if not exists(select * from CardTransaction where
CTCCNo = @CardNo
and month(CTDate) = month(@date)
and year(CTDate) = year(@date)
and CTCCSNo is null
and CTStatus = 'Pending')
begin print('No Transactions Available')
return -503
end

--if all valid, 
else begin

--declare 3 values, the amount due, amount to cash back, and amount to bring over
declare @TransAmount smallmoney
declare @Cashback smallmoney
declare @BringOver smallmoney

--set the Transamount, aka value due for billing and payment 
set @TransAmount = (Select sum(CTAmount) from CardTransaction
where CTCCNo = @CardNo
and month(CTDate) = month(@date)
and year(CTDate) = year(@date)
and CTStatus = 'Pending')

--based on conditions, set the cash back amount using if else statements
--if amoount due is more than 5000, cashback = 50
--if amount due is 800-5000, cashback = 1% of amount due
--is amount due is less than 800, cashback = 0

if @TransAmount >= 5000 begin set @Cashback = 50 end
else if @TransAmount between 800 and 5000 begin set @Cashback = @TransAmount/100 end
else if @TransAmount < 800 begin set @Cashback = 0 end

--set bring over, aka amount overdued from the previous bill
--find bringover amount by selecting top 1 in innerjoin statement.
--This is because the select statement without top 1 will bring back duplicate amounts
--not having top 1 but using sum instead will cause multiple counts for only 1 bring over value

set @BringOver = (select top 1 s.CCSTotalAmountDue from CreditCardStatement s inner join CardTransaction t
on t.CTCCSNo = s.CCSNo
where t.CTCCNo = @cardNo
and month(CTDate) = month(DATEADD(month, -1, @date))
and year(CTDate) = year(DATEADD(month, -1, @date)))

--if the bringover amount is less than 0, set it at 0
--if there are no previous bills since the card is new, the bring over will be null. if bringover is null, set bring over to 0 to bypass error

if @BringOver < 0 begin set @BringOver = 0 end
else if @BringOver is null begin set @BringOver = 0 end

--insert values to credicardstatement table
--CCSCashback is cashback value calculated earlier
--CCSTotalAmountDue is (Amount due calculated earlier - Cashback + Bringover)

insert into CreditCardStatement
values(@StatementNo,
EOMONTH(@date), --end of month of the date of the transaction 
dateadd(week, 3, EOMONTH(@date)),
@Cashback,
(@TransAmount - @Cashback + @BringOver))

--update the cardtransaction records to have the CTCCSNo be the statement number input
update CardTransaction set CTCCSNo = @StatementNo where 
CTCCNo = @CardNo
and month(CTDate) = month(@date)
and year(CTDate) = year(@date)
and CTStatus = 'Pending'

--update the status of the transactions specified from pending to billed
update CardTransaction set CTStatus = 'Billed' where 
CTCCSNo = @StatementNo

--reset the creditcard balance to the limit for the new month
update CreditCard set CCCurrentBal = CCCreditLimit where
CCNo = @cardNo

--set the brought over value to be 0,
--assumption example
--if the bill from october has overdue balance of 500,
--the 500 will be added to the amount due for the bill from november
--then the amount due from october will be 0 since it is brought over

update CreditCardStatement set CCSTotalAmountDue = 0 where
CCSNo = (select top 1 s.CCSNo from CreditCardStatement s
inner join CardTransaction t
on t.CTCCSNo = s.CCSNo
where t.CTCCNo = @cardNo
and month(CTDate) = month(DATEADD(month, -1, @date))
and year(CTDate) = year(DATEADD(month, -1, @date)))

end
end

else
begin
print('System Error')
RETURN -404
end

GO
-----------------------------------------------------Pay Monthly Bill----------------------------------------------------------
--Mandy Tang Min Yee S10218941C
--proc is used to pay the monthly bill, aka CCSTotalAmountDue in the credicard statement table, Statement is fully paid when the amount due is 0
create proc uspPayMonthlyBill(@StatementNo char(10), @PaymentAmount smallmoney) as

--if the statement number does not exist, give error code
if not exists(select * from CreditCardStatement where CCSNo = @StatementNo)
begin
print('Statement Does Not Exist')
return -501
end

--if the statement exists  but the amount due is 0, aka fully paid already, give error code
if exists(select * from CreditCardStatement where CCSNo = @StatementNo and CCSTotalAmountDue = 0)
begin
print('Statement Is Fully Paid')
return -504
end

-- if the payment input is more than amount due, give error code
else if @PaymentAmount > (select CCSTotalAmountDue from CreditCardStatement where CCSNo = @StatementNo)
begin
print('Value Entered Is More Than Amount Due')
return -505
end

--set amount due to the new amount due
else update CreditCardStatement set CCSTotalAmountDue = (CCSTotalAmountDue - @PaymentAmount) where CCSNo = @StatementNo

go
---------------------------------------------- search monthly bill -----------------------------------------------------------------------------
--Mandy Tang Min Yee S10218941C
-- this proc allows the user to search for a specific customer's monthly statements and their payment statuses
create proc uspSearchMonthlyBillPayments(@CustId char(8), @CCSdate varchar(15) = null)
as

--if the customer does not exist, return an error code
if not exists(select * from Customer where CustId = @CustId)

begin
print('Customer Not Found')
return -104
end

--if the date is not given then return all statement payment details for the specified customer
else if @CCSdate is null

begin

select distinct c.CustId , cc.CCNo, t.CTStatus, s.CCSNo, s.CCSTotalAmountDue, s.CCSDate, s.CCSPayDueDate
from Customer c inner join CreditCard cc on c.CustId = cc.CCCustId
inner join CardTransaction t on t.CTCCNo = cc.CCNo
inner join CreditCardStatement s on s.CCSNo = t.CTCCSNo
where
c.CustId = @CustId

end

--if the date added is a valid date, begin the next lines. else, give error -404
else if isdate(convert(datetime, @CCSdate)) = 1 and @CCSdate is not null

begin
--if the statement they want does not exist, return error code
if not exists (select distinct *
from Customer c inner join CreditCard cc on c.CustId = cc.CCCustId
inner join CardTransaction t on t.CTCCNo = cc.CCNo
inner join CreditCardStatement s on s.CCSNo = t.CTCCSNo
where
c.CustId = @CustId
and month(s.CCSDate) = month(@CCSdate)
and year(s.CCSDate) = year(@CCSdate))

begin
print('Statement does not Exist')
return -501
end

else

--if all valid then return statement details for given customer and date
begin
select distinct c.CustId , cc.CCNo, t.CTStatus, s.CCSNo, s.CCSTotalAmountDue, s.CCSDate, s.CCSPayDueDate
from Customer c inner join CreditCard cc on c.CustId = cc.CCCustId
inner join CardTransaction t on t.CTCCNo = cc.CCNo
inner join CreditCardStatement s on s.CCSNo = t.CTCCSNo
where c.CustId = @CustId
and month(s.CCSDate) = month(@CCSdate)
and year(s.CCSDate) = year(@CCSdate)

end
end

else
begin
print('System Error')
RETURN -404
end
go
