/*
The purpose of this project is to analyze a dataset concerning sales events within a website. It is in particular an e-commerce domain and that's mostly a sales funnel analysis, with the aim of providing business insights.
*/

-- Step 1: exploring the dataset and understanding what kind of data we are dealing with
SELECT 
* 
FROM dbo.user_events 

-- Step 2: let's proceed with a CTE to define sales funnel and the different stages 
;WITH funnel_stages AS (
    SELECT 
      COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS stage1_views,
      COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS stage2_cart,
      COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage3_checkout,
      COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS stage4_payment,
      COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS stage5_purchase
    FROM dbo.user_events
)

SELECT * FROM funnel_stages;


-- Step 3: find the conversion rates through the funnel
; WITH funnel_stages AS (
    SELECT 
      COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS stage1_views,
      COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS stage2_cart,
      COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage3_checkout,
      COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS stage4_payment,
      COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS stage5_purchase
    FROM dbo.user_events
)

SELECT 
  stage1_views, 
  stage2_cart,
  ROUND(stage2_cart * 100 / NULLIF(stage1_views, 0), 2) AS view_to_cart_rate,
  stage3_checkout,
  ROUND(stage3_checkout * 100 / NULLIF(stage2_cart, 0), 2) AS cart_to_checkout_rate,
  stage4_payment,
  ROUND(stage4_payment * 100 / NULLIF(stage3_checkout, 0), 2) AS checkout_to_payment_rate,
  stage5_purchase,
  ROUND(stage5_purchase * 100 / NULLIF(stage4_payment, 0), 2) AS payment_to_purchase_rate,
  ROUND(stage5_purchase * 100 / NULLIF(stage1_views, 0), 2) AS overall_conversion_rate
FROM funnel_stages;


-- Step 4: compare the different marketing channels - funnel by source
; WITH source_funnel AS (
    SELECT
      traffic_source,
      COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS views,
      COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS carts,
      COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchases
    FROM dbo.user_events
    GROUP BY traffic_source
)

SELECT
  traffic_source,
  views,
  carts,
  purchases,
  ROUND(carts * 100 / NULLIF(views, 0), 2) AS cart_conversion_rate,
  ROUND(purchases * 100 / NULLIF(views, 0), 2) AS purchase_conversion_rate,
  ROUND(purchases * 100 / NULLIF(carts, 0), 2) AS cart_to_purchase_conversion_rate
FROM source_funnel
ORDER BY purchases DESC

/*
Here we are expliciting the traffic sources of the website, the number of views and the overall quantity of accesses; what we want to see is not only the number of people accessing to the website but, actually, the number of purchases we have, so through the conversion rate I can see the effective channel which is performing best. From that we can see that email seems to be the best option. Social media is generating a loto of traffic, but then it is not the best for the business when we come to conversion rates. Maybe the insight here is to promote the email channel rather than social media. 
*/

-- Step 5: time to conversion analysis (i.e., the time spent by users in all the funnel stages)
; WITH user_time AS (
    SELECT
      user_id,
      MIN(CASE WHEN event_type = 'page_view' THEN event_date END) AS view_time,
      MIN(CASE WHEN event_type = 'add_to_cart' THEN event_date END) AS cart_time,
      MIN(CASE WHEN event_type = 'purchase' THEN event_date END) AS purchase_time
    FROM dbo.user_events
    GROUP BY user_id
    HAVING MIN(CASE WHEN event_type = 'purchase' THEN event_date END) IS NOT NULL    -- We are interested to the actual purchases only 
)

SELECT
  COUNT(*) AS converted_users,
  ROUND(AVG(DATEDIFF(MINUTE, view_time, cart_time)), 2) AS avg_view_to_cart_minutes,
  ROUND(AVG(DATEDIFF(MINUTE, cart_time, purchase_time)), 2) AS avg_cart_to_purchase_minutes,
  ROUND(AVG(DATEDIFF(MINUTE, view_time, purchase_time)), 2) AS avg_total_time_minutes
FROM user_time

/*
We can see the time users spent on average in the funnel: 24 minutes for the entire journey in the website could potentially be shortened, thus this could be an insight for the business.
*/

-- Step 6 (and last): considering the revenue in the funnel analysis
; WITH funnel_revenue AS (
    SELECT
      ROUND(COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END), 2) AS total_visitors,
      ROUND(COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END), 2) AS total_buyers,
      ROUND(SUM(CASE WHEN event_type = 'purchase' THEN amount END), 2) AS total_revenue,
      ROUND(COUNT(CASE WHEN event_type = 'purchase' THEN 1 END), 2) AS total_orders
    FROM dbo.user_events 
)

SELECT
  total_visitors,
  total_buyers, 
  total_orders,
  total_revenue,
  ROUND(total_revenue / total_orders, 2) AS avg_order_value,
  ROUND(total_revenue / total_buyers, 2) AS revenue_per_buyer,
  ROUND(total_revenue / total_visitors, 2) AS revenue_per_visitor
FROM funnel_revenue

/*
Here, the insights about the efficiency of the marketing efforts (i.e., the revenue) comes from the avg_order_value, thus the comparison and the search for potential improvements should focus on that.
*/