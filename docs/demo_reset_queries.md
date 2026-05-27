# Demo Reset Queries

## 1. Reset exception memory: We need to run this when the table is full
```sql
TRUNCATE TABLE `ferrous-biplane-450410-i2.AI_Mockproject.exception_memory`;



## 2. Confirm memory is empty

SELECT COUNT(*) AS cnt
FROM `ferrous-biplane-450410-i2.AI_Mockproject.exception_memory`;


## 3. Check inserted rows after workflow run

SELECT
  run_timestamp,
  COUNT(*) AS rows_inserted
FROM `ferrous-biplane-450410-i2.AI_Mockproject.exception_memory`
GROUP BY run_timestamp
ORDER BY run_timestamp DESC;