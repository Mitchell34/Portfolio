--Inspecting Data
Select *
From SalesData

--Checking Unique Values
Select Distinct (status)
From SalesData

Select Distinct (year_id)
From SalesData

Select Distinct (productline)
From SalesData

Select Distinct (country)
From SalesData

Select Distinct (dealsize)
From SalesData

Select Distinct (territory)
From SalesData

Select Distinct (month_id)
From SalesData
Where year_id = 2005  --Only 5 months of sales in 2005

--Analysis: grouping sales by productline
Select productline, sum(sales) AS Revenue
From SalesData
Group By productline
Order by 2 DESC

Select year_id, sum(sales) AS Revenue
From SalesData
Group By year_id
Order By 2 DESC

Select dealsize, sum(sales) AS Revenue
From SalesData
Group By dealsize
Order By 2 DESC   -- Medium sized deals lead to most revenue

--Analyzing the best month for sales in a specific year...How much was earned that month?
Select month_id, sum(sales) AS Revenue, Count(ordernumber) AS Frequency
From SalesData
Where year_id = 2004
Group By month_id
Order By 2 DESC

--November appears to be the month with the highest revenue and frequency of sales. What products do they sell the most of?
Select month_id, productline, sum(sales) AS Revenue, Count(ordernumber) AS Frequency
From SalesData
Where year_id = 2003 AND month_id = 11
Group By month_id, productline
Order By 3 DESC

--Who is our best customer (Using RFM Analysis)
DROP TABLE IF EXISTS #rfm
;With RFM AS
(
	Select
		customername,
		sum(sales) AS MonetaryValue,
		avg(sales) AS AvgMonetaryValue,
		count(ordernumber) AS Frequency,
		max(orderdate) AS last_order_date,
		(Select max(orderdate) from SalesData) AS max_order_date,
		DATEDIFF(DD, max(orderdate), (Select max(orderdate) from SalesData)) AS Recency
	From SalesData
	Group By customername
),
rfm_calc AS
(
	Select r.*,
		NTILE(4) OVER (Order By Recency DESC) AS rfm_recency,
		NTILE(4) OVER (Order By Frequency) AS rfm_frequency,
		NTILE(4) OVER (Order By MonetaryValue) AS rfm_monetary
	From RFM r
)
Select
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary AS rfm_cell,
	CAST(rfm_recency as varchar) + CAST(rfm_frequency as varchar) + CAST(rfm_monetary as varchar) AS rfm_cell_string
Into #rfm
From rfm_calc c

Select CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
	CASE
		When rfm_cell_string IN (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'
		When rfm_cell_string IN (133, 134, 143, 244, 334, 343, 344, 221, 144) then 'slipping away, cannot lose'
		When rfm_cell_string IN (311, 411, 331) then 'new customers'
		When rfm_cell_string IN (222, 223, 232, 233, 322, 421, 412, 234) then 'potential churner'
		When rfm_cell_string IN (323, 333, 321, 422, 423, 332, 432) then 'active'
		When rfm_cell_string IN (433, 434, 443, 444) then 'loyal'
	End rfm_segment
From #rfm


--What products are most often sold together?
Select DISTINCT ordernumber, Stuff(
	(Select ',' + productcode
	From SalesData d
	Where ordernumber IN
		(
			Select ordernumber
			From (
				Select ordernumber, COUNT(*) rn
				From SalesData
				Where Status = 'Shipped'
				Group By ordernumber
			)m
			Where rn = 3
		)
		And d.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))
		, 1,1,'') AS ProductCodes
From SalesData s
Order By 2 DESC