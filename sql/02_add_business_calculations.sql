-- Now let’s move to Step 2: business calculations Goal
-- Take your joined query and add 3 new columns:
-- margin_value = selling_price - total_cost
-- margin_pct = selling_price - total_cost / selling_price
-- delay_days =
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
  ((o.selling_price - c.total_cost) / o.selling_price) AS margin_pct,
  DATE_DIFF(s.actual_delivery_date, s.promised_delivery_date, DAY) AS delay_days
FROM `ferrous-biplane-450410-i2.AI_Mockproject.Orders` AS o
LEFT JOIN `ferrous-biplane-450410-i2.AI_Mockproject.Costs` AS c
  ON o.order_id = c.order_id
LEFT JOIN `ferrous-biplane-450410-i2.AI_Mockproject.Shipments` AS s
  ON o.order_id = s.order_id
