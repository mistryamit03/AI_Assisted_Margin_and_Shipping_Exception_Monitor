-- Phase 3 starts here. We build a memory table. Create one permanent table to store exceptions from each run.
-- To make this more agent-like, do only these 4 things:


CREATE TABLE IF NOT EXISTS `ferrous-biplane-450410-i2.AI_Mockproject.exception_memory` (
  run_timestamp TIMESTAMP,
  order_id STRING,
  order_date DATE,
  country STRING,
  product_type STRING,
  priority_level STRING,
  selling_price FLOAT64,
  total_cost FLOAT64,
  margin_value FLOAT64,
  margin_pct FLOAT64,
  delay_days INT64,
  alert_type STRING,
  run_mode STRING,
  exception_signature STRING,
  is_new_exception BOOL,
  status STRING
);
