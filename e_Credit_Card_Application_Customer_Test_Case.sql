SELECT * FROM Customer 
SELECT * FROM CardTransaction
SELECT * FROM CreditCard
SELECT * FROM CreditCardStatement
SELECT * FROM Reward

DROP DATABASE CreditCardSys
------------------------------------------------------------------------------------------------------------
-- Test Cases for Credit Card Application
-- Part 1.1 (Creating Customer) 
-- Successful Case: Test 1 (Create customer and able to apply for credit card) and Test 2 (Cannot apply cc)
SELECT * FROM Customer

-- Test 1 : Success Case (Eligible to apply for Credit Card)
-- Message return: notification for bank officer to check if he/she is eligible for credit card application.
DECLARE @Status INT
EXEC @Status = uspCreateCustomer @cId = 'C000005', @cNRIC = 'S5555555E', @cName = 'Wong Guo Fung', @cDOB = '1990-01-01', 
@cAddress = 'Blk 555, Clementi Ave 3, #5-555', @cContact = '95555555', 
@cEmail = 'wongguofung@gmail.com', @cAnnualIncome = 100000.00
SELECT 'Status Value' = @Status --Return Status
GO
-- Able to set CustStatus to 'Active' -- Message return Details updated, able to apply for credit card
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerStatus @cNRIC = 'S5555555E', @cStatus = 'Active'
SELECT 'Status Value' = @Status --Return Status
GO

-- Test 2 : Unsuccessful Case (Not eligible to apply for Credit Card, due to AGE not IN [21-70]- More than 70)
-- Message return: notification for bank officer to check if he/she is eligible for credit card application.
DECLARE @Status INT
EXEC @Status = uspCreateCustomer @cId = 'C000006', @cNRIC = 'S6666666F', @cName = 'Jerry Lim', @cDOB = '1930-06-06', 
@cAddress = 'Blk 666, Bishan Street 12, #6-666', @cContact = '96666666', 
@cEmail = 'jerrylim@gmail.com', @cAnnualIncome = 50000.00
SELECT 'Status Value' = @Status --Return Status
GO

-- Unable to set CustStatus to 'Active'
-- Message return: 'Customer not eligible to apply for credit card.'
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerStatus @cNRIC = 'S6666666F', @cStatus = 'Active'
SELECT 'Status Value' = @Status --Return Status
GO

-- Test 3 : Unsuccessful Case (Not eligible to apply for Credit Card, due to AGE not IN [21-70]- Under 21)
-- Message return: notification for bank officer to check if he/she is eligible for credit card application.
DECLARE @Status INT
EXEC @Status = uspCreateCustomer @cId = 'C000007', @cNRIC = 'S7777777G', @cName = 'Lim Hong', @cDOB = '2010-07-07', 
@cAddress = 'Blk 777, Yishun Condo, #7-777', @cContact = '97777777', 
@cEmail = 'limhong@gmail.com', @cAnnualIncome = 50000.00
GO

-- Unable to set CustStatus to 'Active'
-- Message return: 'Customer not eligible to apply for credit card.'
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerStatus @cNRIC = 'S7777777G', @cStatus = 'Active'
SELECT 'Status Value' = @Status --Return Status
GO

-- Test 4 : Unsuccessful Case (Not eligible to apply for Credit Card, due to Salary lower than 30k)
-- Message return: notification for bank officer to check if he/she is eligible for credit card application.
DECLARE @Status INT
EXEC @Status = uspCreateCustomer @cId = 'C000008', @cNRIC = 'S8888888H', @cName = 'Jason Chew', @cDOB = '2000-08-08', 
@cAddress = 'Blk 888, Tanglin Road , #8-888', @cContact = '98888888', 
@cEmail = 'jasonchew@gmail.com', @cAnnualIncome = 25000.00
SELECT 'Status Value' = @Status --Return Status
GO

-- Unable to set CustStatus to 'Active'
-- Message return: 'Customer not eligible to apply for credit card.'
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerStatus @cNRIC = 'S8888888H', @cStatus = 'Active'
SELECT 'Status Value' = @Status --Return Status
GO

SELECT * FROM Customer

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
-- Testing for error returns
SELECT * FROM Customer
-- Test 5 : Unuccessful Case (Cannot create Customer, due to same NRIC - RETURN -101)
DECLARE @Status INT
EXEC @Status = uspCreateCustomer @cId = 'C000009', @cNRIC = 'S1111111A', @cName = 'Ming Ming', @cDOB = '2000-09-09',  -- Same NRIC as 'C000001'
@cAddress = 'Blk 999, Joo Koon Street 9 , #9-999', @cContact = '99999999', 
@cEmail = 'mingx2@gmail.com', @cAnnualIncome = 30000.00
SELECT 'Status Value' = @Status --Return Status
GO

