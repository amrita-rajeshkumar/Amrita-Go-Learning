-- Latest Date Chart
SELECT 
   distinct dim__day_ts
FROM tanzu_dm.tmc_org_summary_latest_v0

-- Sec. 1.1 total customer count
SELECT count(vmstar_customer_id) as customer_count
      ,dim__day_ts
FROM tanzu_dm.tmc_account_summary_weekly_v0
WHERE is_identified_customer_account
  AND days_until_entitlement_end_date>0
  AND dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP)) 
GROUP BY dim__day_ts
ORDER BY dim__day_ts
        
-- Sec. 1.2 activated customers count
SELECT COUNT(DISTINCT(csp_org_id)) as activated_customer_count
      ,dim__day_ts
FROM tanzu_dm.tmc_org_summary_weekly_v0
WHERE is_identified_customer_account AND is_onboarded
  AND dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP))
GROUP BY dim__day_ts
ORDER BY dim__day_ts


-- Sec. 1.3 un-onboarded customers
SELECT COUNT(vmstar_customer_id) as unactivated_customer_count
      ,dim__day_ts
FROM tanzu_dm.tmc_account_summary_weekly_v0
WHERE is_identified_customer_account
  AND is_onboarded=false
  AND days_until_entitlement_end_date>0
  AND dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP))
GROUP BY dim__day_ts
ORDER BY dim__day_ts

-- Sec. 1.4 percent of total customers 
WITH
total_customer_counts AS (
  SELECT count(vmstar_customer_id) as customer_count
      ,dim__day_ts
    FROM tanzu_dm.tmc_account_summary_weekly_v0
    WHERE is_identified_customer_account
      AND days_until_entitlement_end_date>0
    GROUP BY dim__day_ts
    ORDER BY dim__day_ts
  )
  
,onboarded_customer_counts AS(
  SELECT COUNT(DISTINCT(csp_org_id)) as activated_customer_count
      ,dim__day_ts
    FROM tanzu_dm.tmc_org_summary_weekly_v0
    WHERE is_identified_customer_account AND is_onboarded
    GROUP BY dim__day_ts
    ORDER BY dim__day_ts
  )

,together AS(
  SELECT a.dim__day_ts
        ,a.customer_count
        ,b.activated_customer_count
  FROM total_customer_counts AS a JOIN onboarded_customer_counts AS b ON a.dim__day_ts=b.dim__day_ts
)

SELECT dim__day_ts
      ,(activated_customer_count/customer_count) *100 AS 'precent_customers_activated'
FROM together
WHERE dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP))
ORDER BY dim__day_ts


-- Sec. 1.6 Stacked chart
with customer_count as 
(
select 
count(distinct vmstar_customer_id) as Customers,
dim__day_ts
FROM tanzu_dm.tmc_account_summary_weekly_v0
 WHERE is_identified_customer_account
 AND days_until_entitlement_end_date>0
GROUP BY dim__day_ts
),
org_count as 
(
select 
count(distinct csp_org_id) as Orgs,
count(distinct case when number_of_clusters >0 then csp_org_id end ) as Orgs_with_clusters_managed,
dim__day_ts
 FROM tanzu_dm.tmc_org_summary_weekly_v0
WHERE is_identified_customer_account AND is_onboarded
GROUP BY dim__day_ts
)
select 
c.dim__day_ts,
c.Customers,
o.Orgs,
o.Orgs_with_clusters_managed
from customer_count c 
join org_count o 
on c.dim__day_ts = o.dim__day_ts
where c.dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)
order by c.dim__day_ts

-- Sec. 2.1.1 total vCPUs sold   
WITH unonboarded_vcpus AS(
  SELECT SUM(total_entitlement_quantity_vcpu) AS unactivated_customer_vcpu_sold
        ,dim__day_ts
    FROM tanzu_dm.tmc_account_summary_weekly_v0
    WHERE is_identified_customer_account
      AND is_onboarded=false
      AND days_until_entitlement_end_date>0
    GROUP BY dim__day_ts
    ORDER BY dim__day_ts
),

onboarded_vcpus AS(
  SELECT SUM(total_entitlement_quantity_vcpu) as activated_org_vcpu_sold
        ,dim__day_ts
    FROM tanzu_dm.tmc_org_summary_weekly_v0
    WHERE is_identified_customer_account
      AND is_onboarded
    GROUP BY dim__day_ts
    ORDER BY dim__day_ts
),

total AS(
  SELECT a.dim__day_ts
      ,a.unactivated_customer_vcpu_sold
      ,b.activated_org_vcpu_sold
    FROM unonboarded_vcpus AS a
    JOIN onboarded_vcpus AS b ON b.dim__day_ts=a.dim__day_ts
)

SELECT dim__day_ts
  ,(unactivated_customer_vcpu_sold + activated_org_vcpu_sold) AS total_vcpus_sold
FROM total
WHERE  dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP))
ORDER BY dim__day_ts

-- Sec. 2.1.2 activated customer vcpu
SELECT SUM(usage_quantity_vcpu) as activated_customers_vcpu_usage
  ,dim__day_ts
FROM tanzu_dm.tmc_account_summary_weekly_v0
WHERE is_identified_customer_account AND is_onboarded
  AND dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP)) 
GROUP BY dim__day_ts
ORDER BY dim__day_ts

-- Sec. 2.1.3 percent of vcpus consu
WITH
total_vcpus_sold AS(
  WITH unonboarded_vcpus AS(
    SELECT SUM(total_entitlement_quantity_vcpu) AS unactivated_customer_vcpu_sold
          ,dim__day_ts
      FROM tanzu_dm.tmc_account_summary_weekly_v0
      WHERE is_identified_customer_account
        AND is_onboarded=false
        AND days_until_entitlement_end_date>0
      GROUP BY dim__day_ts
      ORDER BY dim__day_ts
  ),
  
  onboarded_vcpus AS(
    SELECT SUM(total_entitlement_quantity_vcpu) as activated_org_vcpu_sold
          ,dim__day_ts
      FROM tanzu_dm.tmc_org_summary_weekly_v0
      WHERE is_identified_customer_account
        AND is_onboarded
      GROUP BY dim__day_ts
      ORDER BY dim__day_ts
  ),
  
  total AS(
    SELECT a.dim__day_ts
        ,a.unactivated_customer_vcpu_sold
        ,b.activated_org_vcpu_sold
      FROM unonboarded_vcpus AS a
      JOIN onboarded_vcpus AS b ON b.dim__day_ts=a.dim__day_ts
  )
  
  SELECT dim__day_ts
    ,(unactivated_customer_vcpu_sold + activated_org_vcpu_sold) AS sum_vcpus_sold
  FROM total
  ORDER BY dim__day_ts
),

