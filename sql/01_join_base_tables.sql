-- Counting rows to see if they are 120 rows

SELECT COUNT(*) AS row_count
FROM
  (
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
      s.tracking_event_count
    FROM `ferrous-biplane-450410-i2.AI_Mockproject.Orders` AS o
    LEFT JOIN `ferrous-biplane-450410-i2.AI_Mockproject.Costs` AS c
      ON o.order_id = c.order_id
    LEFT JOIN `ferrous-biplane-450410-i2.AI_Mockproject.Shipments` AS s
      ON o.order_id = s.order_id
  )