-- Test 6 : Unuccessful Case (Cannot create Customer, due to same email -  RETURN -102)
DECLARE @Status INT
EXEC @Status = uspCreateCustomer @cId = 'C000010', @cNRIC = 'S1010101J', @cName = 'Jason chew', @cDOB = '2000-10-10', 
@cAddress = 'Blk 101, Lakeside Ave 10 , #10-101', @cContact = '91010101', 
@cEmail = 'peter@mymail.com.sg', @cAnnualIncome = 30000.00 -- Same Email as 'C000001'
SELECT 'Status Value' = @Status --Return Status
GO

-- Test 7 : Unuccessful Case (Cannot create Customer, due to NULL values -  RETURN -404)
DECLARE @Status INT
EXEC @Status = uspCreateCustomer @cId = 'C000011', @cNRIC = 'S1111111K', @cName = 'Mikey', @cDOB = '1994-11-11', 
@cAddress = 'Blk 110, Bedok Ave 11 , #11-110', @cContact = NULL, -- Contact No. set to NULL
@cEmail = 'mikey@gmail.com', @cAnnualIncome = 30000.00
SELECT 'Status Value' = @Status --Return Status
GO
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--

------------------------------------------------------------------------------------------------------------
-- Part 1.2 (Updating Customer -- Changing customer status, making customer Active, Suspended)
-- Successful Case: Test 1 w/o CC and Test 2 w cc that is not active , Test 3 w cc that is active
SELECT * FROM Customer

-- Test 1 : Successful Case (Can Create Customer, eligible for Credit Card)
-- Message return: notification for bank officer to check if he/she is eligible for credit card application.
DECLARE @Status INT
EXEC @Status = uspCreateCustomer @cId = 'C000012', @cNRIC = 'S1212121L', @cName = 'Sam Leong', @cDOB = '1992-12-12', 
@cAddress = 'Blk 120, Bukit Merah Street 12, #12-101', @cContact = '91212121', 
@cEmail = 'leongsam@gmail.com', @cAnnualIncome = 30000.00
SELECT 'Status Value' = @Status --Return Status
GO

-- Test 1.1
-- Able to set CustStatus to 'Suspended', w/o credit card 
-- Message return: Customer Status updated
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerStatus @cNRIC = 'S1212121L', @cStatus = 'Suspended'
SELECT 'Status Value' = @Status --Return Status
GO

-- Test 1.2
-- Able to set CustStatus to 'Pending', w/o credit card 
-- Message return: Customer Status updated
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerStatus @cNRIC = 'S1212121L', @cStatus = 'Pending'
SELECT 'Status Value' = @Status --Return Status
GO

SELECT * FROM Customer

-- Test 2 : Successful Case (Can Create Customer, eligible for Credit Card)
-- Message return: notification for bank officer to check if he/she is eligible for credit card application.
DECLARE @Status INT
EXEC @Status = uspCreateCustomer @cId = 'C000013', @cNRIC = 'S1313131N', @cName = 'Terry Koh', @cDOB = '1983-01-13', 
@cAddress = 'Blk 130, Seng Kang Ave 13, #13-130', @cContact = '91313131', 
@cEmail = 'terrykoh@gmail.com', @cAnnualIncome = 50000.00
SELECT 'Status Value' = @Status --Return Status
GO

-- Test 2.1 : Customer with Credit Card Status not active can be set to Suspended (CustStatus)
--Insert Credit Card for testing (Credit Card Status not active)
SELECT * FROM CreditCard

INSERT INTO CreditCard VALUES ('1234567890123456','123','01/2022', 25000, 25000, 'Expired', 'C000013')
-- Able to set CustStatus to 'Suspended', with Credit Card
-- Message return: Customer Status updated
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerStatus @cNRIC = 'S1313131N', @cStatus = 'Suspended'
SELECT 'Status Value' = @Status --Return Status
GO

-- Test 2.2 : Customer with Credit Card Status not active can be set to Pending (CustStatus)
-- Able to set CustStatus to 'Pending', with Credit Card
-- Message return: Customer Status updated
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerStatus @cNRIC = 'S1313131N', @cStatus = 'Pending'
SELECT 'Status Value' = @Status --Return Status
GO

SELECT * FROM Customer

-- Test 3 : Successful Case (Can Create Customer, eligible for Credit Card)
-- Message return: notification for bank officer to check if he/she is eligible for credit card application.
DECLARE @Status INT
EXEC @Status = uspCreateCustomer @cId = 'C000014', @cNRIC = 'S1414141P', @cName = 'Ash Li', @cDOB = '1973-04-14', 
@cAddress = 'Blk 140, Bukit Timah Ave 14, #14-140', @cContact = '91414141', 
@cEmail = 'ashli@hotmail.com', @cAnnualIncome = 75000.00
SELECT 'Status Value' = @Status --Return Status
GO