total_consumed AS(
  SELECT SUM(usage_quantity_vcpu) AS activated_org_vcpu_usage
    ,dim__day_ts
  FROM tanzu_dm.tmc_account_summary_weekly_v0
  WHERE is_identified_customer_account
    AND is_onboarded
  GROUP BY dim__day_ts
  ORDER BY dim__day_ts
),

together AS(
  SELECT a.dim__day_ts
      ,a.sum_vcpus_sold
      ,b.activated_org_vcpu_usage
    FROM total_vcpus_sold AS a
    JOIN total_consumed AS b ON b.dim__day_ts=a.dim__day_ts
)

SELECT dim__day_ts
  ,(activated_org_vcpu_usage/sum_vcpus_sold)*100 AS percent_vcpus_consumed
FROM together
WHERE dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP))
ORDER BY dim__day_ts


-- Sec. 2.1.4 % vCPU Consumed for A
with activated_vcpus as 
(

SELECT SUM(usage_quantity_vcpu) as activated_customers_vcpu_usage
  ,dim__day_ts
FROM tanzu_dm.tmc_account_summary_weekly_v0
WHERE is_identified_customer_account AND is_onboarded
  AND dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', now() )
GROUP BY dim__day_ts
ORDER BY dim__day_ts
), 
onboarded_vcpus AS(
  SELECT SUM(total_entitlement_quantity_vcpu) as activated_org_vcpu_sold
        ,dim__day_ts
    FROM tanzu_dm.tmc_org_summary_weekly_v0
    WHERE is_identified_customer_account
      AND is_onboarded
      and dim__day_ts > '2021-07-01'
    GROUP BY dim__day_ts
    ORDER BY dim__day_ts
),
together AS(
  SELECT a.dim__day_ts
      ,a.activated_customers_vcpu_usage
      ,b.activated_org_vcpu_sold
    FROM activated_vcpus AS a
    JOIN onboarded_vcpus AS b ON b.dim__day_ts=a.dim__day_ts
)


SELECT dim__day_ts
, activated_customers_vcpu_usage
,activated_org_vcpu_sold
  ,round((activated_customers_vcpu_usage/activated_org_vcpu_sold)*100,2) AS percent_vcpus_consumed_for_activated_customers
FROM together
WHERE dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', now() )

ORDER BY dim__day_ts


-- Sec. 2.1.5 % vCPU Consumed for A
with activated_vcpus as 
(

SELECT SUM(usage_quantity_vcpu) as activated_customers_vcpu_usage
  ,dim__day_ts
FROM tanzu_dm.tmc_account_summary_weekly_v0
WHERE is_identified_customer_account AND is_onboarded
  AND dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', now() )
GROUP BY dim__day_ts
ORDER BY dim__day_ts
), 
onboarded_nonzero_vcpus AS(
  SELECT SUM(total_entitlement_quantity_vcpu) as activated_org_nonzero_vcpu_sold
        ,dim__day_ts
    FROM tanzu_dm.tmc_org_summary_weekly_v0
    WHERE is_identified_customer_account
      AND is_onboarded
      and usage_quantity_vcpu>0
      AND number_of_clusters>0
    GROUP BY dim__day_ts
    ORDER BY dim__day_ts
),
together AS(
  SELECT a.dim__day_ts
      ,a.activated_customers_vcpu_usage
      ,b.activated_org_nonzero_vcpu_sold
    FROM activated_vcpus AS a
    JOIN onboarded_nonzero_vcpus AS b ON b.dim__day_ts=a.dim__day_ts
)


SELECT dim__day_ts
, activated_customers_vcpu_usage
,activated_org_nonzero_vcpu_sold
  ,round((activated_customers_vcpu_usage/activated_org_nonzero_vcpu_sold)*100,2) AS percent_nonzerovcpus_consumed_for_activated_customers
FROM together
WHERE dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', now() )
ORDER BY dim__day_ts


-- Sec. 2.2.1 orgs with clusters under 
SELECT COUNT(csp_org_id) as activated_orgs_with_clusters_under_management
  ,dim__day_ts
FROM tanzu_dm.tmc_org_summary_weekly_v0
WHERE is_identified_customer_account
  AND is_onboarded
  AND number_of_clusters >0
  AND dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP)) 
GROUP BY dim__day_ts
ORDER BY dim__day_ts


--Sec. 2.2.2 percent of customers
WITH total_customer_counts AS (
  SELECT count(vmstar_customer_id) as customer_count
        ,dim__day_ts
  FROM tanzu_dm.tmc_account_summary_weekly_v0
  WHERE is_identified_customer_account
    AND days_until_entitlement_end_date>0
  GROUP BY dim__day_ts
  ORDER BY dim__day_ts
  )
  
,onboarded_customers_under_management_counts AS(
  SELECT COUNT(csp_org_id) as activated_orgs_with_clusters_under_management
    ,dim__day_ts
  FROM tanzu_dm.tmc_org_summary_weekly_v0
  WHERE is_identified_customer_account
    AND is_onboarded
    AND number_of_clusters >0
  GROUP BY dim__day_ts
  ORDER BY dim__day_ts
  )

,together AS(
  SELECT a.dim__day_ts
        ,a.customer_count
        ,b.activated_orgs_with_clusters_under_management
  FROM total_customer_counts AS a JOIN onboarded_customers_under_management_counts AS b ON a.dim__day_ts=b.dim__day_ts
)

SELECT dim__day_ts
      ,(activated_orgs_with_clusters_under_management/customer_count) *100 AS 'precent_customers_with_clusters_under_management'
FROM together
WHERE dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP))
ORDER BY dim__day_ts





-- Sec. 2.2.3 total clusters under

SELECT SUM(number_of_clusters) as total_clusters_under_management
  ,dim__day_ts
FROM tanzu_dm.tmc_org_summary_weekly_v0
WHERE is_identified_customer_account
  AND is_onboarded
  AND dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP)) 
GROUP BY dim__day_ts
ORDER BY dim__day_ts


