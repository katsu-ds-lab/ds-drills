query = sql("
SELECT 
  customer_id, 
  PERCENT_RANK() OVER (ORDER BY MD5(customer_id)) AS prank
FROM 
  customer
INNER JOIN 
  receipt r
USING (customer_id)
GROUP BY 
  customer_id
HAVING 
  (SUM(r.amount) > 0.0)
"
)



tbl(con, query) %>% sql_render_ext(con = simulate_mssql(), cte = TRUE)
tbl(con, query) %>% sql_render_ext(con = simulate_mssql(), cte = TRUE) %>% class()
tbl(con, query) %>% sql_render_ext(con = simulate_mssql(), cte = FALSE)

query = sql("
SELECT birth_day, EXTRACT(MONTH FROM birth_day) AS m
FROM customer
LIMIT 5
"
)

tbl(con, query) %>% sql_render(con = simulate_oracle())

# 出力：
# <SQL> 
# SELECT birth_day, EXTRACT(MONTH FROM birth_day) AS m
# FROM customer
# LIMIT 5

# 出力されたSQLクエリが Oracle のものではなく、元のクエリのままになるのは何故？

query
tbl(con, query)
tbl(con, query) %>% class()
tbl(con, query) %>% sql_render_ext(con = simulate_mssql())
# tbl(con, query) %>% sql_render_ext(con = simulate_oracle())
# tbl(con, query) %>% sql_render(con = simulate_oracle())
tbl(con, query) %>% select(m) %>% filter(m > 3) %>% sql_render(con = simulate_oracle())

translate_sql(slice_head(x), con = con)
translate_sql(lubridate::month(x), con = con)
translate_sql(lubridate::month(x), con = simulate_mssql())

#-------------------------------------------------------------------------------
db_result = db_receipt %>% 
  summarise(
    amount = sum(amount, na.rm = TRUE), .by = sales_ymd
  ) %>% 
  filter(!is.na(amount)) %>% 
  window_order(sales_ymd) %>% 
  mutate(
    pre_sales_ymd = lag(sales_ymd), 
    pre_amount = lag(amount), 
    diff_amount = amount - pre_amount
  ) %>% 
  arrange(sales_ymd) %>% 
  head(10)

db_result %>% collect()

db_result %>% class()

db_result %>% sql_render_ext(con = simulate_mssql(), cte = TRUE) %>% class()
db_result %>% sql_render_ext(con = simulate_mssql(), cte = TRUE)
db_result %>% sql_render_ext(con = simulate_mssql(), cte = FALSE)
db_result %>% sql_render_ext(con = simulate_mssql(), qualify_all_columns = F)
db_result %>% sql_render_ext(con = simulate_mssql(), qualify_all_columns = T)

db_result %>% sql_render(con = simulate_mssql())

#-------------------------------------------------------------------------------
db_result = db_customer %>% 
  mutate(
    m = birth_day %>% lubridate::month(), 
    .keep = "used"
  ) %>% 
  head(5)

db_result %>% 
  sql_render(con = simulate_postgres())

db_result %>% 
  sql_render_ext(con = simulate_postgres())

db_result %>% 
  sql_render(con = simulate_oracle())

db_result %>% 
  sql_render_ext(con = simulate_oracle())

