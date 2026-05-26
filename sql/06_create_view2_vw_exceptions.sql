
-- Creating the vw_exceptions view after figuring out the problems in looker studio



CREATE OR REPLACE VIEW `ferrous-biplane-450410-i2.AI_Mockproject.vw_exceptions`
AS
WITH
  base_calc AS (
    SELECT
      o.order_id,
      o.order_date,
      o.customer_id,
      o.product_type,
      o.country,
      o.selling_price,
      o.quantity,
      o.quoted_margin_pct,
      c.material_cost,
      c.production_cost,
      c.packaging_cost,
      c.shipping_cost,
      c.total_cost,
      s.carrier,
      s.promised_delivery_date,
      s.actual_delivery_date,
      s.shipment_status,
      s.tracking_event_count,
      (o.selling_price - c.total_cost) AS margin_value,
      SAFE_DIVIDE((o.selling_price - c.total_cost), o.selling_price)
        AS margin_pct,
      DATE_DIFF(s.actual_delivery_date, s.promised_delivery_date, DAY)
        AS delay_days,
    FROM `ferrous-biplane-450410-i2.AI_Mockproject.Orders` AS o
    LEFT JOIN `ferrous-biplane-450410-i2.AI_Mockproject.Costs` AS c
      ON o.order_id = c.order_id
    LEFT JOIN `ferrous-biplane-450410-i2.AI_Mockproject.Shipments` AS s
      ON o.order_id = s.order_id
  ),
  flags AS (
    SELECT
      *,
      CASE WHEN margin_value < 0 THEN 1 ELSE 0 END AS negative_margin_flag,
      CASE
        WHEN margin_value >= 0 AND margin_pct < 0.10 THEN 1
        ELSE 0
        END AS low_margin_flag,
      CASE WHEN delay_days > 0 THEN 1 ELSE 0 END AS late_shipment_flag,
      CASE WHEN delay_days >= 3 THEN 1 ELSE 0 END AS critical_delay_flag,
    FROM base_calc
  ),
  prioritized AS (
    SELECT
      *,
      CASE
        WHEN negative_margin_flag = 1 OR critical_delay_flag = 1 THEN "High"
        WHEN low_margin_flag = 1 OR late_shipment_flag = 1 THEN "Medium"
        ELSE "Low"
        END AS priority_level
    FROM flags
    WHERE
      negative_margin_flag = 1
      OR low_margin_flag = 1
      OR late_shipment_flag = 1
      OR critical_delay_flag = 1
  )
SELECT
  *,
  CASE
    WHEN priority_level = "Low" THEN 1
    WHEN priority_level = "Medium" THEN 2
    WHEN priority_level = "High" THEN 3
    ELSE 99
    END AS priority_sort_order,
  CASE
    WHEN priority_level = "Low" THEN '1. Low'
    WHEN priority_level = "Medium" THEN '2. Medium'
    WHEN priority_level = "High" THEN '3. High'
    ELSE '99. Unknown'
    END AS priority_display,
  DATE_TRUNC(order_date, MONTH) AS order_month,
FROM prioritized