-- Sec. 2.3.1 active users per org 7 day
-- Executed by bpavithra at 1706703539
SELECT
    dim__day_ts                                                     AS dim__day_ts
  , COUNT(DISTINCT csp_org_id)                                      AS activated_org_count
  , SUM(active_users_7d)                                            AS 7d_active_users
  , SUM(active_users_api_7d)                                        AS 7d_active_users_api
  , SUM(active_users_ui_7d)                                         AS 7d_active_users_ui
  , SUM(active_users_cli_7d)                                        AS 7d_active_users_cli
  , SUM(active_users_7d) / COUNT(DISTINCT csp_org_id)               AS 7d_active_users_per_org
  , SUM(active_users_api_7d) / COUNT(DISTINCT csp_org_id)           AS 7d_active_users_per_org_api
  , SUM(active_users_ui_7d) / COUNT(DISTINCT csp_org_id)            AS 7d_active_users_per_org_ui
  , SUM(active_users_cli_7d) / COUNT(DISTINCT csp_org_id)           AS 7d_active_users_per_org_cli
FROM
tanzu_dm.tmc_org_summary_weekly_v0
WHERE is_identified_customer_account AND is_onboarded
AND TO_DATE(dim__day_ts) >= '2021-07-28' AND dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP))
GROUP BY dim__day_ts


-- old query below
/*
WITH active_users AS (
          SELECT distinct
              org_id
              , CASE
                  WHEN client = '' THEN 'API' -- direct API calls have no client info
                  ELSE UPPER(client)
                END AS client
              , user_id
              , pa__arrival_day
          FROM tmc_lake.api_usage WHERE UPPER(client) in ('','UI', 'CLI')
          ),
active_orgs AS (
        SELECT distinct 
            csp_org_id
          , dim__day_ts
        FROM tanzu_dm.tmc_org_summary_daily_v0
        WHERE is_identified_customer_account AND is_onboarded
        ORDER BY dim__day_ts
        ),
Final AS (
        SELECT
            o.dim__day_ts
          , COUNT(DISTINCT o.csp_org_id)                                            AS activated_org_count
          , COUNT(DISTINCT au.user_id)                                              AS 7d_active_users
          , COUNT(DISTINCT (CASE WHEN au.client = 'API' THEN au.user_id END))       AS 7d_active_users_api
          , COUNT(DISTINCT (CASE WHEN au.client = 'UI' THEN au.user_id END))        AS 7d_active_users_ui
          , COUNT(DISTINCT (CASE WHEN au.client = 'CLI' THEN au.user_id END))       AS 7d_active_users_cli
          , COUNT(DISTINCT au.user_id)/COUNT(DISTINCT o.csp_org_id)                 AS 7d_active_users_per_org
          , COUNT(DISTINCT (CASE WHEN au.client = 'API' THEN au.user_id END))/COUNT(DISTINCT o.csp_org_id)                 AS 7d_active_users_per_org_api
          , COUNT(DISTINCT (CASE WHEN au.client = 'UI' THEN au.user_id END)) /COUNT(DISTINCT o.csp_org_id)                 AS 7d_active_users_per_org_ui
          , COUNT(DISTINCT (CASE WHEN au.client = 'CLI' THEN au.user_id END)) /COUNT(DISTINCT o.csp_org_id)                AS 7d_active_users_per_org_cli
        FROM active_orgs AS o
        LEFT JOIN active_users AS au
        ON au.pa__arrival_day between UNIX_TIMESTAMP(DAYS_SUB(o.dim__day_ts, 6)) AND UNIX_TIMESTAMP(o.dim__day_ts)
        AND o.csp_org_id = au.org_id
        GROUP by 1
        ORDER BY 1
        )
SELECT
  *
FROM Final
WHERE
dim__day_ts <= DATE_TRUNC('week', CAST('' AS TIMESTAMP)) 
AND 
to_date(dim__day_ts) >= '2021-07-28' -- this values is hardcoded, as for now we don't have user data in api_usage table before this date
*/

-- old query below
/*WITH
active_users_7_day AS (
  SELECT total_active_users_7d as num_users
    ,at_date
  FROM tanzu_dm.view_tmc_business_and_usage_metrics_v0
),

active_orgs AS(
  SELECT COUNT(DISTINCT(csp_org_id)) as activated_org_count
        ,dim__day_ts
    FROM tanzu_dm.tmc_org_summary_daily_v0
    WHERE is_identified_customer_account
      AND is_onboarded
    GROUP BY dim__day_ts
    ORDER BY dim__day_ts
),

together AS(
SELECT a.num_users
    ,a.at_date
    ,b.dim__day_ts
    ,b.activated_org_count
  FROM active_users_7_day AS a
  JOIN active_orgs AS b on b.dim__day_ts = a.at_date
)

SELECT dim__day_ts
  ,num_users
  ,activated_org_count
  ,num_users/activated_org_count AS users_per_org
FROM together
WHERE dim__day_ts <= DATE_TRUNC('week', CAST('' AS TIMESTAMP)) 
ORDER BY dim__day_ts
*/

-- Sec. 2.4.1 public cloud vcpus unde
SELECT SUM(usage_quantity_vcpu) AS public_cloud_vcpu_under_management
  ,dim__day_ts
FROM tanzu_dm.tmc_deployment_summary_weekly_v0
WHERE is_identified_customer_account 
  AND  infrastructure_domain='PUBLIC'
  AND dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP)) 
GROUP BY dim__day_ts
ORDER BY dim__day_ts
        

-- Sec. 2.4.2 percent vcpu under ma
WITH total_vcpus AS(
 SELECT SUM(usage_quantity_vcpu) AS vcpu_under_management
  ,dim__day_ts
  FROM tanzu_dm.tmc_deployment_summary_weekly_v0
  WHERE is_identified_customer_account
  AND dim__day_ts > '2021-07-01'
  GROUP BY dim__day_ts
  ORDER BY dim__day_ts
),

public_cloud_vcpus AS(
  SELECT SUM(usage_quantity_vcpu) AS public_cloud_vcpu_under_management
    ,dim__day_ts
  FROM tanzu_dm.tmc_deployment_summary_weekly_v0
  WHERE is_identified_customer_account
    AND infrastructure_domain='PUBLIC'
  GROUP BY dim__day_ts
  ORDER BY dim__day_ts
),

together AS(
  SELECT a.vcpu_under_management
    ,b.public_cloud_vcpu_under_management
    ,a.dim__day_ts
  FROM total_vcpus AS a
  JOIN public_cloud_vcpus AS b on a.dim__day_ts = b.dim__day_ts
)

