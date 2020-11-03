--Question 1: Write a query that will determine the top 10 most abandoned products.

IF OBJECT_ID(N'tempdb..#jump_basket') IS NOT NULL
BEGIN
	DROP TABLE #jump_basket
END

IF OBJECT_ID(N'tempdb..#table_with_rownumber') IS NOT NULL
BEGIN
	DROP TABLE #table_with_rownumber
END


CREATE TABLE #jump_basket
	(Basket_ID NVARCHAR(1))

SELECT	User_ID
		,Session_ID
		,Basket_ID
		,ROW_NUMBER() OVER(ORDER BY User_ID, Session_ID) AS rownum
	INTO #table_with_rownumber
FROM dbo.Baskets


DECLARE @rownumber AS INT
DECLARE @rownumberMAX AS INT
SET @rownumber=1
SET @rownumberMAX = (SELECT COUNT(*) FROM dbo.Baskets)


WHILE (@rownumber <= @rownumberMAX-1)
BEGIN
	
	IF ((SELECT User_ID FROM #table_with_rownumber WHERE rownum=@rownumber) = (SELECT User_ID FROM #table_with_rownumber WHERE rownum=@rownumber+1))  
	AND ((SELECT Session_ID FROM #table_with_rownumber WHERE rownum=@rownumber) = (SELECT Session_ID FROM #table_with_rownumber WHERE rownum=@rownumber+1)) 
	AND ((SELECT Basket_ID FROM #table_with_rownumber WHERE rownum=@rownumber) != (SELECT Basket_ID FROM #table_with_rownumber WHERE rownum=@rownumber+1))
	
	BEGIN	
		INSERT INTO #jump_basket 
		SELECT Basket_ID FROM #table_with_rownumber WHERE rownum=@rownumber
	END
	
	SET @rownumber = @rownumber +1
END


SELECT	TOP 10(Product_Name)
		,COUNT(Product_name) as Qty_Abandoned 
FROM dbo.Baskets 
WHERE Basket_ID in (SELECT Basket_ID FROM dbo.Baskets EXCEPT SELECT Basket_ID FROM dbo.Sales EXCEPT SELECT Basket_ID FROM #jump_basket)
GROUP BY Product_Name 
ORDER BY Qty_Abandoned DESC







--Question 2: Write a query that will show the month on month change in the total value of sales in 2020.

SELECT	* 
		,LAG(M.Monthly_Sale) OVER (ORDER BY M.Month) AS Previous_Month_Sale 
		,(M.Monthly_Sale - LAG(M.Monthly_Sale) OVER (ORDER BY M.Month)) AS Monthly_Diff
FROM
		(
		SELECT	Month(Time_stamp) as Month
				,SUM(Sales_value) as Monthly_Sale
		FROM	dbo.Sales 
		GROUP BY Month(Time_stamp)
		) M







--Question 3: Write a query that will show what percentage of users who only purchase once.

--SOLUTION 1

SELECT 100*COUNT(*)/(SELECT COUNT(DISTINCT(User_ID)) FROM dbo.Baskets) AS percent_once_only 

	FROM
	
	(
	SELECT COUNT(UB.User_ID) as user_orders, UB.User_ID 
	FROM
		
		(
		SELECT	DISTINCT(S.Basket_ID)
				,B.User_ID 
		FROM dbo.Sales AS S
		LEFT JOIN dbo.Baskets AS B
		ON S.Basket_ID=B.Basket_ID
		) AS UB

	GROUP BY UB.User_ID
	) UO

WHERE user_orders=1



--SOLUTION 2: JUST SO THAT WE COULD USE THE DERIVED TABLE FROM THIS QUERY WITHIN OUR NEXT QUERY

IF OBJECT_ID(N'tempdb..#paid_user_baskets') is not null
BEGIN
	DROP TABLE #paid_user_baskets
END


SELECT	DISTINCT(S.Basket_ID)
				,S.Time_stamp
				,B.User_ID 
		INTO #paid_user_baskets
		FROM dbo.Sales AS S
		LEFT JOIN dbo.Baskets AS B
		ON S.Basket_ID=B.Basket_ID



SELECT 100*COUNT(*)/(SELECT COUNT(DISTINCT(User_ID)) FROM dbo.Baskets) AS percent_once_only 

	FROM
	
	(
	SELECT COUNT(User_ID) as user_orders, User_ID 
	FROM #paid_user_baskets GROUP BY User_ID having COUNT(User_ID)=1
	) X








--Question 4: Write a query that will show on average how many days users take to purchase again.

IF OBJECT_ID(N'tempdb..#purchase_frequency') IS NOT NULL
BEGIN
	DROP TABLE #purchase_frequency
END


CREATE TABLE #purchase_frequency 
	(avg_days INT)

DECLARE @users AS INT
DECLARE @usersmax AS INT
SET @usersmax = (SELECT MAX(User_ID) FROM dbo.Baskets)
SET @users=1


WHILE (@users <= @usersmax)

BEGIN

	INSERT INTO #purchase_frequency

	SELECT AVG(day_diff) 
	FROM
	(

	SELECT	*
			,LAG(Time_stamp) OVER(ORDER BY Basket_ID) AS last_time
			,DATEDIFF(d,LAG(Time_stamp) OVER(ORDER BY Basket_ID),Time_stamp) AS day_diff
	FROM
		(
		SELECT	* 
		FROM #paid_user_baskets
		WHERE User_ID=@users  
		) C

	) X

	SET @users=@users+1

END


SELECT AVG(avg_days) AS purchase_frequency_days 
FROM #purchase_frequency 
WHERE avg_days IS NOT NULL








-- Question 5: Assume that the following query takes a long time to run. How could you optimise it to improve the performance?
'
SELECT s.sales_value FROM
(SELECT * FROM BASKETS) b
LEFT JOIN
(SELECT * FROM SALES) s
ON b.basket_id = s.basket_id
WHERE b.user_id = 3 AND b.session_id = 3
AND DATE(b.time_stamp) >= ‘2020-01-01’
'


--SUGGESTED SOLUTION 
--Find the Basket_ID via a sub-query that satisfies the above specified user_id session_id and time_stamp criteria
-- Then do the following .... select sales_value where basket_id are in the results of sub_query

SELECT Sales_value 
FROM Sales 
WHERE Basket_ID in 
	(
	SELECT Basket_ID 
	FROM Baskets
	WHERE User_ID = 3 AND Session_ID = 3 AND DATE(time_stamp) >= '2020-01-01'
	)




