-- Create the comparison view

-- BigQuery will answer: 
-- Is this exception new
-- or has this same issue pattern been seen before


CREATE OR REPLACE VIEW `ferrous-biplane-450410-i2.AI_Mockproject.vw_exception_agent_input` AS
WITH current_exceptions AS (
  SELECT
    *,
    TO_HEX(MD5(CONCAT(
      CAST(order_id AS STRING), '|',
      CAST(negative_margin_flag AS STRING), '|',
      CAST(low_margin_flag AS STRING), '|',
      CAST(late_shipment_flag AS STRING), '|',
      CAST(critical_delay_flag AS STRING)
    ))) AS exception_signature
  FROM `ferrous-biplane-450410-i2.AI_Mockproject.vw_exceptions`
),

memory_signatures AS (
  SELECT DISTINCT
    exception_signature
  FROM `ferrous-biplane-450410-i2.AI_Mockproject.exception_memory`
)

SELECT
  c.*,
  CASE
    WHEN m.exception_signature IS NULL THEN TRUE
    ELSE FALSE
  END AS is_new_exception,
  CASE
    WHEN m.exception_signature IS NULL THEN 'new'
    ELSE 'known'
  END AS status
FROM current_exceptions c
LEFT JOIN memory_signatures m
  ON c.exception_signature = m.exception_signature;