SELECT (public_cloud_vcpu_under_management/vcpu_under_management ) *100 AS percent_vcpu_is_public_cloud
  ,dim__day_ts
FROM together
WHERE dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP))
ORDER BY dim__day_ts
        
-- Sec. 2.4.3 Count of orgs on public
SELECT COUNT(csp_order_ids) as total_orgs_on_public_cloud
  ,dim__day_ts
FROM tanzu_dm.tmc_org_summary_weekly_v0
WHERE is_identified_customer_account
  AND is_onboarded
  AND infrastructure_mix = 'HYBRID' OR infrastructure_mix = 'PUBLIC_ONLY'
  AND dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP)) 
GROUP BY dim__day_ts
ORDER BY dim__day_ts

-- Sec. 2.4.4% Onboarded Orgs on P
WITH total_activated_orgs AS (
  SELECT COUNT(DISTINCT(csp_org_id)) as activated_org_count
        ,dim__day_ts
  FROM tanzu_dm.tmc_org_summary_weekly_v0
  WHERE is_identified_customer_account
    AND is_onboarded
  GROUP BY dim__day_ts
  ORDER BY dim__day_ts
  )
  
,onboarded_public_cloud_orgs AS(
  SELECT COUNT(csp_order_ids) as total_orgs_on_public_cloud
      ,dim__day_ts
    FROM tanzu_dm.tmc_org_summary_weekly_v0
    WHERE is_identified_customer_account
      AND is_onboarded
      AND infrastructure_mix = 'HYBRID' OR infrastructure_mix = 'PUBLIC_ONLY'
    GROUP BY dim__day_ts
    ORDER BY dim__day_ts
  )

,together AS(
  SELECT a.dim__day_ts
        ,a.activated_org_count
        ,b.total_orgs_on_public_cloud
  FROM total_activated_orgs AS a JOIN onboarded_public_cloud_orgs AS b ON a.dim__day_ts=b.dim__day_ts
)

SELECT dim__day_ts
      ,(total_orgs_on_public_cloud/activated_org_count) *100 AS 'precent_orgs_with_public_cloud_footprint'
FROM together
WHERE dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP))
ORDER BY dim__day_ts


-- Sec. 2.4.5 Onboarded orgs ONLY 
SELECT COUNT(csp_order_ids) as total_orgs_on_only_public_cloud
  ,dim__day_ts
FROM tanzu_dm.tmc_org_summary_weekly_v0
WHERE is_identified_customer_account
  AND is_onboarded
  AND infrastructure_mix = 'PUBLIC_ONLY'
  AND dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP)) 
GROUP BY dim__day_ts
ORDER BY dim__day_ts


-- Sec. 2.4.6 % of Onboarded orgs
WITH total_activated_orgs AS (
  SELECT COUNT(DISTINCT(csp_org_id)) as activated_org_count
        ,dim__day_ts
  FROM tanzu_dm.tmc_org_summary_weekly_v0
  WHERE is_identified_customer_account
    AND is_onboarded
  GROUP BY dim__day_ts
  ORDER BY dim__day_ts
  )
  
,onboarded_public_cloud_orgs AS(
  SELECT COUNT(csp_order_ids) as total_orgs_on_only_public_cloud
      ,dim__day_ts
    FROM tanzu_dm.tmc_org_summary_weekly_v0
    WHERE is_identified_customer_account
      AND is_onboarded
      AND infrastructure_mix = 'PUBLIC_ONLY'
    GROUP BY dim__day_ts
    ORDER BY dim__day_ts
  )

,together AS(
  SELECT a.dim__day_ts
        ,a.activated_org_count
        ,b.total_orgs_on_only_public_cloud
  FROM total_activated_orgs AS a JOIN onboarded_public_cloud_orgs AS b ON a.dim__day_ts=b.dim__day_ts
)

SELECT dim__day_ts
      ,(total_orgs_on_only_public_cloud/activated_org_count) *100 AS 'precent_orgs_only_public_cloud_footprint'
FROM together
WHERE dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP))
ORDER BY dim__day_ts
        

-- Sec. 2.4.7 vcpu on tkg under mana
SELECT SUM(usage_quantity_vcpu) as total_vcpu_tkg_under_management
  ,dim__day_ts
FROM tanzu_dm.tmc_deployment_summary_weekly_v0
WHERE is_identified_customer_account
  AND k8s_is_tkg
  AND dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP)) 
GROUP BY dim__day_ts
ORDER BY dim__day_ts


-- Sec. 2.4.8 percent tkg vcpus under
WITH total_vcpus AS(
  SELECT SUM(usage_quantity_vcpu) AS vcpu_under_management
  ,dim__day_ts
  FROM tanzu_dm.tmc_deployment_summary_weekly_v0
  WHERE is_identified_customer_account
  AND dim__day_ts > '2021-07-01'
  GROUP BY dim__day_ts
  ORDER BY dim__day_ts
),

tkg_vcpus AS(
  SELECT SUM(usage_quantity_vcpu) AS tkg_vcpu_under_management
    ,dim__day_ts
  FROM tanzu_dm.tmc_deployment_summary_weekly_v0
  WHERE is_identified_customer_account
    AND k8s_is_tkg
  GROUP BY dim__day_ts
  ORDER BY dim__day_ts
),

together AS(
  SELECT a.vcpu_under_management
    ,b.tkg_vcpu_under_management
    ,a.dim__day_ts
  FROM total_vcpus AS a
  JOIN tkg_vcpus AS b on a.dim__day_ts = b.dim__day_ts
)

SELECT (tkg_vcpu_under_management/vcpu_under_management ) *100 AS percent_vcpu_is_on_tkg
  ,dim__day_ts
FROM together
WHERE dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP))
ORDER BY dim__day_ts
        

