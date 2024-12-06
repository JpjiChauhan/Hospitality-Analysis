create database hospitality_analysis;
use hospitality_analysis;
select * from fact_aggregated_bookings;
select * from fact_bookings;
select * from dim_date;
select * from dim_hotels;
select * from dim_rooms;
SET SQL_SAFE_UPDATES=0;

ALTER TABLE fact_aggregated_bookings ADD COLUMN occupancy DECIMAL(5, 2);
UPDATE fact_aggregated_bookings SET occupancy = ROUND(successful_bookings / capacity * 100, 2);



-- 1. Total Revenue)
SELECT 
CASE
WHEN SUM(revenue_realized)>=1000000000 THEN CONCAT(ROUND(SUM(revenue_realized)/1000000000,1),'B')
WHEN SUM(revenue_realized)>=1000000 THEN CONCAT(ROUND(SUM(revenue_realized)/1000000,1),'M')
WHEN SUM(revenue_realized)>=1000 THEN CONCAT(ROUND(SUM(revenue_realized)/1000,1),'K')
ELSE SUM(revenue_realized)
END 
 AS Total_revenue 
 FROM fact_bookings;


-- 2. Occupancy %
SELECT ROUND(SUM(successful_bookings)/(SUM(capacity)) * 100, 2) AS `OCCUPANCY %` FROM fact_aggregated_bookings;


-- 3. Cancellation Rate
SELECT 
CONCAT(ROUND(COUNT(*)/1000,1),'K') AS total_bookings,
CONCAT(ROUND(SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END)/1000,1),'K') AS cancellations,
CONCAT(ROUND((SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*)) * 100,2),'%') AS cancellation_rate
FROM fact_bookings;


-- 4. Total Booking
SELECT CONCAT(ROUND(COUNT(booking_id)/1000,1),'K') AS Total_booking FROM fact_bookings;


-- 5. Total Capacity
SELECT CONCAT(ROUND(SUM(capacity)/1000,1),'K') AS `TOTAL CAPACITY` FROM fact_aggregated_bookings;


-- 6. Trend Analysis
SELECT 
DATE_FORMAT(booking_date, '%Y-%m') AS Month,
CONCAT(ROUND(COUNT(*)/1000,2),'K') AS Total_bookings,
CASE 
WHEN SUM(revenue_realized)>=1000000 THEN CONCAT(ROUND(SUM(revenue_realized)/1000000,1),'M') 
WHEN SUM(revenue_realized)>=1000 THEN CONCAT(ROUND(SUM(revenue_realized)/1000,1),'K') 
ELSE SUM(revenue_realized)
END AS Total_revenue
FROM fact_bookings
GROUP BY month
ORDER BY month;


-- 7. Weekday  & Weekend  Revenue and Booking
SELECT 
d.Day_type,
CONCAT(ROUND(COUNT(b.booking_id)/1000,1),'K') AS Total_bookings,
CONCAT(ROUND(COUNT(b.booking_id)/(SELECT COUNT(*) FROM fact_bookings) * 100,2),'%') AS `Total_bookings(%)`,
CASE 
WHEN SUM(b.revenue_realized)>=1000000 THEN CONCAT(ROUND(SUM(b.revenue_realized)/1000000,1),'M') 
WHEN SUM(b.revenue_realized)>=1000 THEN CONCAT(ROUND(SUM(b.revenue_realized)/1000,1),'K') 
ELSE SUM(b.revenue_realized)
END AS Total_revenue,
CONCAT(ROUND(SUM(b.revenue_realized)/(SELECT SUM(revenue_realized) FROM fact_bookings) * 100,2),'%') AS `Total_revenue(%)`
FROM fact_bookings b
JOIN dim_date d ON b.check_in_date = d.date
GROUP BY d.day_type;


-- 8.  Revenue by State & hotel
SELECT 
h.city as city, 
h.property_name AS property_name, 
CASE 
WHEN SUM(b.revenue_realized)>=1000000 THEN CONCAT(ROUND(SUM(b.revenue_realized)/1000000,1),'M') 
WHEN SUM(b.revenue_realized)>=1000 THEN CONCAT(ROUND(SUM(b.revenue_realized)/1000,1),'K') 
ELSE SUM(b.revenue_realized)
END AS Revenue 
FROM fact_bookings b join dim_hotels h ON b.property_id=h.property_id 
GROUP BY city, property_name 
ORDER BY city;


-- 9. Class Wise Revenue
SELECT 
Room_category,
CASE
	WHEN SUM(revenue_realized)>=1000000 THEN CONCAT(ROUND(SUM(revenue_realized)/1000000,1),'M') 
	WHEN SUM(revenue_realized)>=1000 THEN CONCAT(ROUND(SUM(revenue_realized)/1000,1),'K')
	ELSE SUM(revenue_realized)
	END AS Class_revenue
FROM fact_bookings
GROUP BY room_category;


-- 10. Checked out, cancelled, No show
SELECT 
booking_status,
CONCAT(ROUND(COUNT(*)/1000,1),'K') AS total_count
FROM fact_bookings
GROUP BY booking_status;


-- 11. Weekly trend Key trend (Revenue, Total booking, Occupancy) 
CREATE TEMPORARY TABLE weekly_revenue AS
SELECT 
    d.`week no` AS `week`,
    CASE
    WHEN SUM(b.revenue_realized)>=1000000 THEN CONCAT(ROUND(SUM(b.revenue_realized)/1000000,1),'M') 
    WHEN SUM(b.revenue_realized)>=1000 THEN CONCAT(ROUND(SUM(b.revenue_realized)/1000,1),'K')
    ELSE SUM(b.revenue_realized)
    END AS Total_revenue,
    CONCAT(ROUND(COUNT(b.booking_id)/1000,1),'K') AS Total_bookings
FROM fact_bookings b JOIN dim_date d ON d.`date` = b.booking_date
GROUP BY d.`week no`;                          -- Temporary table

DROP TEMPORARY TABLE IF EXISTS weekly_revenue; -- Drop temporary table
SELECT * FROM weekly_revenue;

SELECT 
    w.`week`,
	ANY_VALUE(w.Total_revenue) as Total_revenue,
    ANY_VALUE(w.Total_bookings) as Total_booking,
    ROUND(AVG(a.occupancy), 2) AS `Average_occupancy(%)`
FROM weekly_revenue w JOIN fact_aggregated_bookings a ON w.`week`= a.week_num
GROUP BY  w.`week`
ORDER BY w.week;





