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

# d = tibble(a = 0.123456, b = 123.123456, c = 123456700000, d = 100 * b)
# d
# d$a

#-------------------------------------------------------------------------------
# 必要なパッケージをロード
library(DBI)
library(dplyr)
library(dbplyr)
library(duckdb)
library(tibble)

# サンプルのデータフレームを作成
df_sales = tribble(
  ~store, ~month, ~sales, ~profit, 
  "S001",  4L,     150,   30, 
  "S001",  5L,     170,   34, 
  "S001",  6L,     140,   27, 
  "S001",  7L,     160,   32, 
  "S002",  4L,     NA,    28, 
  "S002",  5L,     160,   31, 
  "S002",  6L,     130,   27, 
  "S002",  7L,     150,   28
)

df_master = tribble(
  ~store, ~name,    ~pref, 
  "S001", "storeA", "Tokyo", 
  "S002", "storeB", "Osaka", 
  "S003", "storeC", "Kanagawa", 
  "S004", "storeD", "Fukuoka"
)

# DuckDB に接続 (一時データベース)
con = DBI::dbConnect(duckdb::duckdb())

# テーブルとしてデータベースに登録
DBI::dbWriteTable(
  con, "store_sales", df_sales, overwrite = TRUE
)
DBI::dbWriteTable(
  con, "store_master", df_master, overwrite = TRUE
)

# store_sales テーブルを dplyr で参照
db_sales = tbl(con, "store_sales")
db_master = tbl(con, "store_master")

#...............................................................................

# dbplyr の変換は完璧ではありません。
# SQLは正しくても、簡潔ではないSQLクエリに変換されるケース

db_sales %>% 
  filter(!is.na(sales)) %>% 
  show_query()

query = sql("
SELECT store_sales.*
FROM store_sales
WHERE sales IS NOT NULL
"
)
query %>% db_get_query(con)

# 
db_sales %>% show_query()
db_sales %>% my_show_query(F)

### dplyr 操作全体の変換

## 単一テーブルの操作

# `select()` は `SELECT` 句を修正します: 
db_sales %>% 
  select(store, sales) %>% 
  my_show_query(F)

db_sales %>% 
  rename(store_code = store) %>% 
  # show_query()
  my_show_query(F)

db_sales %>% 
  relocate(profit, sales, .after = store) %>% 
  my_show_query(F)

# "month" がダブルクォートで括られてるのは、これが duckdb の予約語だからです。

# `mutate()` は `SELECT` 句を修正します: 
db_sales %>% 
  mutate(
    margin = 100 * profit / sales, 
    .keep = "unused"
  ) %>% 
  my_show_query(F)

# filter() は WHERE 句を生成します
db_sales %>% 
  filter(month == 4L & profit >= 30) %>% 
  my_show_query(F)

# arrange() は ORDER BY 句を生成します
db_sales %>% 
  arrange(month, desc(profit)) %>% 
  my_show_query(F)

# `distinct()` は SQL の `DISTINCT` 修飾子を生成します。
db_sales %>% 
  distinct() %>% 
  show_query()
  my_show_query(F)

db_sales %>% 
  distinct(store) %>% 
  show_query()
  my_show_query(F)

# summarise() は要約関数と合わせて SELECT 句を修正します
db_sales %>% 
  summarise(avg_profit = mean(profit)) %>% 
  # show_query()
  my_show_query(F)

# summarise() は group_by() と合わせて GROUP BY 句を生成します
db_sales %>% 
  group_by(store) %>% 
  summarise(avg_profit = mean(profit)) %>% 
  # show_query()
  my_show_query(F)

# 要約後の filter() は HAVING 句を生成します
db_sales %>% 
  group_by(store) %>% 
  summarise(avg_profit = mean(profit)) %>% 
  filter(avg_profit > 30) %>% 
  # show_query()
  my_show_query(F)

# head() は LIMIT 句を生成します
db_sales %>% 
  head(3) %>% 
  # show_query()
  my_show_query(F)

## 2つのテーブルの操作

# inner_join() LEFT JOIN 句を生成します
db_sales %>% 
  inner_join(db_master, by = "store") %>% 
  show_query()
  my_show_query(F)

# left_join(), right_join() についても同様です。

# full_join() は FULL JOIN 句を生成します
db_sales %>% 
  full_join(db_master, by = "store") %>% 
  # show_query()
  my_show_query(F)

# cross_join() は CROSS JOIN 句を生成します
db_master %>% 
  select(store) %>% 
  cross_join(db_sales %>% select(month)) %>% 
  # show_query()
  my_show_query(F)

# semi_join() は WHERE 句の EXISTS 演算子を生成します
db_master %>% 
  semi_join(db_sales, by = "store") %>% 
  # show_query()
  my_show_query(F)

# anti_join() は WHERE 句の NOT EXISTS 演算子を生成します。
db_master %>% 
  anti_join(db_sales, by = "store") %>% 
  # show_query()
  my_show_query(F)