-- Sec. 3.1 COGS over time
WITH vcpu_sold as 
(

WITH unonboarded_vcpus AS(
  SELECT SUM(total_entitlement_quantity_vcpu) AS unactivated_customer_vcpu_sold
        ,dim__day_ts
    FROM tanzu_dm.tmc_account_summary_weekly_v0
    WHERE is_identified_customer_account
      AND is_onboarded=false
      AND days_until_entitlement_end_date>0
    GROUP BY dim__day_ts
    ORDER BY dim__day_ts
),

onboarded_vcpus AS(
  SELECT SUM(total_entitlement_quantity_vcpu) as activated_org_vcpu_sold
        ,dim__day_ts
    FROM tanzu_dm.tmc_org_summary_weekly_v0
    WHERE is_identified_customer_account
      AND is_onboarded
    GROUP BY dim__day_ts
    ORDER BY dim__day_ts
),

total AS(
  SELECT a.dim__day_ts
      ,a.unactivated_customer_vcpu_sold
      ,b.activated_org_vcpu_sold
    FROM unonboarded_vcpus AS a
    JOIN onboarded_vcpus AS b ON b.dim__day_ts=a.dim__day_ts
)

SELECT strleft(cast(dim__day_ts as string), 7) as dayts, dim__day_ts
  ,(unactivated_customer_vcpu_sold + activated_org_vcpu_sold) AS total_vcpus_sold
FROM total
WHERE  dim__day_ts <=  DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP)) 
ORDER BY dim__day_ts

)
,
 vcpu_used AS 
(
SELECT SUM(usage_quantity_vcpu) as activated_customers_vcpu_usage
,strleft(cast(dim__day_ts as string), 7) as vu_dayts
  ,dim__day_ts
FROM tanzu_dm.tmc_account_summary_weekly_v0
WHERE is_identified_customer_account AND is_onboarded
  AND dim__day_ts <=  DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP)) 
GROUP BY dim__day_ts
ORDER BY dim__day_ts
)
,


cogs AS 
(
select strleft (cast(month_of_cost as string),7) as monthcost , round(cost,2) as cost 
, lag(cost,1) over(order by cost)  as lagcost
from tanzu_rtba_metrics.tmc_cloudhealth_monthly_cost_latest_view_v1
)



select vcpu_sold.*, vcpu_used.activated_customers_vcpu_usage
--cogs.cost/ round(count(vcpu_sold.dayts) over (partition by dayts order by dayts),2) as weekly_cost 
--, round((cogs.cost/ count(vcpu_sold.dayts) over (partition by vcpu_sold.dayts order by vcpu_sold.dayts))/(vcpu_sold.total_vcpus_sold),4) as avg_cost_per_vcpu_sold
--,round((cogs.cost/ count(vcpu_sold.dayts) over (partition by vcpu_sold.dayts order by vcpu_sold.dayts))/(vcpu_used.activated_customers_vcpu_usage+1),4) as avg_cost_per_vcpu_used

, cogs.cost
, vcpu_used.activated_customers_vcpu_usage 

--, cogs.lagcost 
--, lag(cogs.cost,1) over(order by cogs.cost) 
--, cogs.lagcost/total_vcpus_sold lagcostpervcpu
, round((cogs.cost *12)/vcpu_sold.total_vcpus_sold,2)  as costpervcpusold
, round((cogs.cost*12)/(vcpu_used.activated_customers_vcpu_usage+1),2) as costpervcpuused
from vcpu_sold,vcpu_used, cogs
where vcpu_sold.dayts=cogs.monthcost
and vcpu_used.vu_dayts=cogs.monthcost 
and vcpu_used.dim__day_ts=vcpu_sold.dim__day_ts
AND vcpu_used.dim__day_ts > '2021-07-01'
order by vcpu_sold.dim__day_ts


-- Sec. 3.2 COGS BigVal

WITH vcpu_sold as 
(

WITH unonboarded_vcpus AS(
  SELECT SUM(total_entitlement_quantity_vcpu) AS unactivated_customer_vcpu_sold
        ,dim__day_ts
    FROM tanzu_dm.tmc_account_summary_weekly_v0
    WHERE is_identified_customer_account
      AND is_onboarded=false
      AND days_until_entitlement_end_date>0
    GROUP BY dim__day_ts
    ORDER BY dim__day_ts
),

onboarded_vcpus AS(
  SELECT SUM(total_entitlement_quantity_vcpu) as activated_org_vcpu_sold
        ,dim__day_ts
    FROM tanzu_dm.tmc_org_summary_weekly_v0
    WHERE is_identified_customer_account
      AND is_onboarded
    GROUP BY dim__day_ts
    ORDER BY dim__day_ts
),

total AS(
  SELECT a.dim__day_ts
      ,a.unactivated_customer_vcpu_sold
      ,b.activated_org_vcpu_sold
    FROM unonboarded_vcpus AS a
    JOIN onboarded_vcpus AS b ON b.dim__day_ts=a.dim__day_ts
)

SELECT strleft(cast(dim__day_ts as string), 7) as dayts, dim__day_ts
  ,(unactivated_customer_vcpu_sold + activated_org_vcpu_sold) AS total_vcpus_sold
FROM total
WHERE  dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', now() )
ORDER BY dim__day_ts

)
,
 vcpu_used AS 
(
SELECT SUM(usage_quantity_vcpu) as activated_customers_vcpu_usage
,strleft(cast(dim__day_ts as string), 7) as vu_dayts
  ,dim__day_ts
FROM tanzu_dm.tmc_account_summary_weekly_v0
WHERE is_identified_customer_account AND is_onboarded
  AND dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', now() )
GROUP BY dim__day_ts
ORDER BY dim__day_ts
)
,


cogs AS 
(
select strleft (cast(month_of_cost as string),7) as monthcost , round(cost,2) as cost 
, lag(cost,1) over(order by cost)  as lagcost
from tanzu_rtba_metrics.tmc_cloudhealth_monthly_cost_latest_view_v1
)



select vcpu_sold.*, vcpu_used.activated_customers_vcpu_usage
--cogs.cost/ round(count(vcpu_sold.dayts) over (partition by dayts order by dayts),2) as weekly_cost 
--, round((cogs.cost/ count(vcpu_sold.dayts) over (partition by vcpu_sold.dayts order by vcpu_sold.dayts))/(vcpu_sold.total_vcpus_sold),4) as avg_cost_per_vcpu_sold
--,round((cogs.cost/ count(vcpu_sold.dayts) over (partition by vcpu_sold.dayts order by vcpu_sold.dayts))/(vcpu_used.activated_customers_vcpu_usage+1),4) as avg_cost_per_vcpu_used

, cogs.cost