-- Test 3.1 : Customer with Credit Card Status active cannot be set to 'Suspended' or 'Pending' (CustStatus)
INSERT INTO CreditCard VALUES ('1345678902123456','234','01/2025', 37500, 37500, 'Active', 'C000014')
-- Message return : Customer credit card still active
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerStatus @cNRIC = 'S1414141P', @cStatus = 'Pending'
SELECT 'Status Value' = @Status --Return Status
GO

-- Need to change Credit Card Status to some other than Active to update Customer Status 
UPDATE CreditCard SET CCStatus = 'Expired' WHERE CCCustId ='C000014'
-- Message return : Customer status is updated.
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerStatus @cNRIC = 'S1414141P', @cStatus = 'Pending'
SELECT 'Status Value' = @Status --Return Status
GO

SELECT * FROM Customer
SELECT * FROM CreditCard
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
-- Testing for error returns

-- Test 3 : Unsuccessful Case (Customer not found - RETURN -104)
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerStatus @cNRIC = 'S1515151Q', @cStatus = 'Pending' -- CustNRIC not found
SELECT 'Status Value' = @Status --Return Status
GO

-- Test 4 : Unsuccessful Case (Status not in option - RETURN -105)
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerStatus @cNRIC = 'S1313131N', @cStatus = 'Cancelled'
SELECT 'Status Value' = @Status --Return Status
GO

------------------------------------------------------------------------------------------------------------
-- Part 1.3 (Updating Customer -- Changing customer personal details)
-- Successful Case: Test 1 Change all personal details except for income, Test 2 Change income 
SELECT * FROM Customer

-- Test 1 : Successful case (Everything change except income)
-- Message return: Customer details updated
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerDetails @cNRIC = 'S5555555E', @cName = 'Wong Xiao Feng',
@cAddress = 'Blk 000, Jurong West Street 10, #5-555', @cContact = '98367999', @cEmail  = 'xiaofeng@gmail.com'
SELECT 'Status Value' = @Status --Return Status
GO

-- Test 2 : Successful case (Only change income -- Message return, alert change in salary)
-- Message return: Customer details updated and notification to bank officer to check if he/she is eligible for credit card application
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerDetails @cNRIC = 'S5555555E', @cAnnualIncome = 30000.00
SELECT 'Status Value' = @Status --Return Status
GO

-- Test 3 : Successful case (Only change income -- Message return, alert change in salary, Customer can apply credit card)
-- Message return: Customer details updated and notification to bank officer to check if he/she is eligible for credit card application
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerDetails @cNRIC = 'S8888888H', @cName = NULL, --Jason Chew can create credit card now
@cAddress = NULL, @cContact = NULL, @cEmail  = NULL,  @cAnnualIncome = 30000.00
SELECT 'Status Value' = @Status --Return Status
GO

SELECT * FROM Customer
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
-- Testing for error returns

-- Test 4 : Unsuccessful case (RETURN -103 - No Attributes Entered)
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerDetails @cNRIC = 'S8888888H'
SELECT 'Status Value' = @Status --Return Status
GO

-- Test 4 : Unsuccessful case (RETURN -104 - Customer not in table)
DECLARE @Status INT
EXEC @Status = uspUpdateCustomerDetails @cNRIC = 'S8888888Z', @cName = 'Ray'
SELECT 'Status Value' = @Status --Return Status
GO

------------------------------------------------------------------------------------------------------------
-- Part 1.4 (Stop Delete Customer )

-- Test 1 : Successful case (Message return - cannot delete customer)
-- Message return: 'Customer is not deleted, consider changing the customer status instead'
DELETE Customer WHERE CustNRIC = 'S5555555E'
GO

------------------------------------------------------------------------------------------------------------
/* Test for views */

-- Part 1.5 (Search Customer Earned Reward for given month - Using Views: CustomerEarnRewardView)

-- Test 1: Successful case (Show customer and card transcation details with rewards earned for the particular month - October)
-- Betty Phua will be shown
DECLARE @Status INT
EXEC @Status = uspSearchCustomerEarnReward @date = '2022-10-01'
SELECT 'Status Value' = @Status --Return Status
GO

-- Test 2: Successful case (Show customer and card transcation details with rewards earned for the particular month - September)
-- Petter Chew will be shown
DECLARE @Status INT
EXEC @Status = uspSearchCustomerEarnReward @date = '2022-09-01'
SELECT 'Status Value' = @Status --Return Status
GO

-- Test 3: Successful case (Show all customer that earned rewards for all year and month)
-- Petter Chew and Betty Chua shown
SELECT * FROM CustomerEarnRewardView

------------------------------------------------------------------------------------------------------------
--########################################################################################################--
------------------------------------------------------------------------------------------------------------