# intersect() は INTERSECT 演算子を生成します。
db_sales %>% 
  select(store) %>% 
  intersect(db_master %>% select(store)) %>% 
  # show_query()
  my_show_query(F)

# union() は UNION 演算子を生成します。
db_sales %>% 
  select(store) %>% 
  union(db_master %>% select(store)) %>% 
  # show_query()
  my_show_query(F)

# union_all() は UNION ALL 演算子を生成します。
db_sales %>% 
  select(store) %>% 
  union_all(db_master %>% select(store)) %>% 
  # show_query()
  my_show_query(F)

# setdiff() は EXCEPT 演算子を生成します。
db_master %>% 
  select(store) %>% 
  setdiff(db_sales %>% select(store)) %>% 
  # show_query()
  my_show_query(F)

## その他の操作

# count(), slice_min(), slice_max(), replace_na(), pivot_longer() などのその他の操作については、
# ここまでに挙げた SQLの句や演算子、SQL関数を組み合わせて変換されます。

# 例えば、count() は次のように変換されます。
db_sales %>% 
  count(store, name = "n_month") %>% 
  # show_query()
  my_show_query(F)

# pivot_longer() は次のように変換されます。
db_sales %>% 
  tidyr::pivot_longer(
    -c(store, month), names_to = "name", values_to = "amount"
  ) %>% 
  show_query()
  my_show_query(F)

### dplyr 操作内の式の変換

# 1. dplyr が認識できる式
# 2. dplyr が認識できない式

## dplyr が認識できる式

# 算術演算子
db_sales %>% 
  mutate(
    v1 = sales + profit, 
    v2 = 100 * (sales - profit) / sales, 
    v3 = profit ^ 2L, 
    .keep = "none"
  ) %>% 
  # show_query()
  my_show_query(F)

# 比較演算子、論理演算子(&, |, !)
db_sales %>% 
  mutate(
    v1 = (sales == 150), 
    v2 = (!(sales > 150)), 
    v3 = (sales != 150 & profit >= 30), 
    v4 = (sales < 150 | profit <= 30), 
    v5 = (store %in% c("S001", "S003")), 
    .keep = "used"
  ) %>% 
  # show_query()
  my_show_query(F)

# 数学関数、数値の丸め
db_sales %>% 
  mutate(
    v1 = log(profit), 
    v2 = sqrt(profit), 
    v3 = sin(profit), 
    v4 = floor(sales / profit), 
    .keep = "none"
  ) %>% 
  # show_query()
  my_show_query(F)

# 型変換
db_sales %>% 
  mutate(
    v1 = as.integer(profit), 
    v2 = as.numeric(month), 
    v3 = as.double(month), 
    v4 = as.character(month), 
    v5 = as.Date("2025-04-01"), 
    .keep = "used"
  ) %>% 
  # show_query()
  my_show_query(F)

# 文字列関数
db_master %>% 
  mutate(
    len = nchar(pref), 
    upp = toupper(pref), 
    sub = substr(name, 6, 6), 
    p = paste(name, pref, sep = "-"), 
    .keep = "used"
  ) %>% 
  # show_query()
  my_show_query(F)

# 日付関数
db_master %>% 
  mutate(
    ymd = lubridate::as_date("2025-04-01"), 
    .keep = "none"
  ) %>% 
  head(1) %>% 
  mutate(
    # strftime = strftime(ymd, "%Y/%m/%d"), 
    month = lubridate::month(ymd), 
    add = ymd + lubridate::days(7L), 
    .keep = "used"
  ) %>% 
  show_query(cte = TRUE)
  # my_show_query(F)

date1 <- as.Date("2023-01-15")
date2 <- as.Date("2023-01-10")
# 2つの日付の差を日単位で計算
difftime(date1, date2, units = "days")

# パターンマッチング
db_master %>% 
  filter(
    stringr::str_detect(pref, "ka$")
  ) %>% 
  # show_query()
  my_show_query(F)

# is.na()
db_sales %>% 
  filter(is.na(sales)) %>% 
  show_query()
  my_show_query(F)

# if_else()
db_sales %>% 
  mutate(
    profit_size = 
      if_else(sales > 150, "big", "small", "none"), 
    .keep = "used"
  ) %>% 
  # show_query()
  my_show_query(F)

query = sql("
SELECT
  sales,
  CASE 
    WHEN (sales > 150.0) THEN 'big' 
    WHEN NOT (sales > 150.0) THEN 'small' 
    ELSE 'none'
  END AS profit_size
FROM store_sales
"
)
query %>% db_get_query(con)



# 要約関数 (`summarise`内)
db_sales %>% 
  summarise(
    n = n(), 
    n_store = n_distinct(store), 
    avg = mean(sales), 
    per50 = median(sales)
  ) %>% 
  # show_query()
  my_show_query(F)

# ウィンドウ関数への変換