--, cogs.lagcost 
--, lag(cogs.cost,1) over(order by cogs.cost) 
--, cogs.lagcost/total_vcpus_sold lagcostpervcpu
, round((cogs.cost*12)/vcpu_sold.total_vcpus_sold,2)  as costpervcpusold
, round((cogs.cost*12)/(vcpu_used.activated_customers_vcpu_usage+1),2) as costpervcpuused
from vcpu_sold,vcpu_used, cogs
where vcpu_sold.dayts=cogs.monthcost
and vcpu_used.vu_dayts=cogs.monthcost 
and vcpu_used.dim__day_ts=vcpu_sold.dim__day_ts
AND vcpu_used.dim__day_ts > '2021-07-01'
order by vcpu_used.dim__day_ts  
--limit 1


-- Sec. 4.1 Top onboarded orgs
SELECT 
   dim__day_ts
  ,csp_org_name
  ,tmc_subdomain AS subdomain
  ,csp_org_id
  ,usage_quantity_vcpu
  ,total_entitlement_quantity_vcpu
  ,number_of_clusters AS num_clusters
  ,onboarding_date AS when_onboarded
  ,entitlement_end_date
  ,days_until_entitlement_end_date
  ,tier as tiers
  ,skus
  ,booking_order_ids AS booking_id
  ,csp_order_ids AS csp_booking_id
  ,total_policy_count AS num_policies
  ,to_cluster_count AS num_TO_clusters
  ,tsm_cluster_count AS num_TSM_clusters
  ,active_users_7d AS 7d_active_users
  ,active_users_api_7d AS 7d_active_users_api
  ,active_users_ui_7d AS 7d_active_users_ui
  ,active_users_cli_7d AS 7d_active_users_cli
FROM tanzu_dm.tmc_org_summary_latest_v0
WHERE is_identified_customer_account
  AND is_onboarded
  --AND usage_quantity_vcpu > 0
--  AND dim__day_ts = DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--CAST('' AS TIMESTAMP)
ORDER BY dim__day_ts DESC, usage_quantity_vcpu DESC


-- Sec. 4.1.1 Top Onboarded Orgs Fo
WITH onboarded_orgs AS (
    SELECT 
      dim__day_ts
      ,csp_org_name
      ,tmc_subdomain AS subdomain
      ,csp_org_id
      ,usage_quantity_vcpu
      ,total_entitlement_quantity_vcpu
      ,number_of_clusters AS num_clusters 
      ,onboarding_date AS when_onboarded
      ,entitlement_end_date
      ,days_until_entitlement_end_date
      ,tier as tiers
      ,skus
      ,booking_order_ids AS booking_id
      ,csp_order_ids AS csp_booking_id
      ,total_policy_count AS num_policies
      ,to_cluster_count AS num_TO_clusters
      ,tsm_cluster_count AS num_TSM_clusters
      ,active_users_7d AS 7d_active_users
      ,active_users_api_7d AS 7d_active_users_api
      ,active_users_ui_7d AS 7d_active_users_ui
      ,active_users_cli_7d AS 7d_active_users_cli
    FROM tanzu_dm.tmc_org_summary_latest_v0
    WHERE is_identified_customer_account
      AND is_onboarded
      AND number_of_clusters > 0
--      AND dim__day_ts = DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--CAST('' AS TIMESTAMP)
ORDER BY dim__day_ts DESC, usage_quantity_vcpu DESC
)
SELECT
'With TSM Clusters' AS metric,
COUNT(DISTINCT CASE WHEN num_TSM_clusters > 0 THEN csp_org_id ELSE NULL END) / COUNT(DISTINCT csp_org_id) AS percent_value,
COUNT(DISTINCT CASE WHEN num_TSM_clusters > 0 THEN csp_org_id ELSE NULL END) AS value
FROM onboarded_orgs
UNION ALL
SELECT
'With TO Clusters' AS metric,
COUNT(DISTINCT CASE WHEN num_TO_clusters > 0 THEN csp_org_id ELSE NULL END) / COUNT(DISTINCT csp_org_id) AS percent_value,
COUNT(DISTINCT CASE WHEN num_TO_clusters > 0 THEN csp_org_id ELSE NULL END) as value
FROM onboarded_orgs
UNION ALL
SELECT
'With Policies' AS metric,
COUNT(DISTINCT CASE WHEN num_policies > 0 THEN csp_org_id ELSE NULL END) / COUNT(DISTINCT csp_org_id) AS percent_value,
COUNT(DISTINCT CASE WHEN num_policies > 0 THEN csp_org_id ELSE NULL END) as value
FROM onboarded_orgs


