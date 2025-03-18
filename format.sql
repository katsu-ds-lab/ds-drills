WITH product_num AS (
  SELECT 
    store_cd,
    product_cd,
    COUNT(*) AS n
  FROM 
    receipt
  GROUP BY 
    store_cd, product_cd
),
product_rank AS (
  SELECT 
    *,
    RANK() OVER (
      PARTITION BY store_cd
      ORDER BY n DESC
    ) AS rank
  FROM 
    product_num
)
SELECT 
  store_cd,
  product_cd,
  n
FROM 
  product_rank
WHERE
  rank = 1
ORDER BY 
  store_cd
LIMIT 10
;