# mutate() + 要約関数

db_sales %>% 
  mutate(
    n = n(), 
    avg = mean(sales), 
    max = max(sales)
  ) %>% 
  # show_query()
  my_show_query(F)

# group_by() を併用した場合

db_sales %>% 
  group_by(month) %>% 
  mutate(
    n = n(), 
    avg = mean(sales), 
    max = max(sales)
  ) %>% 
  # show_query()
  my_show_query(F)

# window_order(), window_frame()
db_sales %>% 
  group_by(store) %>% 
  window_order(month) %>% 
  window_frame(-1, 1) %>% 
  mutate(
    avg_win = mean(sales)
  ) %>% 
  # show_query()
  my_show_query(F)

# lag(), lead()

db_sales %>% 
  group_by(store) %>% 
  mutate(
    lag_profit = lag(profit, 1L, order_by = month)
  ) %>% 
  # show_query()
  my_show_query(F)

db_sales %>% 
  group_by(store) %>% 
  window_order(month) %>% 
  mutate(
    lag_p = lag(profit, 1L), 
    lead_p = lead(profit, 1L)
  ) %>% 
  # show_query()
  my_show_query(F)


# lead() についても同様です。

# mutate + ランキング関数

db_sales %>% 
  group_by(store) %>% 
  mutate(
    rank = min_rank(desc(sales)), 
    .keep = "used"
  ) %>% 
  # show_query()
  my_show_query(F)


# mutate + 累積関数

db_sales %>% 
  group_by(store) %>% 
  window_order(month) %>% 
  mutate(
    cum = cumsum(profit)
  ) %>% 
  # show_query()
  my_show_query(F)

#...............................................................................
## 2. dplyr が認識できない式

# Prefix functions

db_sales %>% 
  mutate(
    v1 = CEIL(profit / sales), 
    v2 = EVEN(month)
  ) %>% 
  show_query()
  my_show_query(F)

# Infix functions
# LIKE
db_master %>% 
  filter(
    pref %LIKE% "%ka"
  ) %>% 
  show_query()
  my_show_query(F)

# Special forms
# SQL の構文をそのまま埋め込む

# SQL の式は、R よりも構文の種類が豊富になる傾向があるため、R コードから直接変換できない式もあります。
# 次のように sql() によるリテラル SQL を用いると、変換を介さずに 直接 SQL の式を埋め込むことができます。

d1 %>% mutate(m = sql("QUANTILE_CONT(x, 0.5) OVER ()"))

db_sales %>% 
  mutate(
    sales2 = sql("IFNULL(sales, 0.0)"), 
    store_rev = sql("REVERSE(store)"), 
    per25 = sql("QUANTILE_CONT(profit, 0.25) OVER ()")
  ) %>% 
  # show_query()
  my_show_query(F)

# これにより、必要な SQL を自由に生成できるようになります。

# options(dplyr.strict_sql)

# dbplyr を強制的にエラーにする

# options(dplyr.strict_sql = FALSE)
options(dplyr.strict_sql = TRUE)

db_sales %>% 
  mutate(
    v = EVEN(month)
  )

db_master %>% 
  filter(
    pref %LIKE% "%ka"
  )


#-------------------------------------------------------------------------------


options(dplyr.strict_sql = FALSE)
options(dplyr.strict_sql = TRUE)
n
# ~store, ~month, ~sales, ~profit
db_sales %>% mutate(m = mean(profit))
db_sales %>% mutate(m = mean(profit, trim = 0.2))
#> mean(profit, trim = 0.2) でエラー: 使われていない引数 (trim = 0.2)

db_sales %>% collect() %>% mutate(m = mean(profit, trim = 0.2))

db_result = db_sales %>% mutate(m = xxx(profit))
db_result %>% show_query()

translate_sql(xxx(x, y), con = con)
translate_sql(mean(x, trim = 0.2), con = con)
#> mean(profit, trim = 0.2) でエラー: 使われていない引数 (trim = 0.2)

c(1, 2, 3, 4, 10) %>% mean(na.rm = T, trim = 0.2)

「dbplyr は、dplyr が変換方法を認識できない式については、そのまま SQL に残します。」

SQLに変換するのはdbplyrの役割ですよね？
「dbplyr が変換する方法が分からない式」は「dplyr が認識できない式」と同等ですか？

db_result = db_sales %>% mutate(combined = paste(store, store))
db_result %>% show_query()

「dplyr が認識できない式」
→ そもそも dplyr が処理できず、R のエラーになるもの。
「dbplyr が SQL に変換できない式」
→ dplyr では解釈できるが、dbplyr が SQL に変換する方法を知らないもの（R 固有の関数など）。

db_sales %>% mutate(avg_sales = mean(sales)) %>% show_query()

「dplyr が SQL への変換方法を知らない関数」という表現は、
「SQLに変換するのはdbplyrの役割である」ことと矛盾しない？

