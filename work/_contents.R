#-------------------------------------------------------------------------------

df_customer %>% 
  summarise(
    n1 = sum(ifelse(gender_cd == "1", 1L, 0L))
  )

db_customer %>% 
  summarise(
    n1 = sum(ifelse(gender_cd == "1", 1L, 0L))
  )

db_customer %>% 
  summarise(
    n1 = sum(ifelse(gender_cd == "1", 1L, 0L)), 
    n = n()
  ) -> 
  db_result
db_result %>% my_show_query()

<SQL>
SELECT
  SUM(CASE WHEN (gender_cd = '1') THEN 1 WHEN NOT (gender_cd = '1') THEN 0 END) AS n1,
  COUNT(*) AS n
FROM customer

#-------------------------------------------------------------------------------
db_receipt %>% 
  filter(sales_ymd >= 20180101L ) %>%  
  group_by(product_cd) %>% 
  summarise(total_sales = sum(amount)) %>% 
  arrange(desc(total_sales)) -> 
  db_result

db_result %>% my_show_query(cte = F)

query = sql("
WITH q01 AS (
  SELECT receipt.*
  FROM receipt
  WHERE (sales_ymd >= 20180101)
)
SELECT product_cd, SUM(amount) AS total_sales
FROM q01
GROUP BY product_cd
ORDER BY total_sales DESC
"
)
query %>% db_get_query(con) # con はデータベース接続オブジェクト

query %>% db_get_query(con, convert_tibble = F) %>% class()
#> [1] "data.frame"

# A tibble: 7,061 × 2
   product_cd total_sales
   <chr>            <dbl>
 1 P071401001     1233100
 2 P071401002      429000
 3 P071401003      371800
 4 P060303001      346320
 5 P071401012      305800
 6 P071401014      277200
 7 P071401024      271200
 8 P071401022      268800
 9 P071401013      264000
10 P071401004      256300
11 P071401025      247200
12 P071401007      241200
13 P071401017      239800
14 P071401019      237600
15 P071401020      237600
# ℹ 7,046 more rows
# ℹ Use `print(n = ...)` to see more rows


db_receipt %>% 
  filter(sales_ymd >= 20180101L ) %>% 
  arrange(sales_ymd) %>% 
  my_show_query()

query = sql("
SELECT sales_ymd, store_cd, product_cd, amount
FROM receipt
WHERE (sales_ymd >= ?)
ORDER BY sales_ymd
"
)
query %>% db_get_query(con, params = list(20190123))

#-------------------------------------------------------------------------------
db_receipt %>% 
  filter(sales_ymd >= 20180101L ) %>%  
  group_by(product_cd) %>% 
  summarise(total_sales = sum(amount)) %>% 
  arrange(desc(total_sales)) -> 
  db_result

db_result %>% my_show_query()

db_result %>% sql_render_ext()
db_result %>% sql_render()

db_result %>% sql_render_ext(con = simulate_mysql())
db_result %>% sql_render_ext(con = simulate_postgres())
db_result %>% sql_render_ext(con = simulate_snowflake())

db_result %>% sql_render(con = simulate_mysql())
db_result %>% sql_render(con = simulate_postgres())
db_result %>% sql_render(con = simulate_snowflake())

db_result %>% sql_render(sql_options = sql_options(cte = T, use_star = F))
db_result %>% 
  sql_render_ext(cte = T, use_star = F, qualify_all_columns = F)

db_result %>% 
  sql_render(
    sql_options = 
      sql_options(cte = T, use_star = F, qualify_all_columns = F)
  )

db_result %>% sql_render(con = simulate_mysql())

<SQL> SELECT `product_cd`, SUM(`amount`) AS `total_sales`
FROM (
  SELECT `receipt`.*
  FROM receipt
  WHERE (`sales_ymd` >= 20180101)
) AS `q01`
GROUP BY `product_cd`
ORDER BY `total_sales` DESC

db_result %>% sql_render_ext(con = simulate_mysql())

<SQL> WITH q01 AS (
  SELECT receipt.*
  FROM receipt
  WHERE (sales_ymd >= 20180101)
)
SELECT product_cd, SUM(amount) AS total_sales
FROM q01
GROUP BY product_cd
ORDER BY total_sales DESC

db_result %>% 
  sql_render_ext(
    con = simulate_mysql(), pattern = "`", replacement = "\""
  )

<SQL> WITH "q01" AS (
  SELECT "receipt".*
  FROM receipt
  WHERE ("sales_ymd" >= 20180101)
)
SELECT "product_cd", SUM("amount") AS "total_sales"
FROM "q01"
GROUP BY "product_cd"
ORDER BY "total_sales" DESC


db_product %>% 
  group_by(category_major_cd) %>% 
  summarise(
    n = n(), 
    mean = mean(unit_price), 
    q1 = quantile(unit_price, probs = 0.25), # 第一四分位点
    sd = sd(unit_price) # 標準偏差
  ) %>% 
  arrange(category_major_cd) -> 
  db_result

db_result %>% my_show_query()
db_result %>% sql_render_ext(con = simulate_mysql())
db_result %>% sql_render_ext(con = simulate_postgres())
db_result %>% sql_render_ext(con = simulate_snowflake())

#-------------------------------------------------------------------------------
# tbl()
db_receipt %>% 
  filter(sales_ymd >= 20180101L ) %>% 
  my_show_query()

query = sql("
SELECT sales_ymd, product_cd, amount
FROM receipt
WHERE (sales_ymd >= 20180101)
"
)
query = tbl(con, q)
query

# Source:   SQL [?? x 3]
# Database: DuckDB v1.1.3-dev165 [root@Darwin 24.1.0:R 4.4.2/.../DB/100knocks.duckdb]
  sales_ymd product_cd amount
      <int> <chr>       <dbl>
1  20181103 P070305012    158
2  20181118 P070701017     81
3  20190205 P050301001     25
4  20180821 P060102007     90
5  20190605 P050102002    138
6  20181205 P080101005     30
7  20190922 P070501004    128
...

query %>% 
  group_by(product_cd) %>% 
  summarise(total_sales = sum(amount)) %>% 
  arrange(desc(total_sales)) -> 
  db_result
db_result

# Source:     SQL [?? x 2]
# Database:   DuckDB v1.1.3-dev165 [root@Darwin 24.1.0:R 4.4.2/.../DB/100knocks.duckdb]
# Ordered by: desc(total_sales)
  product_cd total_sales
  <chr>            <dbl>
1 P071401001     1233100
2 P071401002      429000
3 P071401003      371800
4 P060303001      346320
5 P071401012      305800
6 P071401014      277200
...

print(db_result)
