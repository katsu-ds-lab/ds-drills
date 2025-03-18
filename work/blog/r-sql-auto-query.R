# 必要なパッケージをロード
library(DBI)
library(dplyr)
library(dbplyr)
library(duckdb)

# DuckDB に接続 (一時データベース)
con = DBI::dbConnect(duckdb::duckdb())

# サンプルのデータフレームを作成
df_sales = tribble(
  ~store, ~sales, ~profit,
  "S001", 15000, 3000,
  "S002", 18000, 3500,
  "S003", 12000, 2500,
  "S004", 20000, 4000,
  "S005", 16000, 3200
)

# テーブルとしてデータベースに登録
DBI::dbWriteTable(
  con, "store_sales", df_sales, overwrite = TRUE
)

# store_sales テーブルを dplyr で参照
db_store_sales = tbl(con, "store_sales")

# フィルタリングと並び替え
# (テーブル操作をSQLクエリとして保持)
db_result = 
  db_store_sales %>%
  filter(sales >= 15000) %>%
  arrange(desc(profit))

# SQLクエリの生成・確認
show_query(db_result)
# => 
# <SQL>
# SELECT store_sales.*
# FROM store_sales
# WHERE (sales >= 15000.0)
# ORDER BY profit DESC

# SQLクエリの結果を R 側に取り込む
df_result = collect(db_result)

# 以下、データフレームでの処理
df_result %>% head(3)
# => 
# # A tibble: 3 × 3
#   store sales profit
#   <chr> <dbl>  <dbl>
# 1 S004  20000   4000
# 2 S002  18000   3500
# 3 S005  16000   3200

#-------------------------------------------------------------------------------
# カスタムメソッドを定義
custom_db_get_info = function(dbObj, ...) {
  ll = attr(dbObj, "driver") |> dbGetInfo()
  # s = ll$dbname
  # dbname = paste0(
  #   stringr::str_sub(s, 1, 7), 
  #   "...", 
  #   stringr::str_sub(s, stringr::str_length(s) - 24)
  # )
  list(
    # dbname = ll$dbname, 
    dbname = stringr::str_trunc(ll$dbname, 23, "left"), 
    # dbname = dbname, 
    db.version = ll$driver.version
  )
}

# dbGetInfo メソッドを duckdb_connection 用にオーバーライド
methods::setMethod("dbGetInfo", "duckdb_connection", custom_db_get_info)

#-------------------------------------------------------------------------------

db_result %>% print(n = 3)

db_result %>% head(3) %>% show_query()
