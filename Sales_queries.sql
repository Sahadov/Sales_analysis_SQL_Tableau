-- ANALYSING SALES DATA USING SQL
-- SKILLS USED: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Conditions usage, Buckets Division, RFM-analys, Creating Tables, 


USE project_sales;

select * from sales_data;

-- Checking unique values
select distinct status from sales_data;
select distinct year_id from sales_data;
select distinct productline from sales_data;
select distinct territory from sales_data;
select distinct dealsize from sales_data;

-- Total revenues by productlines
select PRODUCTLINE, round((SUM(SALES)), 2) as REVENUE
from sales_data
group by PRODUCTLINE
order by 2 desc;

-- Total revenues by years
select YEAR_ID, round((SUM(SALES)), 2) as REVENUE
from sales_data
group by YEAR_ID
order by 2 desc;

-- Total revenues by dealsize
select DEALSIZE, round((SUM(SALES)), 2) as REVENUE
from sales_data
group by DEALSIZE
order by 2 desc;

-- What was the best month in the specific year?
select MONTH_ID, round((SUM(SALES)), 2) as REVENUE, COUNT(ORDERNUMBER) as FREQUENCY
from sales_data
where YEAR_ID = 2003
group by MONTH_ID
order by 2 desc;

--November seems to be the best saling month. What product do they sell in November the most?
select  MONTH_ID, PRODUCTLINE, round((SUM(SALES)), 2) as REVENUE, count(ORDERNUMBER) as FREQUENCY
from sales_data
where YEAR_ID = 2004 and MONTH_ID = 11
group by  MONTH_ID, PRODUCTLINE
order by 3 desc;

-- RFM

with rfm as (
	select 
			CUSTOMERNAME, 
			SUM(SALES) as MONETARY_VALUE,
			AVG(SALES) as AVG_MONETARY_VALUE,
			COUNT(ORDERNUMBER) as FREQUENCY,
			MAX(ORDERDATE) as LAST_ORDER_DATE,
			(select MAX(ORDERDATE) from sales_data) as MAX_ORDER_DATE,
			DATEDIFF(
				(select MAX(ORDERDATE) from sales_data),
				MAX(ORDERDATE)
			) as RECENCY
	from sales_data
	group by CUSTOMERNAME
),
rfm_calc as (
	select r.*,
			NTILE(4) OVER (order by Recency desc) rfm_recency,
			NTILE(4) OVER (order by Frequency) rfm_frequency,
			NTILE(4) OVER (order by Monetary_Value) rfm_monetary
	from rfm r
)

select 
	c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	CONCAT(rfm_recency, rfm_frequency, rfm_monetary) rfm_cell_string
from rfm_calc c;


-- Create RFM-table

DROP Table if exists project_sales.rfm_data;
Create Table project_sales.rfm_data
(
CUSTOMERNAME nvarchar(255),
MONETARY_VALUE numeric,
AVG_MONETARY_VALUE numeric,
FREQUENCY numeric,
LAST_ORDER_DATE datetime,
MAX_ORDER_DATE datetime,
RECENCY numeric,
RFM_RECENCY numeric,
RFM_FREQUENCY numeric,
RFM_MONETARY numeric,
RFM_CELL numeric,
RFM_CELL_STRING numeric
);

Insert into project_sales.rfm_data
with rfm as (
	select 
			CUSTOMERNAME, 
			SUM(SALES) as MONETARY_VALUE,
			AVG(SALES) as AVG_MONETARY_VALUE,
			COUNT(ORDERNUMBER) as FREQUENCY,
			MAX(ORDERDATE) as LAST_ORDER_DATE,
			(select MAX(ORDERDATE) from sales_data) as MAX_ORDER_DATE,
			DATEDIFF(
				(select MAX(ORDERDATE) from sales_data),
				MAX(ORDERDATE)
			) as RECENCY
	from sales_data
	group by CUSTOMERNAME
),
rfm_calc as (
	select r.*,
			NTILE(4) OVER (order by Recency desc) rfm_recency,
			NTILE(4) OVER (order by Frequency) rfm_frequency,
			NTILE(4) OVER (order by Monetary_Value) rfm_monetary
	from rfm r
)

select 
	c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	CONCAT(rfm_recency, rfm_frequency, rfm_monetary) rfm_cell_string
from rfm_calc c;

select * from rfm_data;

-- Segmentazing the customers

select CUSTOMERNAME , RFM_RECENCY, RFM_FREQUENCY, RFM_MONETARY,
		case 
		when RFM_CELL_STRING in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'Lost customers'
		when RFM_CELL_STRING in (133, 134, 143, 244, 334, 343, 344, 144) then 'Slipping away, can lose'
		when RFM_CELL_STRING in (311, 411, 331) then 'New customers'
		when RFM_CELL_STRING in (222, 223, 233, 322) then 'Potential churners'
		when RFM_CELL_STRING in (323, 333,321, 422, 332, 432) then 'Active'
		when RFM_CELL_STRING in (433, 434, 443, 444) then 'Loyal'
	end rfm_segment
from rfm_data