-- Sec. 4.1.2 vCPU Clusters Others (t

WITH customers AS (
  SELECT
    *,
    CASE
      WHEN total_entitlement_quantity_vcpu > 0 THEN round(
        (
          usage_quantity_vcpu / total_entitlement_quantity_vcpu
        ) * 100,
        2
      )
    END AS usage_percentage
  FROM
    tanzu_dm.tmc_org_summary_latest_v0
  WHERE
    is_identified_customer_account
    AND is_onboarded
),
data_protection AS (
  SELECT
    DISTINCT csp_org_name,
    org_id,
    cluster_count AS dp_clusters
  FROM
    tmc_dwh_prod.view_latest_data_protection_onboarded_org_info
  WHERE
    cluster_count > 1
),
custom_roles AS (
  SELECT
    org_id,
    COUNT(*) AS "total_custom_roles"
  FROM
    tmc_dwh_prod.org_custom_role_info
  GROUP BY
    org_id
),
cluster_groups AS (
  SELECT
    COUNT(*) AS "total_number_cg",
    org_id
  FROM
    tmc_dwh_prod.org_cluster_group_info
  WHERE
    org_id IN (
      SELECT
        DISTINCT oc.organization_id
      FROM
        tmc_lake.org_contract_info AS oc
      WHERE
        cast(oc.pa__arrival_ts AS timestamp) >= utc_timestamp() - INTERVAL 18 hours
        AND oc.pa__collector_id = 'tmc_tenancy' -- needed to filter out staging data
        -- below orgs are tests orgs
        AND oc.organization_id != '1b3ac77f-8cbf-4a2d-a85e-5a0fa4d527fa'
        AND oc.organization_id != 'a16fa8bb-0563-4231-9d93-e398729b399b'
        AND oc.organization_id != 'd307b7ba-0c1b-488c-9330-ace7b478fdab'
        AND oc.organization_id != '918bd74e-01f6-42c6-abdb-eb93bdf3aef1'
        AND oc.organization_id != 'bf0d9b95-510d-4de4-b687-0c57c953ab8f'
        AND oc.contract_term_period > 3
        AND oc.contract_type != 'FREE_TRIAL'
    )
  GROUP BY
    org_id
),
templates AS (
  SELECT
    org_id,
    COUNT(*) AS "total_templates"
  FROM
    tmc_dwh_prod.org_policy_template_info
  GROUP BY
    org_id
)
SELECT
  *
FROM
  tmc_dwh_prod.org_resource_manager_info AS rmi
  INNER JOIN customers ON customers.csp_org_id = rmi.org_id
  INNER JOIN cluster_groups ON rmi.org_id = cluster_groups.org_id
  LEFT JOIN data_protection ON rmi.org_id = data_protection.org_id
  LEFT JOIN custom_roles ON rmi.org_id = custom_roles.org_id
  LEFT JOIN templates ON rmi.org_id = templates.org_id


  -- Sec. 4.2 onboarded customers wit
  SELECT dim__day_ts
  ,csp_org_name
  ,tmc_subdomain AS subdomain
  ,csp_org_id
  ,usage_quantity_vcpu
  ,total_entitlement_quantity_vcpu
  ,number_of_clusters AS num_clusters
  ,onboarding_date AS when_onboarded
  ,entitlement_end_date
  ,days_until_entitlement_end_date
  ,tier as tiers
  ,skus
  ,booking_order_ids AS booking_id
  ,csp_order_ids AS csp_booking_id
  ,total_policy_count AS num_policies
  ,to_cluster_count AS num_TO_clusters
  ,tsm_cluster_count AS num_TSM_clusters
  ,active_users_7d AS 7d_active_users
  ,active_users_api_7d AS 7d_active_users_api
  ,active_users_ui_7d AS 7d_active_users_ui
  ,active_users_cli_7d AS 7d_active_users_cli
FROM tanzu_dm.tmc_org_summary_latest_v0
WHERE is_identified_customer_account
  AND is_onboarded
  AND usage_quantity_vcpu=0
--  AND dim__day_ts = DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--CAST('' AS TIMESTAMP)
ORDER BY dim__day_ts DESC
  ,total_entitlement_quantity_vcpu DESC


  -- Sec. 4.3 Yet to onboard customers
  SELECT dim__day_ts
  ,vmstar_customer_id
  ,vmstar_account_name
  ,vmw_gult_name
  ,total_entitlement_quantity_vcpu
  ,csp_order_status_last_changed_most_recent AS last_status_change_date
  ,csp_order_status_most_recent AS last_status_change
  ,entitlement_end_date
  ,days_until_entitlement_end_date
  ,skus
  ,tiers
  ,booking_order_ids AS booking_id
  ,csp_order_ids
FROM tanzu_dm.tmc_account_summary_latest_v0 
WHERE is_identified_customer_account
  AND is_onboarded=FALSE
  AND days_until_entitlement_end_date>0
--AND dim__day_ts = DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--CAST('' AS TIMESTAMP)
ORDER BY dim__day_ts DESC
  ,total_entitlement_quantity_vcpu DESC


-- Sec. 4.3 Yet to onboard customers
SELECT dim__day_ts
  ,vmstar_customer_id
  ,vmstar_account_name
  ,vmw_gult_name
  ,total_entitlement_quantity_vcpu
  ,csp_order_status_last_changed_most_recent AS last_status_change_date
  ,csp_order_status_most_recent AS last_status_change
  ,entitlement_end_date
  ,days_until_entitlement_end_date
  ,skus
  ,tiers
  ,booking_order_ids AS booking_id
  ,csp_order_ids
FROM tanzu_dm.tmc_account_summary_latest_v0 
WHERE is_identified_customer_account
  AND is_onboarded=FALSE
  AND days_until_entitlement_end_date>0
--AND dim__day_ts = DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--CAST('' AS TIMESTAMP)
ORDER BY dim__day_ts DESC
  ,total_entitlement_quantity_vcpu DESC


-- Sec. 5.1 onboarded orgs w/ expirin

SELECT dim__day_ts
  ,csp_org_name
  ,tmc_subdomain AS subdomain
  ,csp_org_id
  ,days_until_entitlement_end_date
  ,entitlement_end_date
  ,usage_quantity_vcpu
  ,total_entitlement_quantity_vcpu
  ,number_of_clusters
  ,csp_order_ids
  ,booking_order_ids
  ,skus
  ,vmstar_account_id
  ,vmstar_customer_id
  ,vmstar_account_name
  ,vmw_gult_uuid
  ,vmw_gult_name
  ,vmw_site_uuid
  ,vmw_site_name
  ,entitlement_account_numbers
  ,total_policy_count AS num_policies
  ,to_cluster_count AS num_TO_clusters
  ,tsm_cluster_count AS num_TSM_clusters
  ,active_users_7d AS 7d_active_users
  ,active_users_api_7d AS 7d_active_users_api
  ,active_users_ui_7d AS 7d_active_users_ui
  ,active_users_cli_7d AS 7d_active_users_cli
FROM tanzu_dm.tmc_org_summary_latest_v0
WHERE is_identified_customer_account
  AND number_of_clusters>0
  AND days_until_entitlement_end_date BETWEEN 0 AND 90
--  AND dim__day_ts = DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--CAST('' AS TIMESTAMP)
ORDER BY days_until_entitlement_end_date
  ,usage_quantity_vcpu DESC
  ,total_entitlement_quantity_vcpu DESC


-- Sec. 5.2 Onboarded orgs under m
with orgs_with_last_ent_date as (
    select
        csp_org_id,
        csp_org_name
        , dim__day_ts
        ,latest_date  
        ,tmc_subdomain AS subdomain
        ,entitlement_end_date
                ,usage_quantity_vcpu
        ,total_entitlement_quantity_vcpu
,number_of_clusters
,csp_order_ids
,booking_order_ids
,skus
,vmstar_account_id
,vmstar_customer_id
,vmstar_account_name
,vmw_gult_uuid
,vmw_gult_name
,vmw_site_uuid
,vmw_site_name
,entitlement_account_numbers
,total_policy_count AS num_policies
,to_cluster_count AS num_TO_clusters
,tsm_cluster_count AS num_TSM_clusters
,active_users_7d AS 7d_active_users
,active_users_api_7d AS 7d_active_users_api
,active_users_ui_7d AS 7d_active_users_ui
,active_users_cli_7d AS 7d_active_users_cli
,datediff(now(), entitlement_end_date) as time_since_expiry
    from tanzu_dm.tmc_org_summary_daily_v0
    ,(select max(dim__day_ts) as latest_date from tanzu_dm.fact_entitlement_latest_v0) as fel
    where is_identified_customer_account
    and is_onboarded
    and number_of_clusters>0
    --group by 1,2,3,4
    order by 2 asc
),
orgs_with_ent_latest as (
    select
        csp_org_id
    from tanzu_dm.tmc_org_summary_latest_v0
    where is_onboarded and is_identified_customer_account
    group by 1
),
org_max_date as 
   (select
        csp_org_id
        ,MAX(dim__day_ts) as last_day_seen_with_ent
    from tanzu_dm.tmc_org_summary_daily_v0
    where is_identified_customer_account
    and is_onboarded
    group by 1
    )
SELECT e.* FROM orgs_with_last_ent_date as e
LEFT JOIN orgs_with_ent_latest as l
    on e.csp_org_id = l.csp_org_id
    inner join org_max_date dt
    on dt.last_day_seen_with_ent = e.dim__day_ts
    and dt.csp_org_id=e.csp_org_id
where l.csp_org_id is NULL
and time_since_expiry between 0 and 90
order by 2 asc









--currently filtered to only orgs with clusters under management
--SELECT 
 --latest_date as dim__day_ts
--,csp_org_name
--,tmc_subdomain AS subdomain
--,csp_org_id
  ------------ updated logic for days_until_entitlement_end_date ------------
--,datediff(dim__day_ts, latest_date) as days_until_entitlement_end_date
  ------------ ------------------------------------------------- ------------
--,entitlement_end_date
--,usage_quantity_vcpu
--,total_entitlement_quantity_vcpu
--,number_of_clusters
--,csp_order_ids
--,booking_order_ids
--,skus
--,vmstar_account_id
--,vmstar_customer_id
--,vmstar_account_name
--,vmw_gult_uuid
--,vmw_gult_name
--,vmw_site_uuid
--,vmw_site_name
--,entitlement_account_numbers
--,total_policy_count AS num_policies
--,to_cluster_count AS num_TO_clusters
--,tsm_cluster_count AS num_TSM_clusters
--,active_users_7d AS 7d_active_users
--,active_users_api_7d AS 7d_active_users_api
--,active_users_ui_7d AS 7d_active_users_ui
--,active_users_cli_7d AS 7d_active_users_cli
--FROM tanzu_dm.tmc_org_summary_daily_v0, (select max(dim__day_ts) as latest_date from tanzu_dm.fact_entitlement_latest_v0) as fel
--WHERE is_identified_customer_account
  --AND number_of_clusters>0
  ------------ updated where clause ------------
  --AND days_until_entitlement_end_date = 0
  --AND datediff(dim__day_ts, latest_date) <= 0
  --AND datediff(dim__day_ts, latest_date) >= -90
  ------------ -------------------- ------------
--ORDER BY days_until_entitlement_end_date DESC
--,usage_quantity_vcpu DESC
--,total_entitlement_quantity_vcpu DESC
-- old query below
-- SELECT dim__day_ts
--   ,csp_org_name
--   ,tmc_subdomain AS subdomain
--   ,csp_org_id
--   ,days_until_entitlement_end_date
--   ,entitlement_end_date
--   ,usage_quantity_vcpu
--   ,total_entitlement_quantity_vcpu
--   ,number_of_clusters
--   ,csp_order_ids
--   ,booking_order_ids
--   ,skus
--   ,vmstar_account_id
--   ,vmstar_customer_id
--   ,vmstar_account_name
--   ,vmw_gult_uuid
--   ,vmw_gult_name
--   ,vmw_site_uuid
--   ,vmw_site_name
--   ,entitlement_account_numbers
--   ,total_policy_count AS num_policies
--   ,to_cluster_count AS num_TO_clusters
--   ,tsm_cluster_count AS num_TSM_clusters
--   ,active_users_7d AS 7d_active_users
--   ,active_users_api_7d AS 7d_active_users_api
--   ,active_users_ui_7d AS 7d_active_users_ui
--   ,active_users_cli_7d AS 7d_active_users_cli
-- FROM tanzu_dm.tmc_org_summary_latest_v0
-- WHERE is_identified_customer_account
--   AND number_of_clusters>0
--   AND days_until_entitlement_end_date <= 0 --DATEDIFF(DAYS_SUB(DATE_TRUNC('DAY', NOW()),1),entitlement_end_date)--DATEDIFF(CAST('' AS TIMESTAMP),entitlement_end_date)
--   AND days_until_entitlement_end_date >= -90 -- DATEDIFF(DATE_SUB(DAYS_SUB(DATE_TRUNC('DAY', NOW()),1),interval 90 day),entitlement_end_date)--DATEDIFF(DATE_SUB(CAST('' AS TIMESTAMP),interval 90 day),entitlement_end_date)
--   --AND dim__day_ts = DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--CAST('' AS TIMESTAMP)
-- ORDER BY days_until_entitlement_end_date DESC
--   ,usage_quantity_vcpu DESC
--   ,total_entitlement_quantity_vcpu DESC



-- Sec. 6 ratio of multi-org logos to o
WITH

multi_org_counts AS(
  SELECT COUNT(*) AS multi_org_count
          ,dim__day_ts
          FROM tanzu_dm.tmc_org_summary_weekly_v0
          WHERE is_onboarded
            AND is_identified_customer_account
          GROUP BY vmstar_customer_id, dim__day_ts
          HAVING COUNT(*)>1
          ORDER BY dim__day_ts
),

onboarded_customer_counts AS(
  SELECT COUNT(vmstar_customer_id) as onboarded_customer_logos
      ,dim__day_ts
    FROM tanzu_dm.tmc_org_summary_weekly_v0
    WHERE is_identified_customer_account
    AND is_onboarded
    GROUP BY dim__day_ts
    ORDER BY dim__day_ts
),

together AS(
  SELECT a.dim__day_ts
        ,a.multi_org_count
        ,b.onboarded_customer_logos
  FROM multi_org_counts AS a JOIN onboarded_customer_counts AS b ON a.dim__day_ts=b.dim__day_ts
)

SELECT dim__day_ts
      , multi_org_count / onboarded_customer_logos AS ratio_multi_orgs_to_logos
FROM together
WHERE dim__day_ts <= DAYS_SUB(DATE_TRUNC('DAY', NOW()),1)--DATE_TRUNC('week', CAST('' AS TIMESTAMP))
ORDER BY dim__day_ts
          
        