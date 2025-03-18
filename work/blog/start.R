# vignette("new-backend")
# vignette("sql")
# vignette("translation-function", package = "dbplyr")
# vignette("translation-verb")

# SQLクエリからテーブル参照を取得する: tbl()
# my_show_query()

# 標準出力向けの設定 ------------
list(
  "digits" = 2,  
  "tibble.print_max" = 40, # 表示する最大行数.
  "tibble.print_min" = 15, # 表示する最小行数.
  "tibble.width" = NULL,   # 全体の出力幅. デフォルトは NULL.
  "pillar.sigfig" = 4,     # 表示する有効桁数
  "pillar.max_dec_width" = 13 # 10進数表記の最大許容幅
) |> 
  options()
#-------------------------------------------------------------------------------

library(DBI)
library(dplyr)
library(dbplyr)
library(duckdb)

# `dbGetQuery()` ------------

query = 
  "SELECT sales_ymd, product_cd, amount FROM receipt"
d = DBI::dbGetQuery(con, query)
d %>% head(5)

d %>% class() # "data.frame"

query = sql("
SELECT product_cd, SUM(amount) AS total_sales
FROM receipt
WHERE (sales_ymd >= 20180101)
GROUP BY product_cd
ORDER BY total_sales DESC
"
)

DBI::dbGetQuery(con, query)

# n を指定
DBI::dbGetQuery(con, query, n = 3)

# バインドパラメータを使用したクエリ
query = sql("
SELECT product_cd, SUM(amount) AS total_sales
FROM receipt
WHERE (sales_ymd >= ?)
GROUP BY product_cd
ORDER BY total_sales DESC
"
)

DBI::dbGetQuery(con, query, params = list(20190401))
DBI::dbGetQuery(con, query, params = list(20190401)) %>% head(5)

# db_get_query ------------

query = sql("
SELECT product_cd, SUM(amount) AS total_sales
FROM receipt
WHERE (sales_ymd >= 20180101)
GROUP BY product_cd
ORDER BY total_sales DESC
"
)

query %>% db_get_query(con, n = 5)

d = DBI::dbGetQuery(con, query, params = list(20180101))
d %>% head(5)
d = query %>% db_get_query(con, params = list(20200101))
d %>% head(5)

# `sql_render()` ------------

lubridate::as_date("20180101")
20180101L %>% as.character() %>% as.Date("%Y%m%d") %>% format("%Y-%m-%d")
20180101L %>% as.character() %>% as.POSIXct()
20180101L %>% as.character() %>% lubridate::as_date()
# readr::parse_datetime(x, format = fmt, locale = locale(tz = tz))
# 20180101L %>% as.character() %>% readr::parse_datetime()

as.Date("2025-04-01") - as.Date("2024-04-01")
difftime(as.Date("2025-04-01"), as.Date("2024-04-01"), units = "weeks")

db_customer %>% 
  mutate(
    m = birth_day %>% lubridate::month(), 
    # s = sales_ymd %>% as.character() %>% as.Date("%Y%m%d"), 
    # s = sales_ymd %>% as.character() %>% lubridate::as_date(), 
    # s = sales_ymd %>% as.character() %>% readr::parse_datetime(), 
    # d = as.Date("2025-04-01") - as.Date("2024-04-01"), 
    # d = difftime(as.Date("2025-04-01"), as.Date("2024-04-01")), 
    # d = birth_day - lubridate::days(3L), 
    .keep = "used"
  ) %>% 
  head(5) -> 
  db_result
db_result

db_customer %>% 
  mutate(
    m = birth_day %>% lubridate::month(), 
    .keep = "used"
  ) %>% 
  head(5) -> 
  db_result

db_result %>% 
  sql_render(con = simulate_postgres())

db_result

# データベースシミュレーター
# simulate_*() を使えば、特定のデータベース向けの SQL を生成できる
# 実際のデータベース接続なしで SQL を試せるので、デバッグや開発時に便利
# JOIN などの複雑なクエリも簡単に確認できる
# 「データベースがないけど SQL を確認したい！」というときに simulate_*() を使おう！

db_result %>% 
  sql_render(con = simulate_postgres())

db_result %>% show_query()
db_result %>% sql_render()

# MySQL/MariaDB、Snowflake、Oracle、SQL server で試す場合は、以下のようになります。

db_result %>% sql_render(con = simulate_mysql())
db_result %>% sql_render(con = simulate_snowflake())
db_result %>% sql_render(con = simulate_oracle())
db_result %>% sql_render(con = simulate_mssql())

db_result %>% sql_render(con = simulate_postgres())
db_result %>% sql_render(con = simulate_redshift())

db_result %>% sql_render_ext(con = simulate_redshift())
db_result %>% sql_render_ext(con = simulate_postgres())
db_result %>% sql_render_ext(con = simulate_mysql())
db_result %>% sql_render_ext(con = simulate_snowflake())
db_result %>% sql_render_ext(con = simulate_oracle())
db_result %>% sql_render_ext(con = simulate_mssql())

db_result %>% sql_render_ext(con = simulate_mysql(), subquery = TRUE)
db_result %>% sql_render_ext(con = simulate_mysql(), subquery = FALSE)

lf <- lazy_frame(a = TRUE, b = 1, c = 2, d = "z", con = simulate_postgres())
lf
lf %>% summarise(x = sd(b, na.rm = TRUE))
lf %>% summarise(y = cor(b, c), z = cov(b, c))

db_result = db_customer %>% 
  left_join(
    db_receipt %>% select(customer_id, amount), 
    by = "customer_id"
  ) %>% 
  group_by(customer_id) %>% 
  summarise(sum_amount = sum(amount, na.rm = TRUE)) %>% 
  arrange(customer_id)

db_result

db_result %>% sql_render(
    con = simulate_mysql(), 
    sql_options = sql_options(cte = TRUE)
  )

db_result %>% 
  sql_render_ext(con = simulate_mysql(), cte = TRUE)

db_result %>% sql_render_ext(
    con = simulate_mysql(), cte = TRUE, 
    replacement = "\""
  )

# sql_render
db_result %>% 
  sql_render(
    sql_options = 
      sql_options(cte = TRUE, use_star = FALSE, qualify_all_columns = FALSE)
  )
# sql_render_ext
db_result %>% 
  sql_render_ext(cte = TRUE, use_star = FALSE, qualify_all_columns = FALSE)

# options(dbplyr.sql_translator = dbplyr::simulate_mssql())
# db_result %>% sql_render()
# query = db_result %>% sql_render(con = simulate_mssql())
# query

# options(dbplyr.sql_translator = dbplyr::simulate_mssql()) を設定しても、
# sql_render() の結果のクエリをバッククォートで括られてしまう。

# db_customer %>%
#   left_join(db_receipt, by = "customer_id") %>%
#   sql_render(con = simulate_mssql())
# を実行しても、sql_render() の結果のクエリをバッククォートで括られてしまう。
