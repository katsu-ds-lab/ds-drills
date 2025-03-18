#-------------------------------------------------------------------------------
# テーブル参照の標準出力のカスタマイズ ------------
# Database: DuckDB v1.1.3-dev165 [root@Darwin 24.1.0:R 4.4.2//Users/.../work/DB/100knocks.duckdb]

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

DBI::dbGetInfo(con)
db_receipt %>% head(1)
# Source:   table<receipt> [?? x 9]
# Database: DuckDB v1.1.3-dev165 [root@Darwin 24.1.0:R 4.4.2/.../DB/100knocks.duckdb]
#    sales_ymd sales_epoch store_cd receipt_no receipt_sub_no customer_id   
#        <int>       <int> <chr>         <int>          <int> <chr>         
#  1  20181103  1541203200 S14006          112              1 CS006214000001

# 標準出力向けの設定 ------------
list(
  "digits" = 2,  
  "tibble.print_max" = 40, # 表示する最大行数.
  "tibble.print_min" = 15, # 表示する最小行数.
  "tibble.width" = NULL,   # 全体の出力幅. デフォルトは NULL.
  "pillar.sigfig" = 5,     # 表示する有効桁数
  "pillar.max_dec_width" = 13 # 10進数表記の最大許容幅
) |> 
  options()

# dplyr が認識できない関数をエラーにする
options(dplyr.strict_sql = TRUE)

#-------------------------------------------------------------------------------
# R-003 ------------
# レシート明細データ（df_receipt）から売上年月日（sales_ymd）、顧客ID（customer_id）、
# 商品コード（product_cd）、売上金額（amount）の順に列を指定し、10件表示せよ。
# ただし、sales_ymdをsales_dateに項目名を変更しながら抽出すること。

# ブログには掲載しない

# [R] データフレームでの処理
df_receipt %>% 
  select(sales_date = sales_ymd, customer_id, product_cd, amount) %>% 
  head(10)

# A tibble: 10 × 4
#    sales_date customer_id    product_cd amount
#         <int> <chr>          <chr>       <dbl>
#  1   20181103 CS006214000001 P070305012    158
#  2   20181118 CS008415000097 P070701017     81
#  3   20170712 CS028414000014 P060101005    170
#  4   20190205 ZZ000000000000 P050301001     25
#  5   20180821 CS025415000050 P060102007     90
#  6   20190605 CS003515000195 P050102002    138
#  7   20181205 CS024514000042 P080101005     30
#  8   20190922 CS040415000178 P070501004    128
#  9   20170504 ZZ000000000000 P071302010    770
# 10   20191010 CS027514000015 P071101003    680

#...............................................................................
# [R] データベース・バックエンドでの処理
db_result = db_receipt %>% 
  select(sales_date = sales_ymd, customer_id, product_cd, amount) %>% 
  head(10)

db_result %>% collect()

db_result
# Source:   SQL [10 x 4]
# Database: DuckDB v1.1.3-dev165 [root@Darwin 24.1.0:R 4.4.2/.../DB/100knocks.duckdb]
#    sales_date customer_id    product_cd amount
#         <int> <chr>          <chr>       <dbl>
#  1   20181103 CS006214000001 P070305012    158
#  2   20181118 CS008415000097 P070701017     81
#  3   20170712 CS028414000014 P060101005    170
#  4   20190205 ZZ000000000000 P050301001     25
#  5   20180821 CS025415000050 P060102007     90
#  6   20190605 CS003515000195 P050102002    138
#  7   20181205 CS024514000042 P080101005     30
#  8   20190922 CS040415000178 P070501004    128
#  9   20170504 ZZ000000000000 P071302010    770
# 10   20191010 CS027514000015 P071101003    680

# class(db_result)
# [1] "tbl_duckdb_connection" "tbl_dbi"               "tbl_sql"              
# [4] "tbl_lazy"              "tbl"

#...............................................................................
# SQLクエリ
db_result %>% my_show_query()

# <SQL>
# SELECT sales_ymd AS sales_date, customer_id, product_cd, amount
# FROM receipt
# LIMIT 10

# リライト
# SELECT 
#   sales_ymd AS sales_date,
#   customer_id,
#   product_cd,
#   amount
# FROM 
#   receipt
# LIMIT 10

#-------------------------------------------------------------------------------
# R-029 ------------
# レシート明細データ（df_receipt）に対し、店舗コード（store_cd）ごとに商品コード（product_cd）の最頻値を求め、10件表示させよ。

# 店舗ごとに最も頻出する商品コードを求める問題です。

# level: 1

# tag: 
# 統計量, 集約関数, ランキング関数, ウィンドウ関数, グループ化, フィルタリング

# レシート明細 (df_receipt) データの概要
df_receipt %>% select(store_cd, product_cd)
df_receipt %>% select(store_cd, product_cd) %>% head(7)

# 結果がたまたま store_cd で ソートされる場合もありますが、順序は保証されないため、
# 確実にソートしたい場合は arrange()を使うべきです。

# 以下は、最頻値が複数ある場合は全てを表示する解答例です。

# sample.1 ------------

# [R] データフレーム操作
df_result = df_receipt %>% 
  count(store_cd, product_cd) %>% 
  filter(n == max(n), .by = store_cd) %>% 
  arrange(desc(n), store_cd) %>% 
  head(10)

df_result

# sample.2 ------------

# [R] データフレームでの処理
df_result = df_receipt %>% 
  count(store_cd, product_cd) %>% 
  slice_max(n, n = 1, with_ties = TRUE, by = store_cd) %>% 
  arrange(desc(n), store_cd) %>% 
  head(10)

df_result

# A tibble: 10 × 3
#    store_cd product_cd     n
#    <chr>    <chr>      <int>
#  1 S14027   P060303001   152
#  2 S14012   P060303001   142
#  3 S14028   P060303001   140
#  4 S12030   P060303001   115
#  5 S13031   P060303001   115
#  6 S12013   P060303001   107
#  7 S13044   P060303001    96
#  8 S14024   P060303001    96
#  9 S12029   P060303001    92
# 10 S13004   P060303001    88

#...............................................................................
# [R] データベース・バックエンドでの処理

# sample.1 ------------

db_result = db_receipt %>% 
  count(store_cd, product_cd) %>% 
  filter(n == max(n), .by = store_cd) %>% 
  arrange(desc(n), store_cd) %>% 
  head(10)

db_result %>% collect()

# A tibble: 10 × 3
#    store_cd product_cd     n
#    <chr>    <chr>      <dbl>
#  1 S14027   P060303001   152
#  2 S14012   P060303001   142
#  3 S14028   P060303001   140
#  4 S12030   P060303001   115
#  5 S13031   P060303001   115
#  6 S12013   P060303001   107
#  7 S14024   P060303001    96
#  8 S13044   P060303001    96
#  9 S12029   P060303001    92
# 10 S13004   P060303001    88

# sample.2 ------------

db_result = db_receipt %>% 
  count(store_cd, product_cd) %>% 
  slice_max(n, n = 1, with_ties = TRUE, by = store_cd) %>% 
  arrange(desc(n), store_cd) %>% 
  head(10)

db_result %>% collect()

# A tibble: 10 × 3
#    store_cd product_cd     n
#    <chr>    <chr>      <dbl>
#  1 S14027   P060303001   152
#  2 S14012   P060303001   142
#  3 S14028   P060303001   140
#  4 S12030   P060303001   115
#  5 S13031   P060303001   115
#  6 S12013   P060303001   107
#  7 S13044   P060303001    96
#  8 S14024   P060303001    96
#  9 S12029   P060303001    92
# 10 S13004   P060303001    88

#...............................................................................
# SQLクエリ

db_result %>% show_query(cte = TRUE)

# sample.1 ------------

# <SQL>
# WITH q01 AS (
#   SELECT store_cd, product_cd, COUNT(*) AS n
#   FROM receipt
#   GROUP BY store_cd, product_cd
# ),
# q02 AS (
#   SELECT q01.*, MAX(n) OVER (PARTITION BY store_cd) AS col01
#   FROM q01
# )
# SELECT store_cd, product_cd, n
# FROM q02 q01
# WHERE (n = col01)
# ORDER BY n DESC, store_cd
# LIMIT 10

query = sql("
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
product_max AS (
  SELECT 
    store_cd,
    product_cd,
    n, 
    MAX(n) OVER (PARTITION BY store_cd) AS max_n
  FROM product_num
)
SELECT 
  store_cd, 
  product_cd, 
  n
FROM 
  product_max
WHERE 
  n = max_n
ORDER BY 
  n DESC, store_cd
LIMIT 10
"
)

query %>% db_get_query(con)

# col01, q01, q02 は dbplyrパッケージで自動生成されるエイリアス名.
# col01: 中間列名
# エイリアス名を直接指定する方法はありません。

# sample.2 ------------

db_result %>% show_query(cte = TRUE)

# WITH q01 AS (
#   SELECT store_cd, product_cd, COUNT(*) AS n
#   FROM receipt
#   GROUP BY store_cd, product_cd
# ),
# q02 AS (
#   SELECT q01.*, RANK() OVER (PARTITION BY store_cd ORDER BY n DESC) AS col01
#   FROM q01
# )
# SELECT store_cd, product_cd, n
# FROM q02 q01
# WHERE (col01 <= 1)
# ORDER BY n DESC, store_cd
# LIMIT 10

# リライト
query = sql("
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
    store_cd,
    product_cd,
    n, 
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
  n DESC, store_cd
LIMIT 10
"
)
query %>% db_get_query(con)

#-------------------------------------------------------------------------------
# R-035 ------------
# レシート明細データ（receipt）に対し、顧客ID（customer_id）ごとに売上金額（amount）を合計して
# 全顧客の平均を求め、平均以上に買い物をしている顧客を抽出し、10件表示せよ。
# ただし、顧客IDが"Z"から始まるものは非会員を表すため、除外して計算すること。

# 非会員を除外し、顧客ごとの売上合計の平均を求め、平均以上の顧客を抽出する問題です。

# level: 1

# tag: 
# 統計量, 集約関数, ウィンドウ関数, グループ化, パターンマッチング, フィルタリング

df_receipt %>% glimpse()

df_receipt %>% 
  filter(!str_detect(customer_id, "^Z")) %>% 
  summarise(sum_amount = sum(amount), .by = customer_id) %>% 
  # mutate(.mean = mean(sum_amount)) %>% 
  # filter(sum_amount >= .mean) %>% 
  filter(sum_amount >= mean(sum_amount)) %>% 
  arrange(desc(sum_amount), customer_id) %>% 
  head(10)

# A tibble: 10 × 2
#    customer_id    sum_amount
#    <chr>               <dbl>
#  1 CS017415000097      23086
#  2 CS015415000185      20153
#  3 CS031414000051      19202
#  4 CS028415000007      19127
#  5 CS001605000009      18925
#  6 CS010214000010      18585
#  7 CS006515000023      18372
#  8 CS016415000141      18372
#  9 CS011414000106      18338
# 10 CS038415000104      17847

#...............................................................................
# dbplyr
db_receipt %>% glimpse()

db_result = db_receipt %>% 
  filter(!(customer_id %LIKE% "Z%")) %>% 
  # filter(!str_detect(customer_id, "^Z")) %>% 
  summarise(sum_amount = sum(amount), .by = customer_id) %>% 
  # mutate(.mean = mean(sum_amount)) %>% 
  # filter(sum_amount >= .mean) %>% 
  filter(sum_amount >= mean(sum_amount)) %>% 
  arrange(desc(sum_amount), customer_id) %>% 
  head(10)

db_result %>% collect()

#...............................................................................

db_result %>% show_query(cte = TRUE)

query = sql("
WITH q01 AS (
  SELECT receipt.*
  FROM receipt
  WHERE (NOT((customer_id LIKE 'Z%')))
),
q02 AS (
  SELECT customer_id, SUM(amount) AS sum_amount
  FROM q01
  GROUP BY customer_id
),
q03 AS (
  SELECT q01.*, AVG(sum_amount) OVER () AS col01
  FROM q02 q01
)
SELECT customer_id, sum_amount
FROM q03 q01
WHERE (sum_amount >= col01)
ORDER BY sum_amount DESC, customer_id
LIMIT 10
"
)
query %>% db_get_query(con)

# 改善点: 
# WITH 句の定義を1つ (customer_sales) にまとめ、不要なCTEを削減。
# 平均値の計算を WHERE 句内のサブクエリで処理し、AVG() のウィンドウ関数を不要に。
# 読みやすさと実行効率を向上。

query = sql("
WITH customer_sales AS (
  SELECT 
    customer_id, 
    SUM(amount) AS sum_amount
  FROM 
    receipt
  WHERE 
    customer_id NOT LIKE 'Z%'
  GROUP BY 
    customer_id
)
SELECT 
  customer_id, 
  sum_amount
FROM 
  customer_sales
WHERE 
  sum_amount >= (
    SELECT AVG(sum_amount) FROM customer_sales
  )
ORDER BY 
  sum_amount DESC, customer_id
LIMIT 10
"
)
query %>% db_get_query(con)

# A tibble: 10 × 2
#    customer_id    sum_amount
#    <chr>               <dbl>
#  1 CS017415000097      23086
#  2 CS015415000185      20153
#  3 CS031414000051      19202
#  4 CS028415000007      19127
#  5 CS001605000009      18925
#  6 CS010214000010      18585
#  7 CS006515000023      18372
#  8 CS016415000141      18372
#  9 CS011414000106      18338
# 10 CS038415000104      17847

#-------------------------------------------------------------------------------
# R-038 ------------
# 顧客データ（customer）とレシート明細データ（receipt）から、顧客ごとの売上金額合計を求め、10件表示せよ。
# ただし、売上実績がない顧客については売上金額を0として表示させること。
# また、顧客は性別コード（gender_cd）が女性（1）であるものを対象とし、非会員（顧客IDが"Z"から始まるもの）
# は除外すること。

# 女性会員を対象に、顧客ごとの売上合計を求める問題です。

# level: 1

# tag: 
# 集約関数, 欠損値処理, グループ化, データ結合, パターンマッチング, フィルタリング

df_customer %>% select(customer_id, gender_cd) %>% head(7)
df_customer %>% select(customer_id, gender_cd)

# `amount` が nullable (NULL を許容する) の場合の解答例を以下に示します。

df_customer %>% 
  filter(
    gender_cd == "1" & !str_detect(customer_id, "^Z")
  ) %>% 
  left_join(
    df_receipt %>% select(customer_id, amount), 
    by = "customer_id"
  ) %>% 
  summarise(
    sum_amount = sum(amount, na.rm = TRUE), 
    .by = "customer_id"
  ) %>% 
  arrange(customer_id) %>% 
  head(10)

# A tibble: 10 × 2
#    customer_id    sum_amount
#    <chr>               <dbl>
#  1 CS001112000009          0
#  2 CS001112000019          0
#  3 CS001112000021          0
#  4 CS001112000023          0
#  5 CS001112000024          0
#  6 CS001112000029          0
#  7 CS001112000030          0
#  8 CS001113000004       1298
#  9 CS001113000010          0
# 10 CS001114000005        626

#...............................................................................
# dbplyr

# amount が全て NA の場合は sum() の結果が NA となるため、次の処理を追加する。
# replace_na(list(sum_amount = 0.0))

# df_product %>% 
#   filter(is.na(unit_cost)) %>% 
#   summarise(s = sum(unit_cost, na.rm = TRUE))
# => 0

# db_product %>% 
#   filter(is.na(unit_cost)) %>% 
#   summarise(s = sum(unit_cost))
# => NA

db_result = db_customer %>% 
  filter(
    gender_cd == "1" & !(customer_id %LIKE% "%Z")
  ) %>% 
  left_join(
    db_receipt %>% select(customer_id, amount), 
    by = "customer_id"
  ) %>% 
  summarise(
    sum_amount = sum(amount, na.rm = TRUE), 
    .by = "customer_id"
  ) %>% 
  replace_na(list(sum_amount = 0.0)) %>% 
  arrange(customer_id) %>% 
  head(10)

db_result %>% collect()

#...............................................................................
db_result %>% show_query(cte = TRUE)

query = sql("
WITH q01 AS (
  SELECT customer.*
  FROM customer
  WHERE (gender_cd = '1' AND NOT((customer_id LIKE '%Z')))
),
q02 AS (
  SELECT LHS.*, amount
  FROM q01 LHS
  LEFT JOIN receipt
    ON (LHS.customer_id = receipt.customer_id)
),
q03 AS (
  SELECT customer_id, SUM(amount) AS sum_amount
  FROM q02 q01
  GROUP BY customer_id
)
SELECT customer_id, COALESCE(sum_amount, 0.0) AS sum_amount
FROM q03 q01
ORDER BY customer_id
LIMIT 10
"
)

query %>% db_get_query(con)
d1 = query %>% db_get_query(con)

# WITH 句を削除して1つのクエリに統合
# customer.* の使用を避け、必要な列 (customer_id) のみを選択
# LEFT JOIN を直接 customer テーブルに適用
# SUM(amount) の集計を GROUP BY 句内で直接実施
# COALESCE を最終的な SUM(amount) に適用

query = sql("
SELECT 
  c.customer_id, 
  COALESCE(SUM(r.amount), 0.0) AS sum_amount
FROM 
  customer c 
LEFT JOIN 
  receipt r 
USING (customer_id)
WHERE 
  c.gender_cd = '1' 
  AND customer_id NOT LIKE 'Z%' 
GROUP BY 
  c.customer_id 
ORDER BY 
  c.customer_id 
LIMIT 10
"
)
query %>% db_get_query(con)
d2 = query %>% db_get_query(con)

identical(d1, d2)

# A tibble: 10 × 2
#    customer_id    sum_amount
#    <chr>               <dbl>
#  1 CS001112000009          0
#  2 CS001112000019          0
#  3 CS001112000021          0
#  4 CS001112000023          0
#  5 CS001112000024          0
#  6 CS001112000029          0
#  7 CS001112000030          0
#  8 CS001113000004       1298
#  9 CS001113000010          0
# 10 CS001114000005        626

#-------------------------------------------------------------------------------
# R-039 ------------
# レシート明細データ（receipt）から、売上日数の多い顧客の上位20件を抽出したデータと、
# 売上金額合計の多い顧客の上位20件を抽出したデータをそれぞれ作成し、さらにその2つを完全外部結合せよ。
# ただし、非会員（顧客IDが"Z"から始まるもの）は除外すること。

# 非会員を除外し、売上日数の多い上位20名と売上金額合計の多い上位20名を抽出し、完全外部結合する問題です。

# level: 1

# tag: 
# 集約関数, データ型変換, パターンマッチング, グループ化, フィルタリング, データ結合

# sample.1

# with_ties = TRUE
# 最大値が重複している場合、その重複したすべての行を選びます。
# そのため、選ばれる行数が20件を超える可能性があります。

df_rec = df_receipt %>% 
  filter(!str_detect(customer_id, "^Z")) %>% 
  select(customer_id, sales_ymd, amount) %>% 
  group_by(customer_id)

df_date = df_rec %>% 
  summarise(n_date = n_distinct(sales_ymd)) %>% 
  slice_max(n_date, n = 20, with_ties = TRUE)

df_amount = df_rec %>% 
  summarise(sum_amount = sum(amount)) %>% 
  slice_max(sum_amount, n = 20, with_ties = TRUE)

df_result = df_date %>% 
  full_join(df_amount, by = "customer_id") %>% 
  arrange(desc(n_date), desc(sum_amount), customer_id)

df_result

# A tibble: 35 × 3
#    customer_id    n_date sum_amount
#    <chr>           <int>      <dbl>
#  1 CS040214000008     23         NA
#  2 CS015415000185     22      20153
#  3 CS010214000010     22      18585
#  4 CS028415000007     21      19127
#  5 CS010214000002     21         NA
#  6 CS017415000097     20      23086
#  7 CS016415000141     20      18372
#  8 CS031414000051     19      19202
#  9 CS014214000023     19         NA
# 10 CS021514000045     19         NA
# 11 CS021515000172     19         NA
# 12 CS022515000226     19         NA
# 13 CS039414000052     19         NA
# 14 CS007515000107     18         NA
# 15 CS014415000077     18         NA
# 16 CS021515000056     18         NA
# 17 CS021515000211     18         NA
# 18 CS022515000028     18         NA
# 19 CS030214000008     18         NA
# 20 CS031414000073     18         NA
# 21 CS032415000209     18         NA
# 22 CS001605000009     NA      18925
# ...
# 34 CS030415000034     NA      15468
# 35 CS015515000034     NA      15300

# sample.2

df_rec = df_receipt %>% 
  filter(!str_detect(customer_id, "^Z")) %>% 
  select(customer_id, sales_ymd, amount) %>% 
  group_by(customer_id)

df_date = df_rec %>% 
  summarise(n_date = n_distinct(sales_ymd)) %>% 
  arrange(desc(n_date), customer_id) %>% 
  head(20)

df_amount = df_rec %>% 
  summarise(sum_amount = sum(amount)) %>% 
  arrange(desc(sum_amount), customer_id) %>% 
  head(20)

df_result = df_date %>% 
  full_join(df_amount, by = "customer_id") %>% 
  arrange(desc(n_date), desc(sum_amount), customer_id)

df_result

#...............................................................................
# dbplyr

# sample.1

db_rec = db_receipt %>% 
  # filter(!str_detect(customer_id, "^Z")) %>% 
  filter(!(customer_id %LIKE% "Z%")) %>% 
  select(customer_id, sales_ymd, amount) %>% 
  group_by(customer_id)

db_date = db_rec %>% 
  summarise(
    n_date = n_distinct(sales_ymd) %>% as.integer()
  ) %>% 
  slice_max(n_date, n = 20, with_ties = TRUE)

db_amount = db_rec %>% 
  summarise(sum_amount = sum(amount)) %>% 
  slice_max(sum_amount, n = 20, with_ties = TRUE)

db_result = db_date %>% 
  full_join(db_amount, by = "customer_id") %>% 
  arrange(desc(n_date), desc(sum_amount), customer_id)

db_result %>% collect()

# A tibble: 35 × 3
#    customer_id    n_date sum_amount
#    <chr>           <int>      <dbl>
#  1 CS040214000008     23         NA
#  2 CS015415000185     22      20153
#  3 CS010214000010     22      18585
#  4 CS028415000007     21      19127
#  5 CS010214000002     21         NA
#  6 CS017415000097     20      23086
#  7 CS016415000141     20      18372
#  8 CS031414000051     19      19202
#  9 CS014214000023     19         NA
# 10 CS021514000045     19         NA
# 11 CS021515000172     19         NA
# 12 CS022515000226     19         NA
# 13 CS039414000052     19         NA
# 14 CS007515000107     18         NA
# 15 CS014415000077     18         NA
# 16 CS021515000056     18         NA
# 17 CS021515000211     18         NA
# 18 CS022515000028     18         NA
# 19 CS030214000008     18         NA
# 20 CS031414000073     18         NA
# 21 CS032415000209     18         NA
# 22 CS001605000009     NA      18925
# ...
# 34 CS030415000034     NA      15468
# 35 CS015515000034     NA      15300

# データフレーム操作の結果と比較
janitor::compare_df_cols(df_result, db_result %>% collect())
identical(df_result, db_result %>% collect())
all.equal(df_result, db_result %>% collect())
anti_join(df_result, db_result %>% collect())

pacman::p_load(arsenal)
d = db_result %>% collect()
arsenal::comparedf(df_result, d) %>% summary()
df_result; d

#................................................
# sample.2

db_rec = db_receipt %>% 
  filter(!(customer_id %LIKE% "Z%")) %>% 
  select(customer_id, sales_ymd, amount) %>% 
  group_by(customer_id)

db_date = db_rec %>% 
  summarise(
    n_date = n_distinct(sales_ymd) %>% as.integer()
  ) %>% 
  arrange(desc(n_date), customer_id) %>% 
  head(20)

db_amount = db_rec %>% 
  summarise(sum_amount = sum(amount)) %>% 
  arrange(desc(sum_amount), customer_id) %>% 
  head(20)

db_result = db_date %>% 
  full_join(db_amount, by = "customer_id") %>% 
  arrange(desc(n_date), desc(sum_amount), customer_id)

db_result %>% collect()

#...............................................................................

# LIMIT を使うべきケース
# 最もシンプルで高速な実装が欲しい場合
# → ORDER BY ... LIMIT 20 のほうが ROW_NUMBER() を使うよりシンプルで速い。
# TIE (同値の扱い) を考慮しなくてよい場合
# → n_date が同じ 20 人が選ばれたとき、同順位の他の人が除外されても問題ないなら LIMIT のほうが効率的。

# arrange() + head() の方が slice_max() を使うよりシンプルで速い

# sample.1

db_result %>% show_query(cte = TRUE)

# 購入日数や合計金額で、RANK() によって、同じ順位が付けられた顧客が複数いると、選ばれる顧客数が20件を超える場合があります。

query = sql("
WITH q01 AS (
  SELECT customer_id, sales_ymd, amount
  FROM receipt
  WHERE (NOT((customer_id LIKE 'Z%')))
),
q02 AS (
  SELECT customer_id, CAST(COUNT(DISTINCT row(sales_ymd)) AS INTEGER) AS n_date
  FROM q01
  GROUP BY customer_id
),
q03 AS (
  SELECT q01.*, RANK() OVER (ORDER BY n_date DESC) AS col01
  FROM q02 q01
),
q04 AS (
  SELECT customer_id, n_date
  FROM q03 q01
  WHERE (col01 <= 20)
),
q05 AS (
  SELECT customer_id, SUM(amount) AS sum_amount
  FROM q01
  GROUP BY customer_id
),
q06 AS (
  SELECT q01.*, RANK() OVER (ORDER BY sum_amount DESC) AS col02
  FROM q05 q01
),
q07 AS (
  SELECT customer_id, sum_amount
  FROM q06 q01
  WHERE (col02 <= 20)
),
q08 AS (
  SELECT
    COALESCE(LHS.customer_id, RHS.customer_id) AS customer_id,
    n_date,
    sum_amount
  FROM q04 LHS
  FULL JOIN q07 RHS
    ON (LHS.customer_id = RHS.customer_id)
)
SELECT q01.*
FROM q08 q01
ORDER BY n_date DESC, sum_amount DESC, customer_id
"
)
query %>% db_get_query(con)

query = sql("
WITH purchase_data AS (
  SELECT 
    customer_id, sales_ymd, amount
  FROM receipt
  WHERE customer_id NOT LIKE 'Z%'
),
customer_purchase_dates AS (
  SELECT 
    customer_id, 
    CAST(COUNT(DISTINCT sales_ymd) AS INTEGER) AS n_date
  FROM purchase_data
  GROUP BY customer_id
),
ranked_purchase_dates AS (
  SELECT 
    customer_id, 
    n_date, 
    RANK() OVER (ORDER BY n_date DESC) AS rank_n_date
  FROM customer_purchase_dates
),
customer_total_sales AS (
  SELECT 
    customer_id, 
    SUM(amount) AS sum_amount
  FROM purchase_data
  GROUP BY customer_id
),
ranked_total_sales AS (
  SELECT 
    customer_id, 
    sum_amount, 
    RANK() OVER (ORDER BY sum_amount DESC) AS rank_sum_amount
  FROM customer_total_sales
),
top_customers_by_dates AS (
  SELECT customer_id, n_date
  FROM ranked_purchase_dates
  WHERE rank_n_date <= 20
),
top_customers_by_sales AS (
  SELECT customer_id, sum_amount
  FROM ranked_total_sales
  WHERE rank_sum_amount <= 20
)
SELECT 
  COALESCE(d.customer_id, s.customer_id) AS customer_id,
  d.n_date,
  s.sum_amount
FROM top_customers_by_dates d
FULL JOIN top_customers_by_sales s
USING (customer_id) 
ORDER BY n_date DESC, sum_amount DESC, customer_id
"
)

query %>% db_get_query(con)

#................................................
# sample.2

db_result %>% show_query(cte = TRUE)

# WITH q01 AS (
#   SELECT customer_id, sales_ymd, amount
#   FROM receipt
#   WHERE (NOT(REGEXP_MATCHES(customer_id, '^Z')))
# ),
# q02 AS (
#   SELECT customer_id, CAST(COUNT(DISTINCT row(sales_ymd)) AS INTEGER) AS n_date
#   FROM q01
#   GROUP BY customer_id
#   ORDER BY n_date DESC, customer_id
#   LIMIT 20
# ),
# q03 AS (
#   SELECT customer_id, SUM(amount) AS sum_amount
#   FROM q01
#   GROUP BY customer_id
#   ORDER BY sum_amount DESC, customer_id
#   LIMIT 20
# ),
# q04 AS (
#   SELECT
#     COALESCE(LHS.customer_id, RHS.customer_id) AS customer_id,
#     n_date,
#     sum_amount
#   FROM q02 LHS
#   FULL JOIN q03 RHS
#     ON (LHS.customer_id = RHS.customer_id)
# )
# SELECT q01.*
# FROM q04 q01
# ORDER BY n_date DESC, sum_amount DESC, customer_id

query = sql("
WITH purchase_data AS (
  SELECT 
    customer_id, 
    sales_ymd, 
    amount 
  FROM 
    receipt 
  WHERE 
    customer_id NOT LIKE 'Z%'
), 
top_customers_by_dates AS (
  SELECT 
    customer_id, 
    CAST(COUNT(DISTINCT sales_ymd) AS INTEGER) AS n_date 
  FROM 
    purchase_data 
  GROUP BY 
    customer_id 
  ORDER BY 
    n_date DESC, customer_id 
  LIMIT 20
), 
top_customers_by_sales AS (
  SELECT 
    customer_id, 
    SUM(amount) AS sum_amount 
  FROM 
    purchase_data 
  GROUP BY 
    customer_id 
  ORDER BY 
    sum_amount DESC, customer_id 
  LIMIT 20
) 
SELECT 
  COALESCE(d.customer_id, s.customer_id) AS customer_id, 
  d.n_date, 
  s.sum_amount 
FROM 
  top_customers_by_dates d
FULL JOIN 
  top_customers_by_sales s 
USING (customer_id) 
ORDER BY 
  n_date DESC, sum_amount DESC, customer_id
"
)

query %>% db_get_query(con)

# A tibble: 34 × 3
#    customer_id    n_date sum_amount
#    <chr>           <int>      <dbl>
#  1 CS040214000008     23         NA
#  2 CS015415000185     22      20153
#  3 CS010214000010     22      18585
#  4 CS028415000007     21      19127
#  5 CS010214000002     21         NA
#  6 CS017415000097     20      23086
#  7 CS016415000141     20      18372
# ...
# 33 CS030415000034     NA      15468
# 34 CS015515000034     NA      15300

#-------------------------------------------------------------------------------
# R-040 ------------
# 全ての店舗と全ての商品を組み合わせたデータを作成したい。店舗データ（store）と商品データ（product）を直積し、件数を計算せよ。

# 店舗と商品の組み合わせデータの作成
# 店舗データと商品データの直積を作成し、件数を求める問題です。

# level: 1

# tag: 
# 集約関数, 全組み合わせ, データ結合

# sample.1
df_store %>% 
  cross_join(df_product) %>% 
  count()

# sample.2

df_store %>% 
  tidyr::crossing(df_product) %>% 
  count()

# A tibble: 531,590 × 2
#    store_cd product_cd
#    <chr>    <chr>     
#  1 S12014   P040101001
#  2 S12014   P040101002
#  3 S12014   P040101003
#  4 S12014   P040101004
#  5 S12014   P040101005
#  6 S12014   P040101006
#  7 S12014   P040101007
#  8 S12014   P040101008
#  9 S12014   P040101009
# 10 S12014   P040101010
# 11 S12014   P040102001
# 12 S12014   P040102002
# 13 S12014   P040102003
# ...

#...............................................................................
# dbplyr

db_result = db_store %>% 
  cross_join(db_product) %>% 
  count()

db_result %>% collect()

#...............................................................................

db_result %>% show_query()

query = sql("
SELECT 
  COUNT(*) AS n
FROM 
  store 
CROSS JOIN 
  product
"
)

query %>% db_get_query(con)

# A tibble: 531,590 × 2
#    store_cd product_cd
#    <chr>    <chr>     
#  1 S12014   P040101001
#  2 S12014   P040101002
#  3 S12014   P040101003
#  4 S12014   P040101004
#  5 S12014   P040101005
#  6 S12014   P040101006
#  7 S12014   P040101007
#  8 S12014   P040101008
#  9 S12014   P040101009
# 10 S12014   P040101010
# 11 S12014   P040102001
# 12 S12014   P040102002
# 13 S12014   P040102003
# ...

db_result %>% count() %>% show_query()

query = sql("
SELECT 
  COUNT(*) AS count
FROM 
  store
CROSS JOIN 
  product
"
)

query %>% db_get_query(con)

#    count
#    <dbl>
# 1 531590

#-------------------------------------------------------------------------------
# R-041 ------------
# レシート明細データ（receipt）の売上金額（amount）を日付（sales_ymd）ごとに集計し、
# 前回売上があった日からの売上金額増減を計算せよ。そして結果を10件表示せよ。

# 日別売上金額の集計と増減計算
# 売上金額を日別に集計し、前回売上日からの増減を計算する問題です。

# level: 2

# tag: 
# シフト関数, 集約関数, ウィンドウ関数, 欠損値処理, グループ化

# 参考
df_receipt %>% 
  summarise(amount = sum(amount), .by = sales_ymd) %>% 
  filter(amount > 0.0) %>% 
  mutate(
    pre_sales_ymd = lag(sales_ymd, order_by = sales_ymd), 
    pre_amount = lag(amount, order_by = sales_ymd)
  ) %>% 
  mutate(diff_amount = amount - pre_amount) %>% 
  arrange(sales_ymd) %>% 
  head(10)

# ブログでは以下を採用
df_receipt %>% 
  summarise(
    amount = sum(amount, na.rm = TRUE), .by = sales_ymd
  ) %>% 
  filter(amount > 0.0) %>% 
  arrange(sales_ymd) %>% 
  mutate(
    pre_sales_ymd = lag(sales_ymd), 
    pre_amount = lag(amount), 
    diff_amount = amount - pre_amount
  ) %>% 
  head(10)

# A tibble: 1,034 × 5
#    sales_ymd amount pre_sales_ymd pre_amount diff_amount
#        <int>  <dbl>         <int>      <dbl>       <dbl>
#  1  20170101  33723            NA         NA          NA
#  2  20170102  24165      20170101      33723       -9558
#  3  20170103  27503      20170102      24165        3338
#  4  20170104  36165      20170103      27503        8662
#  5  20170105  37830      20170104      36165        1665
#  6  20170106  32387      20170105      37830       -5443
#  7  20170107  23415      20170106      32387       -8972
#  ...

#...............................................................................
# dbplyr
# arrange(sales_ymd) を window_order(sales_ymd) に変更する
# 最後に arrange(sales_ymd) 
# replace_na(list(amount = 0.0)) を追記

# filter(!is.na(amount)) に変更。

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

#...............................................................................

db_result %>% show_query(cte = TRUE)

query = sql("
WITH sales_by_date AS (
  SELECT 
    sales_ymd, 
    SUM(amount) AS amount
  FROM 
    receipt
  GROUP BY 
    sales_ymd
  HAVING 
    SUM(amount) IS NOT NULL
),
sales_by_date_with_lag AS (
  SELECT 
    sales_ymd, 
    amount, 
    LAG(sales_ymd) OVER win AS pre_sales_ymd,
    LAG(amount) OVER win AS pre_amount
  FROM 
    sales_by_date
  WINDOW win AS (ORDER BY sales_ymd)
)
SELECT 
  sales_ymd, 
  amount, 
  pre_sales_ymd, 
  pre_amount, 
  amount - pre_amount AS diff_amount
FROM 
  sales_by_date_with_lag
ORDER BY 
  sales_ymd
LIMIT 10
"
)

query %>% db_get_query(con)

# A tibble: 1,034 × 5
#    sales_ymd sum_amount pre_ymd  pre_amount diff_amount
#    <chr>          <dbl> <chr>         <dbl>       <dbl>
#  1 20170101       33723 NA               NA          NA
#  2 20170102       24165 20170101      33723       -9558
#  3 20170103       27503 20170102      24165        3338
#  4 20170104       36165 20170103      27503        8662
#  5 20170105       37830 20170104      36165        1665
#  6 20170106       32387 20170105      37830       -5443
#  ...

#-------------------------------------------------------------------------------
# R-042 ------------
# レシート明細データ（receipt）の売上金額（amount）を日付（sales_ymd）ごとに集計し、
# 各日付のデータに対し、前回、前々回、3 回前に売上があった日のデータを結合せよ。そして結果を10件表示せよ。

# 日別売上金額の集計と過去売上データの結合
# 売上金額を日別に集計し、各日付に対し、前回・前々回・3 回前の売上データを結合する問題です。

# level: 4

# tag: 
# 集約関数, シフト関数, ウィンドウ関数, 欠損値処理, グループ化, 自己結合

n_lag = 3L

df_sales_with_lag = df_receipt %>% 
  summarise(
    amount = sum(amount, na.rm = TRUE), .by = "sales_ymd"
  ) %>% 
  filter(amount > 0.0) %>% 
  arrange(sales_ymd) %>% 
  mutate(
    lag_ymd = lag(sales_ymd, n = n_lag, default = -1L)
  )

# df_sales_with_lag
df_sales_with_lag %>% tail(3L)

.by = join_by(
    between(y$sales_ymd, x$lag_ymd, x$sales_ymd, bounds = "[)")
  )

df_result = df_sales_with_lag %>% 
  inner_join(
    df_sales_with_lag, by = .by, suffix = c("", ".y")
  ) %>% 
  select(
    sales_ymd, amount, lag_sales_ymd = sales_ymd.y, lag_amount = amount.y
  ) %>% 
  arrange(sales_ymd, lag_sales_ymd)

df_result %>% head(10)
df_result %>% tail(6)

# A tibble: 3,096 × 4
#    sales_ymd amount  lag_ymd lag_amount
#        <int>  <dbl>    <int>      <dbl>
#  1  20170102  24165 20170101      33723
#  2  20170103  27503 20170101      33723
#  3  20170103  27503 20170102      24165
#  4  20170104  36165 20170101      33723
#  5  20170104  36165 20170102      24165
#  6  20170104  36165 20170103      27503
#  7  20170105  37830 20170102      24165
#  8  20170105  37830 20170103      27503
#  9  20170105  37830 20170104      36165
# ...
# 1  20191029  36091 20191028      40161
# 2  20191030  26602 20191027      37484
# 3  20191030  26602 20191028      40161
# 4  20191030  26602 20191029      36091
# 5  20191031  25216 20191028      40161
# 6  20191031  25216 20191029      36091
# 7  20191031  25216 20191030      26602

#...............................................................................
# dbplyr

n_lag = 3L

db_sales_with_lag = db_receipt %>% 
  summarise(
    amount = sum(amount), .by = "sales_ymd"
  ) %>% 
  filter(!is.na(amount)) %>% 
  # arrange(sales_ymd) %>% 
  window_order(sales_ymd) %>% 
  mutate(
    lag_ymd = lag(sales_ymd, n = n_lag, default = -1L)
  )

# db_sales_with_lag

.by = join_by(
    between(y$sales_ymd, x$lag_ymd, x$sales_ymd, bounds = "[)")
  )

db_result = db_sales_with_lag %>% 
  inner_join(
    db_sales_with_lag, by = .by, suffix = c("", ".y")
  ) %>% 
  select(
    sales_ymd, amount, lag_sales_ymd = sales_ymd.y, lag_amount = amount.y
  ) %>% 
  arrange(sales_ymd, lag_sales_ymd)

db_result %>% collect() %>% head(10)
db_result %>% collect() %>% tail(7)

#...............................................................................

db_result %>% show_query(cte = TRUE)

query = sql("
WITH q01 AS (
  SELECT sales_ymd, SUM(amount) AS amount
  FROM receipt
  GROUP BY sales_ymd
  HAVING (NOT(((SUM(amount)) IS NULL)))
),
q02 AS (
  SELECT q01.*, LAG(sales_ymd, 3, -1) OVER (ORDER BY sales_ymd) AS lag_ymd
  FROM q01
),
q03 AS (
  SELECT q01.*, LAG(sales_ymd, 3, -1) OVER (ORDER BY sales_ymd) AS lag_ymd
  FROM q01
),
q04 AS (
  SELECT
    LHS.sales_ymd AS sales_ymd,
    LHS.amount AS amount,
    RHS.sales_ymd AS lag_sales_ymd,
    RHS.amount AS lag_amount
  FROM q02 LHS
  INNER JOIN q03 RHS
    ON (LHS.lag_ymd <= RHS.sales_ymd AND LHS.sales_ymd > RHS.sales_ymd)
)
SELECT q01.*
FROM q04 q01
ORDER BY sales_ymd, lag_sales_ymd
"
)

query %>% db_get_query(con)
query %>% db_get_query(con) %>% tail(7)

query = sql("
WITH sales_data AS (
  SELECT 
    sales_ymd, 
    SUM(amount) AS amount,
    LAG(sales_ymd, 3, -1) OVER (ORDER BY sales_ymd) AS lag_ymd
  FROM 
    receipt
  GROUP BY 
    sales_ymd
  HAVING 
    SUM(amount) IS NOT NULL
)
SELECT 
  L.sales_ymd,
  L.amount,
  R.sales_ymd AS lag_sales_ymd,
  R.amount AS lag_amount
FROM 
  sales_data L
INNER JOIN 
  sales_data R
ON (
  L.lag_ymd <= R.sales_ymd 
  AND L.sales_ymd > R.sales_ymd
)
ORDER BY 
  L.sales_ymd, R.sales_ymd
"
)

query %>% db_get_query(con) %>% head(10)
query %>% db_get_query(con) %>% tail(7)

query = sql("
  SELECT 
    sales_ymd, 
    SUM(amount) AS amount,
    LAG(sales_ymd, 3, -1) OVER (ORDER BY sales_ymd) AS lag_ymd
  FROM 
    receipt
  GROUP BY 
    sales_ymd
  HAVING 
    SUM(amount) IS NOT NULL
"
)
query %>% db_get_query(con)


# A tibble: 3,096 × 4
#    sales_ymd amount lag_sales_ymd lag_amount
#        <int>  <dbl>         <int>      <dbl>
#  1  20170102  24165      20170101      33723
#  2  20170103  27503      20170101      33723
#  3  20170103  27503      20170102      24165
#  4  20170104  36165      20170101      33723
#  5  20170104  36165      20170102      24165
#  6  20170104  36165      20170103      27503
#  7  20170105  37830      20170102      24165
#  8  20170105  37830      20170103      27503
#  9  20170105  37830      20170104      36165
# ...
# 1  20191029  36091      20191028      40161
# 2  20191030  26602      20191027      37484
# 3  20191030  26602      20191028      40161
# 4  20191030  26602      20191029      36091
# 5  20191031  25216      20191028      40161
# 6  20191031  25216      20191029      36091
# 7  20191031  25216      20191030      26602

#-------------------------------------------------------------------------------
# R-043 ------------
# レシート明細データ（receipt）と顧客データ（customer）を結合し、性別コード（gender_cd）と
# 年代（ageから計算）ごとに売上金額（amount）を合計した売上サマリデータを作成せよ。
# 性別コードは0が男性、1が女性、9が不明を表すものとする。
# ただし、項目構成は年代、女性の売上金額、男性の売上金額、性別不明の売上金額の4項目とすること
# （縦に年代、横に性別のクロス集計）。また、年代は10歳ごとの階級とすること。

# 性別・年代別売上金額のクロス集計
# レシート明細データと顧客データを結合し、10歳ごとの年代ごとに、性別別の売上金額を集計する問題です。

# level: 3

# tag: 
# カテゴリ変換, CASE式, データ型変換, 集約関数, 縦横変換, グループ化, データ結合

max_age = df_customer$age %>% max(na.rm = TRUE)

df_sales = df_customer %>% 
  inner_join(
    df_receipt, by = "customer_id"
  ) %>% 
  mutate(
    age_range = 
      epikit::age_categories(
        age, 
        lower = 0, 
        # upper = round(max_age, -1) - if_else(mod(max_age, 10) == 0, 0L, 1L), 
        upper = floor(!!max_age / 10) * 10 + 10, 
        by = 10
      )
  ) %>% 
  summarise(
    sum_amount = sum(amount), 
    .by = c("gender_cd", "age_range")
  ) %>% 
  mutate(
    across(
      gender_cd, 
      ~ forcats::lvls_revalue(.x, c("male", "female", "unknown"))
    )
  )

df_sales
# A tibble: 25 × 3
#    gender_cd age_range sum_amount
#    <fct>     <fct>          <dbl>
#  1 female    40-49        9320791
#  2 female    20-29        1363724
#  3 female    50-59        6685192
#  4 female    30-39         693047
#  5 unknown   40-49         483512
#  6 unknown   30-39          50441
#  7 unknown   20-29          44328
#  8 male      60-69         272469
# ...
# 25 unknown   10-19           4317

# for test
# df_sales %<>% filter(age_range != "20-29")
# df_sales$age_range

# 横長
df_sales %>% 
  pivot_wider(
    id_cols = age_range, 
    id_expand = TRUE, 
    names_from = gender_cd, 
    values_from = sum_amount, 
    names_expand = TRUE, 
    values_fill = 0.0
  )

# A tibble: 11 × 4
#    age_range   male  female unknown
#    <fct>      <dbl>   <dbl>   <dbl>
#  1 0-9            0       0       0
#  2 10-19       1591  149836    4317
#  3 20-29      72940 1363724   44328
#  4 30-39     177322  693047   50441
#  5 40-49      19355 9320791  483512
#  6 50-59      54320 6685192  342923
#  7 60-69     272469  987741   71418
#  8 70-79      13435   29764    2427
#  9 80-89      46360  262923    5111
# 10 90-99          0    6260       0
# 11 100+           0       0       0

# 縦長
df_sales %>% tidyr::complete(
    age_range, gender_cd, fill = list(sum_amount = 0.0)
  )

# A tibble: 33 × 3
#    age_range gender_cd sum_amount
#    <fct>     <fct>          <dbl>
#  1 0-9       male               0
#  2 0-9       female             0
#  3 0-9       unknown            0
#  4 10-19     male            1591
#  5 10-19     female        149836
#  6 10-19     unknown         4317
#  7 20-29     male           72940
#  8 20-29     female       1363724
#  9 20-29     unknown        44328
# 10 30-39     male          177322
# 11 30-39     female        693047
# 12 30-39     unknown        50441
# 13 40-49     male           19355
# 14 40-49     female       9320791
# 15 40-49     unknown       483512
# 16 50-59     male           54320
# 17 50-59     female       6685192
# 18 50-59     unknown       342923
# 19 60-69     male          272469
# 20 60-69     female        987741
# 21 60-69     unknown        71418
# 22 70-79     male           13435
# 23 70-79     female         29764
# 24 70-79     unknown         2427
# 25 80-89     male           46360
# 26 80-89     female        262923
# 27 80-89     unknown         5111
# 28 90-99     male               0
# 29 90-99     female          6260
# 30 90-99     unknown            0
# 31 100+      male               0
# 32 100+      female             0
# 33 100+      unknown            0

#...............................................................................
# dbplyr

# sample.1
db_result = db_customer %>% 
  inner_join(
    db_receipt %>% select(customer_id, amount), 
    by = "customer_id"
  ) %>% 
  mutate(
    age_range = 
      (floor(age / 10) * 10) %>% as.integer()
  ) %>% 
  summarise(
    sum_amount = sum(amount), 
    .by = c("gender_cd", "age_range")
  ) %>% 
  pivot_wider(
    id_cols = age_range, 
    names_from = gender_cd, 
    values_from = sum_amount, 
    names_sort = TRUE, 
    values_fill = 0.0
  ) %>% 
  rename(
    male = "0", female = "1", unknown = "9"
  ) %>% 
  arrange(age_range)

db_result %>% collect()

# A tibble: 9 × 4
#   age_range   male  female unknown
#       <int>  <dbl>   <dbl>   <dbl>
# 1        10   1591  149836    4317
# 2        20  72940 1363724   44328
# 3        30 177322  693047   50441
# 4        40  19355 9320791  483512
# 5        50  54320 6685192  342923
# 6        60 272469  987741   71418
# 7        70  13435   29764    2427
# 8        80  46360  262923    5111
# 9        90      0    6260       0

# sample.2
db_result = db_customer %>% 
  inner_join(
    db_receipt %>% select(customer_id, amount), 
    by = "customer_id"
  ) %>%
  mutate(
    age_range = (floor(age / 10) * 10) %>% as.integer()
  ) %>%
  summarise(
    male = sum(if_else(gender_cd == "0", amount, 0.0)),
    female = sum(if_else(gender_cd == "1", amount, 0.0)),
    unknown = sum(if_else(gender_cd == "9", amount, 0.0)), 
    .by = age_range
  ) %>%
  arrange(age_range)

db_result %>% collect()

#...............................................................................

db_result %>% show_query(cte = TRUE)

query = sql("
SELECT
  CAST(FLOOR(c.age / 10.0) * 10.0 AS INTEGER) AS age_range,
  SUM(CASE WHEN c.gender_cd = '0' THEN r.amount ELSE 0 END) AS male,
  SUM(CASE WHEN c.gender_cd = '1' THEN r.amount ELSE 0 END) AS female,
  SUM(CASE WHEN c.gender_cd = '9' THEN r.amount ELSE 0 END) AS \"unknown\"
FROM 
  customer c
INNER JOIN 
  receipt r 
USING (customer_id)
GROUP BY 
  age_range
ORDER BY 
  age_range
"
)

# r"( )" という raw string リテラルを使用しています。

q = r"(
SELECT
  CAST(FLOOR(c.age / 10.0) * 10.0 AS INTEGER) AS age_range,
  SUM(CASE WHEN c.gender_cd = '0' THEN r.amount ELSE 0 END) AS male,
  SUM(CASE WHEN c.gender_cd = '1' THEN r.amount ELSE 0 END) AS female,
  SUM(CASE WHEN c.gender_cd = '9' THEN r.amount ELSE 0 END) AS "unknown"
FROM 
  customer c
INNER JOIN 
  receipt r 
USING (customer_id)
GROUP BY 
  age_range
ORDER BY 
  age_range
)"

query %>% db_get_query(con)

# A tibble: 9 × 4
#   age_range   male  female unknown
#       <int>  <dbl>   <dbl>   <dbl>
# 1        10   1591  149836    4317
# 2        20  72940 1363724   44328
# 3        30 177322  693047   50441
# 4        40  19355 9320791  483512
# 5        50  54320 6685192  342923
# 6        60 272469  987741   71418
# 7        70  13435   29764    2427
# 8        80  46360  262923    5111
# 9        90      0    6260       0

#-------------------------------------------------------------------------------
# R-044 ------------
# 043で作成した売上サマリデータ（sales_summary）は性別の売上を横持ちさせたものであった。
# このデータから性別を縦持ちさせ、年代、性別コード、売上金額の3項目に変換せよ。
# ただし、性別コードは男性を"00"、女性を"01"、不明を"99"とする。

# 性別・年代別売上金額の集計
# R-043で作成した売上サマリデータの性別を縦持ちに変換する問題です。

# level: 3

# tag: 
# カテゴリ変換, CASE式, データ型変換, 集約関数, 全組み合わせ, グループ化, データ結合

# ここでは、元のデータから縦持ちさせ、年代、性別コード、売上金額の3項目に変換する解答例を紹介します。

max_age = df_customer$age %>% max(na.rm = TRUE)

df_sales = df_customer %>% 
  inner_join(
    df_receipt, by = "customer_id"
  ) %>% 
  mutate(
    age_range = 
      epikit::age_categories(
        age, 
        lower = 0, 
        upper = floor(max_age / 10) * 10 + 10, 
        by = 10
      )
  ) %>% 
  summarise(
    sum_amount = sum(amount), 
    .by = c("gender_cd", "age_range")
  ) %>% 
  mutate(
    across(
      gender_cd, 
      ~ forcats::lvls_revalue(.x, c("00", "01", "99"))
    )
  )

# 縦長
df_sales %>% 
  tidyr::complete(
    age_range, gender_cd, 
    fill = list(sum_amount = 0.0)
  ) %>% 
  arrange(gender_cd, age_range)

# A tibble: 33 × 3
#    age_range gender_cd sum_amount
#    <fct>     <fct>          <dbl>
#  1 0-9       00                 0
#  2 10-19     00              1591
#  3 20-29     00             72940
#  4 30-39     00            177322
#  5 40-49     00             19355
#  6 50-59     00             54320
#  7 60-69     00            272469
#  8 70-79     00             13435
#  9 80-89     00             46360
# 10 90-99     00                 0
# 11 100+      00                 0
# 12 0-9       01                 0
# 13 10-19     01            149836
# 14 20-29     01           1363724
# 15 30-39     01            693047
# 16 40-49     01           9320791
# 17 50-59     01           6685192
# 18 60-69     01            987741
# 19 70-79     01             29764
# 20 80-89     01            262923
# 21 90-99     01              6260
# 22 100+      01                 0
# 23 0-9       99                 0
# 24 10-19     99              4317
# 25 20-29     99             44328
# 26 30-39     99             50441
# 27 40-49     99            483512
# 28 50-59     99            342923
# 29 60-69     99             71418
# 30 70-79     99              2427
# 31 80-89     99              5111
# 32 90-99     99                 0
# 33 100+      99                 0

#...............................................................................

db_sales = db_customer %>% 
  inner_join(
    db_receipt %>% select(customer_id, amount), 
    by = "customer_id"
  ) %>% 
  mutate(
    age_range = 
      (floor(age / 10) * 10) %>% as.integer()
  ) %>% 
  summarise(
    sum_amount = sum(amount), 
    .by = c("gender_cd", "age_range")
  ) %>% 
  mutate(
    gender_cd = case_match(
      gender_cd, 
      "0" ~ "00", 
      "1" ~ "01", 
      .default = "99"
    )
  )

db_sales %>% collect()

db_result = db_sales %>% 
  tidyr::complete(
    age_range, gender_cd, 
    fill = list(sum_amount = 0.0)
  ) %>% 
  arrange(gender_cd, age_range)

db_result %>% collect()

#...............................................................................

db_result %>% show_query(cte = TRUE)

query = sql("
WITH joined_data AS (
  SELECT
    c.customer_id,
    CAST((FLOOR(age / 10.0) * 10.0) AS INTEGER) AS age_range, 
    CASE c.gender_cd 
      WHEN '0' THEN '00'
      WHEN '1' THEN '01'
      ELSE '99' 
    END AS gender_cd,
    r.amount
  FROM 
    customer c
  INNER JOIN 
    receipt r 
  USING(customer_id)
),
all_combinations AS (
  SELECT 
    jd.age_range, g.gender_cd 
  FROM 
    (SELECT DISTINCT age_range FROM joined_data) AS jd
  CROSS JOIN 
    (VALUES ('00'), ('01'), ('99')) AS g(gender_cd)
),
sales_summary AS (
  SELECT 
    gender_cd, 
    age_range, 
    SUM(amount) AS sum_amount
  FROM 
    joined_data
  GROUP BY 
    gender_cd, age_range
)
SELECT 
  ac.age_range,
  ac.gender_cd,
  COALESCE(ss.sum_amount, 0.0) AS sum_amount
FROM 
  all_combinations ac
LEFT JOIN 
  sales_summary ss
USING   
  (age_range, gender_cd)
ORDER BY 
  ac.gender_cd, ac.age_range
"
)

query %>% db_get_query(con)

# A tibble: 27 × 3
#    age_range gender_cd sum_amount
#        <int> <chr>          <dbl>
#  1        10 00              1591
#  2        20 00             72940
#  3        30 00            177322
#  4        40 00             19355
#  5        50 00             54320
#  6        60 00            272469
#  7        70 00             13435
#  8        80 00             46360
#  9        90 00                 0
# 10        10 01            149836
# 11        20 01           1363724
# 12        30 01            693047
# 13        40 01           9320791
# 14        50 01           6685192
# 15        60 01            987741
# 16        70 01             29764
# 17        80 01            262923
# 18        90 01              6260
# 19        10 99              4317
# 20        20 99             44328
# 21        30 99             50441
# 22        40 99            483512
# 23        50 99            342923
# 24        60 99             71418
# 25        70 99              2427
# 26        80 99              5111
# 27        90 99                 0

#-------------------------------------------------------------------------------
# R-045 ------------
# 顧客データ（df_customer）の生年月日（birth_day）は日付型でデータを保有している。
# これをYYYYMMDD形式の文字列に変換し、顧客ID（customer_id）とともに10件表示せよ。

# 日付型を文字列に変換
# 顧客の生年月日をYYYYMMDD形式の文字列に変換する問題です。

# level: 1

# tag: 
# 日付処理, データ型変換

"2025-02-21" %>% as.Date() %>% strftime("%Y%m%d")
df_customer$birth_day %>% class()

df_customer %>% 
  mutate(birth_day = strftime(birth_day, "%Y%m%d")) %>% 
  select(customer_id, birth_day) %>% 
  head(10)

# A tibble: 10 × 2
#    customer_id    birth_day
#    <chr>          <chr>    
#  1 CS021313000114 19810429 
#  2 CS037613000071 19520401 
#  3 CS031415000172 19761004 
#  4 CS028811000001 19330327 
#  5 CS001215000145 19950329 
#  6 CS020401000016 19740915 
#  7 CS015414000103 19770809 
#  8 CS029403000008 19730817 
#  9 CS015804000004 19310502 
# 10 CS033513000180 19620711 

#...............................................................................

# dplyr が認識できない関数をエラーにする
options(dplyr.strict_sql = FALSE)

db_result = db_customer %>% 
  mutate(birth_day = STRFTIME(birth_day, "%Y%m%d")) %>% 
  select(customer_id, birth_day) %>% 
  head(10)

db_result %>% collect()

#...............................................................................

db_result %>% show_query()

query = sql("
SELECT 
  customer_id, 
  STRFTIME(birth_day, '%Y%m%d') AS birth_day
FROM 
  customer
LIMIT 10
"
)

query %>% db_get_query(con)

#-------------------------------------------------------------------------------
# R-047 ------------
# レシート明細データ（df_receipt）の売上日（sales_ymd）はYYYYMMDD形式の数値型でデータを保有している。
# これを日付型に変換し、レシート番号(receipt_no)、レシートサブ番号（receipt_sub_no）とともに10件表示せよ。

# 売上日を日付型に変換
# 売上日を日付型に変換し、レシート番号・レシートサブ番号とともに表示する問題です。

# level: 1

# tag: 
# 日付処理, データ型変換

"20251223" %>% lubridate::fast_strptime("%Y%m%d") %>% class()
# [1] "POSIXlt" "POSIXt" 
"20251223" %>% lubridate::fast_strptime("%Y%m%d") %>% 
      lubridate::as_date() %>% class()
# [1] "Date"

df_receipt %>% 
  select(receipt_no, receipt_sub_no, sales_ymd) %>% 
  mutate(
    sales_ymd = sales_ymd %>% 
      as.character() %>% 
      lubridate::fast_strptime("%Y%m%d") %>% 
      lubridate::as_date()
  ) %>% 
  head(10)

# A tibble: 104,681 × 3
#    receipt_no receipt_sub_no sales_ymd 
#         <int>          <int> <date>    
#  1        112              1 2018-11-03
#  2       1132              2 2018-11-18
#  3       1102              1 2017-07-12
#  4       1132              1 2019-02-05
#  5       1102              2 2018-08-21
#  6       1112              1 2019-06-05
#  ...

#...............................................................................

# dplyr が認識できない関数をエラーにする 
options(dplyr.strict_sql = FALSE)

db_result = db_receipt %>% 
  select(receipt_no, receipt_sub_no, sales_ymd) %>% 
  mutate(
    sales_ymd = sales_ymd %>% 
      as.character() %>% STRPTIME("%Y%m%d") %>% lubridate::as_date()
      # sales_ymd %>% as.character() %>% strptime("%Y%m%d")
      # sales_ymd %>% as.character() %>% lubridate::fast_strptime("%Y%m%d")
      # sales_ymd %>% as.character() %>% lubridate::parse_date_time("%Y%m%d")
      # sales_ymd %>% as.character() %>% lubridate::as_date()
  ) %>% 
  head(10)

db_result = db_receipt %>% 
  select(receipt_no, receipt_sub_no, sales_ymd) %>% 
  mutate(
    sales_ymd = sales_ymd %>% 
      as.character() %>% 
      STRPTIME("%Y%m%d") %>% 
      lubridate::as_date()
  ) %>% 
  head(10)

db_result %>% collect()

#...............................................................................

db_result %>% show_query()

query = sql("
SELECT
  receipt_no,
  receipt_sub_no,
  STRPTIME(
    CAST(sales_ymd AS TEXT), '%Y%m%d'
  ) AS sales_ymd
FROM 
  receipt
LIMIT 10
"
)
query %>% db_get_query(con)

#    receipt_no receipt_sub_no sales_ymd          
#         <int>          <int> <dttm>             
#  1        112              1 2018-11-03 00:00:00
#  ...

query = sql("
SELECT
  receipt_no,
  receipt_sub_no,
  CAST(
    STRPTIME(
      CAST(sales_ymd AS TEXT), '%Y%m%d'
    ) AS DATE
  ) AS sales_ymd
FROM 
  receipt
LIMIT 10
"
)

query %>% db_get_query(con)

#-------------------------------------------------------------------------------
# R-048 ------------
# レシート明細データ（df_receipt）の売上エポック秒（sales_epoch）は数値型の UNIX 秒でデータを保有している。
# これを日付型に変換し、レシート番号(receipt_no)、レシートサブ番号（receipt_sub_no）とともに10件表示せよ。

# ブログには掲載しない

df_receipt %>% 
  mutate(
    sales_date = 
      lubridate::as_datetime(sales_epoch) %>% 
      lubridate::as_date()
  ) %>% 
  select(receipt_no, receipt_sub_no, sales_date)

#...............................................................................

db_result = db_receipt %>% 
  mutate(
    sales_date = 
      sql("TO_TIMESTAMP(sales_epoch) :: TIMESTAMP") %>% 
      as_date()
  ) %>% 
  select(receipt_no, receipt_sub_no, sales_date)

db_result %>% collect()

# TIMESTAMP:	タイムゾーンなしの日時型	'2024-02-13 12:34:56'
# TIMESTAMP:  WITH TIME ZONE	タイムゾーン情報を含む日時型	'2024-02-13 12:34:56 UTC'

db_receipt %>% 
  mutate(
    sales_date = lubridate::as_datetime(sales_epoch)
  ) %>% 
  select(receipt_no, receipt_sub_no, sales_date)

# Error in `collect()`:
# ! Failed to collect lazy table.
# Caused by error in `duckdb_result()`:
# ! rapi_execute: Failed to run query
# Error: Conversion Error: Unimplemented type for cast (INTEGER -> TIMESTAMP)
# LINE 6:   CAST(sales_epoch AS TIMESTAMP) AS sales_ymd_d
# FROM receipt

1541203200L %>% as.POSIXct(format = "%Y-%m-%d")
1541203200L %>% as.POSIXct(origin = "1970-01-01")

db_receipt %>% 
  mutate(
    sales_date = as.POSIXct(sales_epoch, origin = "1970-01-01") %>% as.Date()
  ) %>% 
  select(receipt_no, receipt_sub_no, sales_date)

# as.POSIXct(sales_epoch, origin = "1970-01-01") でエラー: 
#   使われていない引数 (origin = "1970-01-01")

#...............................................................................

db_result %>% show_query(cte = TRUE)

query = sql("
SELECT
  receipt_no,
  receipt_sub_no,
  CAST(TO_TIMESTAMP(sales_epoch) :: TIMESTAMP AS DATE) AS sales_date
FROM receipt
"
)
query %>% db_get_query(con)

query = sql("
SELECT
  receipt_no,
  receipt_sub_no,
  TO_TIMESTAMP(sales_epoch) AS sales_date
FROM receipt
"
)
query %>% db_get_query(con)

#-------------------------------------------------------------------------------
# R-049 ------------
# レシート明細データ（df_receipt）の売上エポック秒（sales_epoch）を日付型に変換し、「年」だけ取り出してレシート番号(receipt_no)、レシートサブ番号（receipt_sub_no）とともに10件表示せよ。

# ブログには掲載しない

df_receipt %>% 
  mutate(
    year = 
      lubridate::as_datetime(sales_epoch) %>% 
      lubridate::year() %>% 
      as.integer()
  ) %>% 
  select(receipt_no, receipt_sub_no, year)

# A tibble: 104,681 × 3
#    receipt_no receipt_sub_no  year
#         <int>          <int> <int>
#  1        112              1  2018
#  2       1132              2  2018
#  3       1102              1  2017
#  4       1132              1  2019
#  5       1102              2  2018
#  6       1112              1  2019
#  7       1102              2  2018
#  8       1102              1  2019
#  9       1112              2  2017
# 10       1102              1  2019

#...............................................................................
# 推奨
db_result = db_receipt %>% 
  mutate(
    sales_ymd = sql("TO_TIMESTAMP(sales_epoch) :: TIMESTAMP"), 
    year = sales_ymd %>% lubridate::year() %>% as.integer()
  ) %>% 
  select(receipt_no, receipt_sub_no, year)

db_result %>% collect()

# 非推奨
db_receipt %>% 
  select(receipt_no, receipt_sub_no, sales_epoch) %>% 
  mutate(
    ymd = sql("YEAR(TO_TIMESTAMP(sales_epoch) :: TIMESTAMP)")
  )

#...............................................................................

db_result %>% show_query(cte = TRUE)

query = sql("
SELECT
  receipt_no,
  receipt_sub_no,
  CAST(EXTRACT(year FROM 
    TO_TIMESTAMP(sales_epoch) :: TIMESTAMP
  ) AS INTEGER) AS 'year'
FROM receipt
"
)
query %>% db_get_query(con)

#-------------------------------------------------------------------------------
# R-053 ------------
# 顧客データ（customer）の郵便番号（postal_cd）に対し、東京（先頭3桁が100〜209のもの）を1、
# それ以外のものを0に二値化せよ。
# さらにレシート明細データ（receipt）と結合し、全期間において売上実績のある顧客数を、作成した二値ごとにカウントせよ。

# 郵便番号の二値化と顧客数の集計
# 郵便番号から東京か否かを 1/0 で二値化し、売上実績のある顧客数を二値ごとにカウントする問題です。

# level: 2

# tag: 
# カテゴリ変換, 文字列処理, CASE式, 重複データ処理, 集約関数, グループ化, フィルタリング, データ結合

# df_customer$postal_cd

# d.c = df_customer %>% 
#   select(customer_id, postal_cd) %>% 
#   mutate(postal_3 = stringr::str_sub(postal_cd, 1L, 3L)) %>% 
#   mutate(tokyo = if_else(between(postal_3, "100", "209"), 1L, 0L))

# sample.1

df_cust = df_customer %>% 
  select(customer_id, postal_cd) %>% 
  mutate(
    tokyo = if_else(
      between(
        stringr::str_sub(postal_cd, 1L, 3L), "100", "209"
      ), 
      1L, 0L
    )
  )

df_cust

df_rec = df_receipt %>% distinct(customer_id)

df_rec

df_cust %>% 
  inner_join(df_rec, by = "customer_id") %>% 
  count(tokyo, name = "n_customer", sort = TRUE)

# A tibble: 2 × 2
#   tokyo n_customer
#   <int>      <int>
# 1     1       4400
# 2     0       3906

# sample.2

df_cust %>% 
  semi_join(df_rec, by = "customer_id") %>% 
  count(tokyo, name = "n_customer", sort = TRUE)

#................................................
# 以下は参考

# sample.1

df_customer %>% 
  select(customer_id, postal_cd) %>% 
  mutate(
    tokyo = if_else(
      between(
        stringr::str_sub(postal_cd, 1L, 3L), "100", "209"
      ), 
      1L, 0L
    )
  ) %>% 
  inner_join(
    df_receipt %>% distinct(customer_id), 
    by = "customer_id"
  ) %>% 
  count(tokyo, name = "n_customer", sort = TRUE)

# A tibble: 2 × 2
#   tokyo n_customer
#   <int>      <int>
# 1     1       4400
# 2     0       3906

# sample.2

df_customer %>% 
  select(customer_id, postal_cd) %>% 
  mutate(
    tokyo = if_else(
      between(
        stringr::str_sub(postal_cd, 1L, 3L), "100", "209"
      ), 
      1L, 0L
    )
  ) %>% 
  semi_join(
    df_receipt %>% distinct(customer_id), 
    by = "customer_id"
  ) %>% 
  count(tokyo, name = "n_customer", sort = TRUE)

#...............................................................................

# sample.1

db_cust = db_customer %>% 
  select(customer_id, postal_cd) %>% 
  mutate(
    tokyo = if_else(
      between(
        stringr::str_sub(postal_cd, 1L, 3L), "100", "209"
      ), 
      1L, 0L
    )
  )

db_cust

db_rec = db_receipt %>% distinct(customer_id)

db_rec

db_result = db_cust %>% 
  inner_join(db_rec, by = "customer_id") %>% 
  count(tokyo, name = "n_customer", sort = TRUE)

db_result %>% collect()

# sample.2

db_result = db_cust %>% 
  semi_join(db_rec, by = "customer_id") %>% 
  count(tokyo, name = "n_customer", sort = TRUE)

db_result %>% collect()

#................................................
# 以下は参考

# sample.1

db_result = db_customer %>% 
  select(customer_id, postal_cd) %>% 
  mutate(
    tokyo = if_else(
      between(
        stringr::str_sub(postal_cd, 1L, 3L), "100", "209"
      ), 
      1L, 0L
    )
  ) %>% 
  inner_join(
    db_receipt %>% distinct(customer_id), 
    by = "customer_id"
  ) %>% 
  count(
    tokyo, 
    name = "n_customer", 
    sort = TRUE
  )

db_result %>% collect()

#   tokyo n_customer
#   <int>      <dbl>
# 1     0       3906
# 2     1       4400

# sample.2

db_result = db_customer %>% 
  select(customer_id, postal_cd) %>% 
  mutate(
    tokyo = if_else(
      between(
        stringr::str_sub(postal_cd, 1L, 3L), "100", "209"
      ), 
      1L, 0L
    )
  ) %>% 
  semi_join(
    db_receipt %>% distinct(customer_id), 
    by = "customer_id"
  ) %>% 
  count(
    tokyo, 
    name = "n_customer", 
    sort = TRUE
  )

db_result %>% collect()

#...............................................................................

db_result %>% show_query(cte = TRUE)

# sample.1-1

query = sql("
WITH customer_region AS (
  SELECT
    customer_id,
    CASE 
      WHEN SUBSTR(postal_cd, 1, 3) BETWEEN '100' AND '209' THEN 1 
      ELSE 0 
    END AS tokyo
  FROM 
    customer
),
active_customers AS (
  SELECT 
    c.*
  FROM 
    customer_region c
  INNER JOIN 
    (SELECT DISTINCT customer_id FROM receipt) r
  USING (customer_id)
)
SELECT 
  tokyo, 
  COUNT(*) AS n_customer
FROM 
  active_customers
GROUP BY 
  tokyo
ORDER BY 
  n_customer DESC
"
)
query %>% db_get_query(con)

# sample.1-2

query = sql("
SELECT 
  CASE 
    WHEN SUBSTR(c.postal_cd, 1, 3) BETWEEN '100' AND '209' THEN 1 
    ELSE 0 
  END AS tokyo, 
  COUNT(*) AS n_customer
FROM 
  customer c
INNER JOIN 
  (SELECT DISTINCT customer_id FROM receipt) r 
USING (customer_id)
GROUP BY 
  tokyo
ORDER BY 
  n_customer DESC
"
)
query %>% db_get_query(con)

# sample.2-1

db_result %>% show_query(cte = TRUE)

query = sql("
WITH customer_region AS (
  SELECT
    customer_id,
    CASE 
      WHEN SUBSTR(postal_cd, 1, 3) BETWEEN '100' AND '209' THEN 1 
      ELSE 0 
    END AS tokyo
  FROM 
    customer
),
active_customers AS (
  SELECT 
    c.*
  FROM 
    customer_region c
  WHERE EXISTS (
    SELECT 1 
    FROM 
      (SELECT DISTINCT customer_id FROM receipt) r
    WHERE 
      c.customer_id = r.customer_id
  )
)
SELECT 
  tokyo, 
  COUNT(*) AS n_customer
FROM 
  active_customers
GROUP BY 
  tokyo
ORDER BY 
  n_customer DESC
"
)
query %>% db_get_query(con)

# sample.2-2

query = sql("
SELECT 
  CASE 
    WHEN SUBSTR(c.postal_cd, 1, 3) BETWEEN '100' AND '209' THEN 1 
    ELSE 0 
  END AS tokyo, 
  COUNT(*) AS n_customer
FROM 
  customer c
WHERE EXISTS (
    SELECT 1 
    FROM 
      (SELECT DISTINCT customer_id FROM receipt) r
    WHERE 
      c.customer_id = r.customer_id
  )
GROUP BY 
  tokyo
ORDER BY 
  n_customer DESC
"
)

query %>% db_get_query(con)

# CASE 式で生成した (1,0) の列 tokyo は 集約キー (GROUP BY に含める列) なので、
# COUNT(*) のような集約関数と同じ SELECT 句に書いても問題ありません。

# ポイント
# tokyo は GROUP BY の対象になるため、集約関数と共存可能。
# COUNT(*) は各 tokyo グループごとの行数を数えるため、正しく動作する。


#-------------------------------------------------------------------------------
# R-055 ------------
# レシート明細（df_receipt）データの売上金額（amount）を顧客ID（customer_id）ごとに合計し、
# その合計金額の四分位点を求めよ。その上で、顧客ごとの売上金額合計に対して以下の基準でカテゴリ値を作成し、
# 顧客ID、売上金額合計とともに10件表示せよ。カテゴリ値は順に1〜4とする。
# 
# 最小値以上第1四分位未満 ・・・ 1を付与
# 第1四分位以上第2四分位未満 ・・・ 2を付与
# 第2四分位以上第3四分位未満 ・・・ 3を付与
# 第3四分位以上 ・・・ 4を付与

# 顧客の売上金額を四分位数で分類

# 顧客ごとの売上金額合計の四分位点を求め、以下の基準でカテゴリ (1～4) を付与する問題です。
# 
# - 最小値以上第1四分位未満 → 1  
# - 第1四分位以上第2四分位未満 → 2  
# - 第2四分位以上第3四分位未満 → 3  
# - 第3四分位以上 → 4

# level: 2

# tag: 
# カテゴリ変換, 欠損値処理, データ型変換, 統計量, 集約関数, CASE式, グループ化, フィルタリング, データ結合

# Rコード (データフレーム操作)

# df_receipt %>%
#     group_by(customer_id) %>%
#     summarise(sum_amount = sum(amount), .groups = "drop") %>%
#     mutate(pct_group = case_when(
#         sum_amount < quantile(sum_amount)[2]  ~ "1",
#         sum_amount < quantile(sum_amount)[3]  ~ "2",
#         sum_amount < quantile(sum_amount)[4]  ~ "3",
#         quantile(sum_amount)[4] <= sum_amount ~ "4"
#     )) %>%
#     head(10)

# kable()でデータフレームをMarkdown形式で表示
# df_customer %>% head(7) %>% knitr::kable()

# レシート明細 (df_receipt) データの概要
df_receipt %>% select(sales_ymd, customer_id, amount, everything())
df_receipt %>% select(sales_ymd, customer_id, amount, everything()) %>% head(7)
df_receipt %>% select(customer_id, amount)
df_receipt %>% select(customer_id, amount) %>% head(7)

df_receipt %>%
  summarise(
    sum_amount = sum(amount, na.rm = TRUE), 
    .by = customer_id
  ) %>% 
  filter(sum_amount > 0.0) %>% 
  mutate(
    pct_group = 
      cut(
        sum_amount, 
        breaks = quantile(sum_amount), 
        labels = FALSE, 
        right = FALSE, 
        include.lowest = TRUE
      ) %>% 
      as.character()
  ) %>% 
  arrange(customer_id) %>% 
  head(10)

# A tibble: 10 × 3
#    customer_id    sum_amount pct_group
#    <chr>               <dbl> <chr>    
#  1 CS001113000004       1298 2        
#  2 CS001114000005        626 2        
#  3 CS001115000010       3044 3        
#  4 CS001205000004       1988 3        
#  5 CS001205000006       3337 3        
#  6 CS001211000025        456 1        
#  7 CS001212000027        448 1        
#  8 CS001212000031        296 1        
#  9 CS001212000046        228 1        
# 10 CS001212000070        456 1    

#...............................................................................
# Rコード (データベース操作)

# PERCENTILE_CONT() はウィンドウ関数 (OVER ()) として使えない!
db_receipt %>% 
  mutate(
    p25 = quantile(amount, 0.25, na.rm = TRUE)
  ) %>% 
  show_query()

query = sql("
SELECT
  *,
  PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY amount) OVER () AS p25
FROM receipt
"
)
query %>% db_get_query(con)

# Error in `dbSendQuery()`:
# ! rapi_prepare: Failed to extract statements:
# Parser Error: ORDER BY is not implemented for window functions!

#................................................
# answer
db_sales_amount = db_receipt %>% 
  summarise(
    sum_amount = sum(amount, na.rm = TRUE), 
    .by = customer_id
  ) %>% 
  filter(!is.na(sum_amount))

db_sales_amount %>% head(5)

db_sales_pct = db_sales_amount %>%
  summarise(
    p25 = quantile(sum_amount, 0.25), 
    p50 = quantile(sum_amount, 0.5), 
    p75 = quantile(sum_amount, 0.75)
  )

db_sales_pct

db_result = db_sales_amount %>% 
  cross_join(db_sales_pct) %>% 
  mutate(
    pct_group = case_when(
      (sum_amount < p25) ~ "1", 
      (sum_amount < p50) ~ "2", 
      (sum_amount < p75) ~ "3", 
      (sum_amount >= p75) ~ "4"
    )
  ) %>% 
  select(customer_id, sum_amount, pct_group) %>% 
  arrange(customer_id) %>% 
  head(10)
  
db_result %>% collect()

#................................................
db_sales_amount %>% 
  cross_join(db_sales_pct) %>% 
  mutate(
    pct_group = 
      cut(
        sum_amount, 
        breaks = c(-Inf, p25, p50, p75, Inf), 
        labels = FALSE, 
        right = FALSE
      ) %>% 
      as.character()
  ) %>% 
  head(10)
#=> Error in `cut()`: ! `breaks` are not unique.

#...............................................................................
# SQLクエリ
db_result %>% show_query(cte = TRUE)

query = sql("
WITH q01 AS (
  SELECT customer_id, SUM(amount) AS sum_amount
  FROM receipt
  GROUP BY customer_id
  HAVING (NOT(((SUM(amount)) IS NULL)))
),
q02 AS (
  SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY sum_amount) AS p25,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sum_amount) AS p50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY sum_amount) AS p75
  FROM q01
),
q03 AS (
  SELECT LHS.*, RHS.*
  FROM q01 LHS
  CROSS JOIN q02 RHS
)
SELECT
  customer_id,
  sum_amount,
  CASE
WHEN ((sum_amount < p25)) THEN '1'
WHEN ((sum_amount < p50)) THEN '2'
WHEN ((sum_amount < p75)) THEN '3'
WHEN ((sum_amount >= p75)) THEN '4'
END AS pct_group
FROM q03 q01
ORDER BY customer_id
LIMIT 10
"
)
query %>% db_get_query(con)

query = sql("
WITH customer_sales AS (
  SELECT 
    customer_id, 
    SUM(amount) AS sum_amount
  FROM 
    receipt
  GROUP BY 
    customer_id
  HAVING
    SUM(amount) IS NOT NULL
),
percentiles AS (
  SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY sum_amount) AS p25,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sum_amount) AS p50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY sum_amount) AS p75
  FROM 
    customer_sales
)
SELECT
  cs.customer_id,
  cs.sum_amount,
  CASE
    WHEN cs.sum_amount < p.p25 THEN '1'
    WHEN cs.sum_amount < p.p50 THEN '2'
    WHEN cs.sum_amount < p.p75 THEN '3'
    ELSE '4'
  END AS pct_group
FROM 
  customer_sales cs
CROSS JOIN 
  percentiles p
ORDER BY 
  cs.customer_id
LIMIT 10
"
)

query %>% db_get_query(con)

# 参考: a JOIN b ON 1=1

query = sql("
  SELECT 
    customer_id, 
    SUM(amount) AS sum_amount
  FROM 
    receipt
  GROUP BY 
    customer_id
  HAVING
    SUM(amount) IS NOT NULL
"
)
query %>% db_get_query(con)

query = sql("
WITH customer_sales AS (
  SELECT 
    customer_id, 
    SUM(amount) AS sum_amount
  FROM 
    receipt
  GROUP BY 
    customer_id
  HAVING
    SUM(amount) IS NOT NULL
)
  SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY sum_amount) AS p25,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sum_amount) AS p50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY sum_amount) AS p75
  FROM 
    customer_sales
"
)

query %>% db_get_query(con)
#     p25   p50   p75
#   <dbl> <dbl> <dbl>
# 1 548.5  1478  3651

#-------------------------------------------------------------------------------
# R-056 ------------
# 顧客データ（customer）の年齢（age）をもとに10歳刻みで年代を算出し、
# 顧客ID（customer_id）、生年月日（birth_day）とともに10件表示せよ。
# ただし、60歳以上は全て60歳代とすること。年代を表すカテゴリ名は任意とする。

# 年齢を10歳刻みで分類
# 年齢を10歳刻みで年代に分類する問題です。

# level: 1

# tag: 
# カテゴリ変換, データ型変換

# pacman::p_load(epikit)

df_customer %>% 
  select(customer_id, birth_day, age) %>% 
  mutate(
    age_rng = epikit::age_categories(
      age, lower = 0, upper = 60, by = 10
    )
  ) %>% 
  head(10)

# A tibble: 21,971 × 4
#    customer_id    birth_day    age age_rng
#    <chr>          <chr>      <int> <fct>  
#  1 CS021313000114 1981-04-29    37 30-39  
#  2 CS037613000071 1952-04-01    66 60+    
#  3 CS031415000172 1976-10-04    42 40-49  
#  4 CS028811000001 1933-03-27    86 60+    
#  5 CS001215000145 1995-03-29    24 20-29  
#  6 CS020401000016 1974-09-15    44 40-49  
#  7 CS015414000103 1977-08-09    41 40-49  
#  8 CS029403000008 1973-08-17    45 40-49  
# ...

#...............................................................................

# db_result = db_customer %>% 
#   select(customer_id, birth_day, age) %>% 
#   mutate(
#     age_rng = 
#       pmin((floor(age / 10) * 10), 60) %>% 
#       as.integer()
#   ) %>% 
#   head(10)

db_result = db_customer %>% 
  select(customer_id, birth_day, age) %>% 
  mutate(
    age_rng = 
      case_when(
        !is.na(age) ~ 
        pmin((floor(age / 10) * 10), 60) %>% as.integer()
      )
  ) %>% 
  head(10)

db_result %>% collect()

# A tibble: 10 × 4
#    customer_id    birth_day    age age_rng
#    <chr>          <date>     <int>   <int>
#  1 CS021313000114 1981-04-29    37      30
#  2 CS037613000071 1952-04-01    66      60
#  3 CS031415000172 1976-10-04    42      40
#  4 CS028811000001 1933-03-27    86      60
#  5 CS001215000145 1995-03-29    24      20
#  6 CS020401000016 1974-09-15    44      40
#  7 CS015414000103 1977-08-09    41      40
#  ...

#................................................
# age が NA を含む場合のチェック
df = tribble(
  ~customer_id, ~age, ~gender_cd, 
  "CS021313000114", NA, "1", 
  "CS037613000071", NA, "9", 
  "CS031415000172", NA, "1", 
  "CS001215000145", 24, NA
)
d = con %>% my_tbl(df = df, overwrite = TRUE)
dbReadTable(con, "df")
db_cust = rows_update(db_customer, d, by = "customer_id", unmatched = "ignore", in_place = FALSE)
db_customer %>% filter(is.na(age))
db_cust %>% filter(is.na(age) | is.na(gender_cd))

db_cust %>% 
  compute(name = "cust_na", temporary = TRUE, overwrite = TRUE)
dbReadTable(con, "cust_na") %>% filter(is.na(age))

db_cust %>% 
  select(customer_id, birth_day, gender_cd, age) %>% 
  mutate(
    age_rng = 
      pmin((floor(age / 10) * 10), 60) %>% 
      as.integer()
  ) %>% 
  filter(is.na(age) | is.na(gender_cd))

#   customer_id    birth_day  gender_cd   age age_rng
#   <chr>          <date>     <chr>     <dbl>   <int>
# 1 CS021313000114 1981-04-29 1            NA      60
# 2 CS037613000071 1952-04-01 9            NA      60
# 3 CS031415000172 1976-10-04 1            NA      60
# 4 CS001215000145 1995-03-29 NA           24      20

db_cust %>% 
  select(customer_id, birth_day, gender_cd, age) %>% 
  mutate(
    age_rng = 
      case_when(
        !is.na(age) ~ 
        pmin((floor(age / 10) * 10), 60) %>% as.integer()
      )
  ) %>% 
  filter(is.na(age) | is.na(gender_cd))

#   customer_id    birth_day  gender_cd   age age_rng
#   <chr>          <date>     <chr>     <dbl>   <int>
# 1 CS021313000114 1981-04-29 1            NA      NA
# 2 CS037613000071 1952-04-01 9            NA      NA
# 3 CS031415000172 1976-10-04 1            NA      NA
# 4 CS001215000145 1995-03-29 NA           24      20

#...............................................................................

db_result %>% show_query(cte = FALSE)

# pmin(1, 2, NA, na.rm = FALSE) => NA

query = sql("
SELECT
  customer_id,
  birth_day,
  age,
  CASE 
    WHEN age IS NULL THEN NULL 
    ELSE CAST(LEAST((FLOOR(age / 10.0) * 10.0), 60.0) AS INTEGER)
  END AS age_rng
FROM 
  customer
LIMIT 10
"
)
query %>% db_get_query(con)

#................................................

# cust_na でテスト

query = sql("
SELECT
  customer_id,
  birth_day,
  age,
  CASE 
    WHEN age IS NULL THEN NULL 
    ELSE CAST(LEAST((FLOOR(age / 10.0) * 10.0), 60.0) AS INTEGER)
  END AS age_rng
FROM 
  cust_na
-- LIMIT 10
"
)
query %>% db_get_query(con)
query %>% db_get_query(con) %>% filter(is.na(age))

#   customer_id    birth_day    age age_rng
#   <chr>          <date>     <dbl>   <int>
# 1 CS021313000114 1981-04-29    NA      NA
# 2 CS037613000071 1952-04-01    NA      NA
# 3 CS031415000172 1976-10-04    NA      NA

#-------------------------------------------------------------------------------
# R-057 ------------
# 056の抽出結果と性別コード（gender_cd）により、新たに性別×年代の組み合わせを表すカテゴリデータを作成し、
# 10件表示せよ。組み合わせを表すカテゴリの値は任意とする。

# 性別×年代のカテゴリの作成

# 年代 (056の結果) と性別コードを組み合わせたカテゴリを作成する問題です。

# level: 2

# tag: 
# カテゴリ変換, 文字列処理, CASE式, データ型変換, 欠損値処理

pacman::p_load(epikit)

df_cust = df_customer %>% 
  select(customer_id, birth_day, gender_cd, age) %>% 
  mutate(
    age_rng = epikit::age_categories(
      age, lower = 0, upper = 60, by = 10
    )
  )

# df_cust[2, "gender_cd"] = NA
# df_cust[3, "age"] = NA

df_cust %>% 
  unite("gender_age", gender_cd, age_rng, sep = "_", remove = FALSE) %>% 
  mutate(
    gender_age = 
      if_else(
        is.na(gender_cd) | is.na(age), 
        NA, 
        gender_age
      )
  ) %>% 
  select(-age_rng) %>% 
  head(10)

# A tibble: 10 × 5
#    customer_id    birth_day  gender_age gender_cd   age
#    <chr>          <date>     <chr>      <chr>     <int>
#  1 CS021313000114 1981-04-29 1_30-39    1            37
#  2 CS037613000071 1952-04-01 9_60+      9            66
#  3 CS031415000172 1976-10-04 1_40-49    1            42
#  4 CS028811000001 1933-03-27 1_60+      1            86
#  5 CS001215000145 1995-03-29 1_20-29    1            24
#  6 CS020401000016 1974-09-15 0_40-49    0            44
#  7 CS015414000103 1977-08-09 1_40-49    1            41
#  8 CS029403000008 1973-08-17 0_40-49    0            45
#  9 CS015804000004 1931-05-02 0_60+      0            87
# 10 CS033513000180 1962-07-11 1_50-59    1            56

# d$gender_age %>% levels() %>% writeLines(sep = ", ")
# d$gender_age %>% levels() %>% ll.json()
# ["0_10-19", "0_20-29", "0_30-39", "0_40-49", "0_50-59", "0_60+", "1_10-19", "1_20-29", "1_30-39", "1_40-49", "1_50-59", "1_60+", "9_10-19", "9_20-29", "9_30-39", "9_40-49", "9_50-59", "9_60+"] 

#...............................................................................

db_result = db_customer %>% 
  select(customer_id, birth_day, gender_cd, age) %>% 
  mutate(
    tmp = pmin(FLOOR(age / 10) * 10, 60) %>% as.integer() %>% as.character(), 
    age_rng = sql("LPAD(tmp, 2, '0')"), 
    gender_age = 
      if_else(
        is.na(gender_cd) | is.na(age), 
        NA, 
        stringr::str_c(gender_cd, age_rng, sep = "_")
      )
  ) %>% 
  select(-c(tmp, age_rng)) %>% 
  head(10)

db_result %>% collect()

# A tibble: 10 × 5
#    customer_id    birth_day  gender_cd   age gender_age
#    <chr>          <date>     <chr>     <int> <chr>     
#  1 CS021313000114 1981-04-29 1            37 1_30      
#  2 CS037613000071 1952-04-01 9            66 9_60      
#  3 CS031415000172 1976-10-04 1            42 1_40      
#  4 CS028811000001 1933-03-27 1            86 1_60      
#  5 CS001215000145 1995-03-29 1            24 1_20      
#  6 CS020401000016 1974-09-15 0            44 0_40      
#  7 CS015414000103 1977-08-09 1            41 1_40      
#  8 CS029403000008 1973-08-17 0            45 0_40      
#  9 CS015804000004 1931-05-02 0            87 0_60      
# 10 CS033513000180 1962-07-11 1            56 1_50      

#................................................
# db_cust でテスト

db_cust %>% 
  select(customer_id, birth_day, gender_cd, age) %>% 
  mutate(
    tmp = pmin(FLOOR(age / 10) * 10, 60) %>% as.integer() %>% as.character(), 
    age_rng = sql("LPAD(tmp, 2, '0')"), 
    gender_age = 
      if_else(
        is.na(gender_cd) | is.na(age), 
        NA, 
        stringr::str_c(gender_cd, age_rng, sep = "_")
      )
  ) %>% 
  select(-c(tmp, age_rng)) %>% 
  filter(is.na(gender_cd) | is.na(age))

#   customer_id    birth_day  gender_cd   age gender_age
#   <chr>          <date>     <chr>     <dbl> <chr>     
# 1 CS021313000114 1981-04-29 1            NA NA        
# 2 CS037613000071 1952-04-01 9            NA NA        
# 3 CS031415000172 1976-10-04 1            NA NA        
# 4 CS001215000145 1995-03-29 NA           24 NA      

#...............................................................................

db_result %>% show_query(cte = FALSE)

# query = sql("
# SELECT
#   customer_id,
#   birth_day, 
#   CONCAT_WS('_', gender_cd, age_rng) AS gender_age, 
#   gender_cd,
#   age
# FROM (
#   SELECT
#     *, 
#     LPAD(
#       CAST(
#         LEAST(CAST(FLOOR(age / 10.0) * 10.0 AS INTEGER), 60) AS TEXT
#       ), 
#       2, '0'
#     ) AS age_rng
#   FROM 
#     customer
# )
# LIMIT 10
# "
# )
# query %>% db_get_query(con)

query = sql("
SELECT
  customer_id,
  birth_day, 
  gender_cd,
  age, 
  CASE 
    WHEN gender_cd IS NULL OR age_rng IS NULL THEN NULL
    ELSE CONCAT_WS('_', gender_cd, age_rng) 
  END AS gender_age
FROM (
  SELECT
    *, 
    CASE 
      WHEN age IS NULL THEN NULL 
      ELSE 
        LPAD(
          CAST(
            LEAST(CAST(FLOOR(age / 10.0) * 10.0 AS INTEGER), 60) AS TEXT
          ), 
          2, '0'
        )
    END AS age_rng
  FROM 
    customer
)
LIMIT 10
"
)

query %>% db_get_query(con)

#-------------------------------------------------------------------------------
# R-058 ------------
# 顧客データ（customer）の性別コード（gender_cd）をダミー変数化し、顧客ID（customer_id）とともに10件表示せよ。

# 性別コードをダミー変数化

# 顧客データの性別コードをダミー変数化する問題です。

# level: 1

# tag: 
# カテゴリ変換, 欠損値処理, CASE式, データ型変換

d = df_customer %>% mutate(across(gender_cd, ~ as.factor(.x)))
d$gender_cd %>% levels()

# d %>% recipes::recipe(~ customer_id + gender_cd, data = .)

df_customer %>% 
  mutate(across(gender_cd, ~ as.factor(.x))) %>% 
  recipes::recipe() %>% 
  step_select(customer_id, gender_cd) %>% 
  step_dummy(gender_cd, one_hot = TRUE) %>% 
  prep() %>% 
  bake(new_data = NULL) %>% 
  head(10)

d = df_customer
d$gender_cd %<>% inset(2, NA)
d %>% 
  mutate(across(gender_cd, ~ as.factor(.x))) %>% 
  recipes::recipe() %>% 
  step_select(customer_id, gender_cd) %>% 
  step_dummy(gender_cd, one_hot = TRUE) %>% 
  prep() %>% 
  bake(new_data = NULL) %>% 
  head(10)

# A tibble: 21,971 × 4
#    customer_id    gender_cd_X0 gender_cd_X1 gender_cd_X9
#    <fct>                 <dbl>        <dbl>        <dbl>
#  1 CS021313000114            0            1            0
#  2 CS037613000071            0            0            1
#  3 CS031415000172            0            1            0
#  4 CS028811000001            0            1            0
#  5 CS001215000145            0            1            0
#  6 CS020401000016            1            0            0
#  7 CS015414000103            0            1            0
# ...

#...............................................................................

db_result = db_customer %>% 
  select(
    customer_id, gender_cd
  ) %>% 
  mutate(
    gender_cd_0 = if_else(gender_cd == "0", 1L, 0L), 
    gender_cd_1 = if_else(gender_cd == "1", 1L, 0L), 
    gender_cd_9 = if_else(gender_cd == "9", 1L, 0L), 
    .keep = "unused"
  ) %>% 
  head(10)

db_result %>% collect()

# A tibble: 21,971 × 4
#    customer_id    gender_cd_0 gender_cd_1 gender_cd_9
#    <chr>                <int>       <int>       <int>
#  1 CS021313000114           0           1           0
#  2 CS037613000071           0           0           1
#  3 CS031415000172           0           1           0
#  ...

#................................................

# NA を含む場合のチェック
df = tribble(
  ~customer_id, ~gender_cd, 
  "CS021313000114", NA, 
  "CS037613000071", NA, 
  "CS031415000172", NA
)
d = con %>% my_tbl(df = df, overwrite = TRUE)
dbReadTable(con, "df")
db_cust = rows_update(db_customer, d, by = "customer_id", unmatched = "ignore", in_place = FALSE)
db_customer %>% filter(is.na(gender_cd))
db_cust %>% filter(is.na(gender_cd))

db_cust %>% 
  compute(name = "cust_na", temporary = TRUE, overwrite = TRUE)
dbReadTable(con, "cust_na") %>% filter(is.na(gender_cd))

con %>% DBI::dbListTables()

db_cust %>% 
  select(
    customer_id, gender_cd
  ) %>% 
  mutate(
    gender_cd_0 = if_else(gender_cd == "0", 1L, 0L), 
    gender_cd_1 = if_else(gender_cd == "1", 1L, 0L), 
    gender_cd_9 = if_else(gender_cd == "9", 1L, 0L), 
    .keep = "unused"
  ) %>% 
  filter(customer_id %in% df$customer_id) %>% 
  collect()

#   customer_id    gender_cd_0 gender_cd_1 gender_cd_9
#   <chr>                <int>       <int>       <int>
# 1 CS021313000114          NA          NA          NA
# 2 CS037613000071          NA          NA          NA
# 3 CS031415000172          NA          NA          NA

#...............................................................................

db_result %>% show_query()

query = sql("
SELECT
  customer_id,
  CASE WHEN (gender_cd = '0') THEN 1 WHEN NOT (gender_cd = '0') THEN 0 END AS gender_cd_0,
  CASE WHEN (gender_cd = '1') THEN 1 WHEN NOT (gender_cd = '1') THEN 0 END AS gender_cd_1,
  CASE WHEN (gender_cd = '9') THEN 1 WHEN NOT (gender_cd = '9') THEN 0 END AS gender_cd_9
FROM customer
LIMIT 10
"
)
query %>% db_get_query(con)

# sample.1
query = sql("
SELECT
  customer_id,
  CASE 
    WHEN gender_cd = '0' THEN 1 WHEN gender_cd IS NULL THEN NULL ELSE 0 
  END AS gender_cd_0,
  CASE 
    WHEN gender_cd = '1' THEN 1 WHEN gender_cd IS NULL THEN NULL ELSE 0 
  END AS gender_cd_1,
  CASE 
    WHEN gender_cd = '9' THEN 1 WHEN gender_cd IS NULL THEN NULL ELSE 0 
  END AS gender_cd_9
FROM customer
LIMIT 10
"
)
query %>% db_get_query(con)

# sample.2
# gender_cd に欠損値が含まれない場合は次のように簡略化できる。
query = sql("
SELECT
  customer_id,
  CASE WHEN gender_cd = '0' THEN 1 ELSE 0 END AS gender_cd_0,
  CASE WHEN gender_cd = '1' THEN 1 ELSE 0 END AS gender_cd_1,
  CASE WHEN gender_cd = '9' THEN 1 ELSE 0 END AS gender_cd_9
FROM customer
LIMIT 10
"
)
query %>% db_get_query(con)

# A tibble: 21,971 × 4
#    customer_id    gender_cd_0 gender_cd_1 gender_cd_9
#    <chr>                <int>       <int>       <int>
#  1 CS021313000114           0           1           0
#  2 CS037613000071           0           0           1
#  3 CS031415000172           0           1           0
#  ...

#................................................
# cust_na テーブルで欠損値を含む場合のテスト

query = sql("
select
  customer_id, 
  gender_cd, 
  case when gender_cd = '0' then 1 else 0 end as gender_cd_0, 
  case when gender_cd = '1' then 1 else 0 end as gender_cd_1, 
  case when gender_cd = '9' then 1 else 0 end as gender_cd_9
from
  cust_na
"
)
query %>% db_get_query(con) %>% filter(is.na(gender_cd))

query = sql("
SELECT
  customer_id,
  gender_cd,
  CASE WHEN gender_cd = '0' THEN 1 WHEN gender_cd IS NULL THEN NULL ELSE 0 END AS gender_cd_0,
  CASE WHEN gender_cd = '1' THEN 1 WHEN gender_cd IS NULL THEN NULL ELSE 0 END AS gender_cd_1,
  CASE WHEN gender_cd = '9' THEN 1 WHEN gender_cd IS NULL THEN NULL ELSE 0 END AS gender_cd_9
FROM 
  cust_na
"
)
query %>% db_get_query(con)
query %>% db_get_query(con) %>% filter(is.na(gender_cd))

#-------------------------------------------------------------------------------
# R-060 ------------
# レシート明細データ（receipt）の売上金額（amount）を顧客ID（customer_id）ごとに合計し、
# 売上金額合計を最小値0、最大値1に正規化して顧客ID、売上金額合計とともに10件表示せよ。
# ただし、顧客IDが"Z"から始まるのものは非会員を表すため、除外して計算すること。

# 顧客ごとの売上金額合計の正規化

# 顧客IDごとの売上金額合計を計算し、非会員を除外した上で、売上金額合計を0から1に正規化する問題です。

# level: 2

# tag: 
# 正規化, 集約関数, ウィンドウ関数, CASE式, グループ化, パターンマッチング, フィルタリング

df_receipt %>% 
  filter(!str_detect(customer_id, "^Z")) %>% 
  summarise(
    sum_amount = sum(amount, na.rm = TRUE), 
    .by = "customer_id"
  ) %>% 
  mutate(
    norm_amount = scales::rescale(sum_amount, to = c(0, 1))
  ) %>% 
  arrange(customer_id)

# A tibble: 8,306 × 3
#    customer_id    sum_amount norm_amount
#    <chr>               <dbl>       <dbl>
#  1 CS001113000004       1298   0.053354 
#  2 CS001114000005        626   0.024157 
#  3 CS001115000010       3044   0.12921  
#  4 CS001205000004       1988   0.083333 
#  5 CS001205000006       3337   0.14194  
# ...

#...............................................................................

# 例外処理の追加
# ゼロ除算を避ける処理を追加する

db_result = db_receipt %>% 
  filter(!customer_id %LIKE% "Z%") %>% 
  summarise(
    sum_amount = sum(amount), 
    .by = "customer_id"
  ) %>% 
  mutate(
    min_amount = min(sum_amount), 
    max_amount = max(sum_amount), 
    norm_amount = case_when(
      (max_amount -  min_amount) > 0.0 ~ 
      (sum_amount - min_amount) / (max_amount -  min_amount), 
      .default = 0.5
    )
  ) %>% 
  select(-c(min_amount, max_amount)) %>% 
  arrange(customer_id) %>% 
  head(10)

db_result %>% collect()

# A tibble: 10 × 3
#    customer_id    sum_amount norm_amount
#    <chr>               <dbl>       <dbl>
#  1 CS001113000004       1298   0.053354 
#  2 CS001114000005        626   0.024157 
#  3 CS001115000010       3044   0.12921  
#  4 CS001205000004       1988   0.083333 
#  5 CS001205000006       3337   0.14194  
#  6 CS001211000025        456   0.016771 
#  7 CS001212000027        448   0.016423 
#  8 CS001212000031        296   0.0098193
#  9 CS001212000046        228   0.0068648
# 10 CS001212000070        456   0.016771 

#...............................................................................

db_result %>% show_query(cte = TRUE)

# 例外処理の追加
# ゼロ除算を避ける処理を追加する

# sample.1

query = sql("
WITH customer_sales AS (
  SELECT 
    customer_id, 
    SUM(amount) AS sum_amount
  FROM 
    receipt
  WHERE 
    customer_id NOT LIKE 'Z%'
  GROUP BY 
    customer_id
),
customer_sales_with_stats AS (
  SELECT 
    customer_id, 
    sum_amount, 
    MIN(sum_amount) OVER () AS min_amount,
    MAX(sum_amount) OVER () AS max_amount
  FROM 
    customer_sales
)
SELECT
  customer_id,
  sum_amount,
  CASE 
    WHEN max_amount - min_amount > 0.0 THEN 
      (sum_amount - min_amount) / (max_amount - min_amount)
    ELSE 0.5
  END AS norm_amount
FROM 
  customer_sales_with_stats
ORDER BY 
  customer_id
LIMIT 10
"
)
query %>% db_get_query(con)

# ブログには掲載しない
# sample.2
query = sql("
WITH customer_sales AS (
  SELECT 
    customer_id, 
    SUM(amount) AS sum_amount
  FROM receipt
  WHERE customer_id NOT LIKE 'Z%'
  GROUP BY customer_id
),
normalized_sales AS (
  SELECT
    customer_id,
    sum_amount,
    (
    sum_amount - MIN(sum_amount) OVER ()) / 
    (MAX(sum_amount) OVER () - MIN(sum_amount) OVER ()
    ) AS norm_amount
  FROM customer_sales
)
SELECT *
FROM normalized_sales
ORDER BY customer_id
LIMIT 10
"
)
query %>% db_get_query(con)

# A tibble: 8,306 × 3
#    customer_id    sum_amount norm_amount
#    <chr>               <dbl>       <dbl>
#  1 CS001113000004       1298   0.053354 
#  2 CS001114000005        626   0.024157 
#  3 CS001115000010       3044   0.12921  
#  4 CS001205000004       1988   0.083333 
#  5 CS001205000006       3337   0.14194  
# ...

#-------------------------------------------------------------------------------
# R-069 ------------
# レシート明細データ（receipt）と商品データ（product）を結合し、顧客毎に全商品の売上金額合計と、
# カテゴリ大区分コード（category_major_cd）が"07"（瓶詰缶詰）の売上金額合計を計算の上、両者の比率を求めよ。
# 抽出対象はカテゴリ大区分コード"07"（瓶詰缶詰）の売上実績がある顧客のみとし、結果を10件表示せよ。

# 瓶詰缶詰の売上割合を顧客ごとに算出

# カテゴリ大区分コード "07" の売上実績がある顧客に対して、全商品の売上金額合計とカテゴリ "07" の売上金額合計の比率を求める問題です。

# level: 2

# tag: 
# CASE式, データ型変換, 集約関数, グループ化, フィルタリング, データ結合

df_receipt %>% 
  inner_join(
    df_product, by = "product_cd"
  ) %>% 
  select(
    customer_id, category_major_cd, amount
  ) %>% 
  mutate(
    amount_07 = if_else(
      category_major_cd == "07", amount, 0.0
    )
  ) %>% 
  summarise(
    across(c(amount, amount_07), 
    ~ sum(.x, na.rm = TRUE)), 
    .by = "customer_id"
  ) %>% 
  filter(amount_07 > 0.0) %>% 
  mutate(sales_rate = amount_07 / amount) %>% 
  arrange(customer_id) %>% 
  head(10)

# A tibble: 10 × 4
#    customer_id    amount amount_07 sales_rate
#    <chr>           <dbl>     <dbl>      <dbl>
#  1 CS001113000004   1298      1298    1      
#  2 CS001114000005    626       486    0.77636
#  3 CS001115000010   3044      2694    0.88502
#  4 CS001205000004   1988       346    0.17404
#  5 CS001205000006   3337      2004    0.60054
#  6 CS001212000027    448       200    0.44643
#  7 CS001212000031    296       296    1      
#  8 CS001212000046    228       108    0.47368
#  9 CS001212000070    456       308    0.67544
# 10 CS001213000018    243       145    0.59671

#...............................................................................

db_result = db_receipt %>% 
  inner_join(
    db_product, by = "product_cd"
  ) %>% 
  select(
    customer_id, category_major_cd, amount
  ) %>% 
  mutate(
    amount_07 = if_else(
      category_major_cd == "07", amount, 0.0
    )
  ) %>% 
  summarise(
    across(c(amount, amount_07), ~ sum(.x)), 
    .by = "customer_id"
  ) %>% 
  filter(amount_07 > 0.0) %>% 
  mutate(sales_rate = amount_07 / amount) %>% 
  arrange(customer_id) %>% 
  head(10)

db_result %>% collect()

#...............................................................................

db_result %>% show_query(cte = TRUE)

# db_receipt %>% 
#   mutate(x = amount %>% round(2L), .keep = "used") %>% my_show_query()

query = sql("
WITH q01 AS (
  SELECT customer_id, category_major_cd, amount
  FROM receipt
  INNER JOIN product
    ON (receipt.product_cd = product.product_cd)
),
q02 AS (
  SELECT
    q01.*,
    CASE WHEN (category_major_cd = '07') THEN amount WHEN NOT (category_major_cd = '07') THEN 0.0 END AS amount_07
  FROM q01
),
q03 AS (
  SELECT customer_id, SUM(amount) AS amount, SUM(amount_07) AS amount_07
  FROM q02 q01
  GROUP BY customer_id
  HAVING (SUM(amount_07) > 0.0)
)
SELECT q01.*, amount_07 / amount AS sales_rate
FROM q03 q01
ORDER BY customer_id
LIMIT 10
"
)
query %>% db_get_query(con)

query = sql("
WITH customer_sales AS (
SELECT 
  r.customer_id,
  SUM(r.amount) AS amount,
  SUM(
    CASE 
      WHEN p.category_major_cd = '07' THEN r.amount 
      ELSE 0.0 
    END
  ) AS amount_07
FROM 
  receipt r
INNER JOIN 
  product p 
USING (product_cd)
GROUP BY 
  r.customer_id
HAVING 
  amount_07 > 0.0
)
SELECT 
  *, 
  amount_07 / amount AS sales_rate
FROM 
  customer_sales
ORDER BY 
  customer_id
LIMIT 10
"
)
query %>% db_get_query(con)

#-------------------------------------------------------------------------------
# R-070 ------------
# レシート明細データ（receipt）の売上日（sales_ymd）に対し、顧客データ（customer）の会員申込日
# （application_date）からの経過日数を計算し、顧客ID（customer_id）、売上日、会員申込日とともに
# 10件表示せよ（sales_ymdは数値、application_dateは文字列でデータを保持している点に注意）。

# 会員申込日からの経過日数の計算

# 売上日に対し、顧客の会員申込日までの経過日数を計算し、顧客ID・売上日・会員申込日とともに表示する問題です。

# level: 2

# tag: 
# 日付処理, データ型変換, 重複データ処理, データ結合

# 経過日数
"20170322" %>% lubridate::parse_date_time("%Y%m%d")
"20170322" %>% lubridate::parse_date_time("%Y%m%d") %>% class()
# "POSIXlt" "POSIXt" 
strptime("20170322", "%Y%m%d")
strptime("20170322", "%Y%m%d") %>% class()
# "POSIXlt" "POSIXt" 
difftime(strptime("20170322", "%Y%m%d"), strptime("20170222", "%Y%m%d")) %>% as.numeric(units = "days")
strptime("2017-03-22 11:22:33", "%Y-%m-%d %H:%M:%S") %>% 
  interval(strptime("20170328", "%Y%m%d")) %/% lubridate::days(1L)

# sample.1
# time_length()
df_receipt %>% 
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    df_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    elapsed_days = 
      lubridate::interval(
        strptime(application_date, "%Y%m%d"), 
        strptime(as.character(sales_ymd), "%Y%m%d")
      ) %>% 
      lubridate::time_length("day")
  ) %>% 
  arrange(customer_id, sales_ymd)

# A tibble: 32,411 × 4
#    customer_id    sales_ymd application_date elapsed_days
#    <chr>              <int> <chr>                   <dbl>
#  1 CS001113000004  20190308 20151105                 1219
#  2 CS001114000005  20180503 20160412                  751
#  3 CS001114000005  20190731 20160412                 1205
#  4 CS001115000010  20171228 20150417                  986
#  5 CS001115000010  20180701 20150417                 1171
#  ...

# sample.2
df_receipt %>% 
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    df_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    elapsed_days = 
      lubridate::interval(
        strptime(application_date, "%Y%m%d"), 
        strptime(as.character(sales_ymd), "%Y%m%d")
      ) %/%
      lubridate::days(1L) %>% 
      as.integer()
  ) %>% 
  arrange(customer_id, sales_ymd)

# A tibble: 32,411 × 4
#    customer_id    sales_ymd application_date elapsed_days
#    <chr>              <int> <chr>                   <int>
#  1 CS001113000004  20190308 20151105                 1219
#  2 CS001114000005  20180503 20160412                  751
#  3 CS001114000005  20190731 20160412                 1205
#  4 CS001115000010  20171228 20150417                  986
#  5 CS001115000010  20180701 20150417                 1171
#  6 CS001115000010  20190405 20150417                 1449
#  ...

# difftime()
df_receipt %>% 
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    df_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    elapsed_days = 
      difftime(
        strptime(as.character(sales_ymd), "%Y%m%d"), 
        strptime(application_date, "%Y%m%d"), 
        units = "days"
      ) %>% 
      as.integer()
  ) %>% 
  arrange(customer_id, sales_ymd)

#...............................................................................

db_receipt %>% 
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    db_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    elapsed_days = 
      difftime(
        strptime(as.character(sales_ymd), "%Y%m%d"), 
        strptime(application_date, "%Y%m%d"), 
        units = "days"
      ) %>% 
      as.integer()
  ) %>% 
  arrange(customer_id, sales_ymd)

# 上記、db_receipt, db_customer がテーブル参照。
# Error in `difftime()`:
# ! Don't know how to translate `difftime()`

# 
db_receipt %>% 
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    db_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    elapsed_days = 
      # strptime(as.character(sales_ymd), "%Y%m%d") - strptime(application_date, "%Y%m%d")
      lubridate::interval(
        strptime(application_date, "%Y%m%d"), 
        strptime(as.character(sales_ymd), "%Y%m%d")
      ) %/%
      lubridate::days(1L) %>% 
      as.integer()
  ) %>% 
  arrange(customer_id, sales_ymd)

# Error in `lubridate::interval()`:
# ! No known SQL translation

#................................................
# dplyr が認識できない関数をエラーにする 
options(dplyr.strict_sql = FALSE)

db_result = db_receipt %>% 
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    db_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    elapsed_days = 
      STRPTIME(as.character(sales_ymd), "%Y%m%d") - 
        STRPTIME(application_date, "%Y%m%d")
  ) %>% 
  mutate(
    elapsed_days = sql("EXTRACT(DAY FROM elapsed_days)")
    # elapsed_days = as.integer(elapsed_days)
  ) %>% 
  arrange(customer_id, sales_ymd)

db_result %>% collect()

#...............................................................................

db_result %>% show_query(cte = TRUE)

query = sql("
WITH receipt_distinct AS (
  SELECT DISTINCT 
    customer_id, sales_ymd
  FROM receipt
)
SELECT 
  c.customer_id, 
  r.sales_ymd, 
  c.application_date,
  EXTRACT(DAY FROM (
      STRPTIME(CAST(r.sales_ymd AS TEXT), '%Y%m%d') - 
        STRPTIME(c.application_date, '%Y%m%d')
    )
  ) AS elapsed_days
FROM 
  receipt_distinct r
INNER JOIN 
  customer c
USING (customer_id)
ORDER BY 
  customer_id, sales_ymd
"
)
query %>% db_get_query(con)

query = sql("

"
)
query %>% db_get_query(con)


# A tibble: 32,411 × 4
#    customer_id    sales_ymd application_date elapsed_days
#    <chr>              <int> <chr>                   <dbl>
#  1 CS001113000004  20190308 20151105                 1219
#  2 CS001114000005  20180503 20160412                  751
#  3 CS001114000005  20190731 20160412                 1205
#  4 CS001115000010  20171228 20150417                  986
#  5 CS001115000010  20180701 20150417                 1171
#  ...

# sqlight
query = sql("
select
  r.customer_id, 
  r.sales_ymd, 
  c.application_date, 
  julianday(
    substr(r.sales_ymd, 1, 4) || '-' || substr(r.sales_ymd, 5, 2) || '-' || substr(r.sales_ymd, 7, 2)
  )
  - julianday(
    substr(c.application_date, 1, 4) || '-' || substr(c.application_date, 5, 2) || '-' || substr(c.application_date, 7, 2)
  ) as elapsed_days
from
  (
    select distinct customer_id, sales_ymd from receipt
  ) as r 
inner join customer as c
  USING (customer_id)
ORDER BY
  customer_id, sales_ymd
"
)
query %>% db_get_query(con)

#-------------------------------------------------------------------------------
# R-071 ------------
# レシート明細データ（df_receipt）の売上日（sales_ymd）に対し、顧客データ（df_customer）の
# 会員申込日（application_date）からの経過月数を計算し、顧客ID（customer_id）、売上日、
# 会員申込日とともに10件表示せよ
# （sales_ymdは数値、application_dateは文字列でデータを保持している点に注意）。
# 1ヶ月未満は切り捨てること。

# 会員申込日からの経過月数の計算

# 売上日に対し、顧客の会員申込日までの経過月数を計算し、顧客ID・売上日・会員申込日とともに表示する問題です。

# level: 2

# tag: 
# 日付処理, データ型変換, 重複データ処理, データ結合

# sample.1
df_receipt %>%
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    df_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    elapsed_months = lubridate::interval(
      strptime(application_date, "%Y%m%d"), 
      strptime(as.character(sales_ymd), "%Y%m%d")
    ) %>% 
    lubridate::time_length("month") %>% 
    floor() %>% 
    as.integer()
  ) %>% 
  arrange(customer_id, sales_ymd) %>% 
  head(10)

# A tibble: 10 × 4
#    customer_id    sales_ymd application_date elapsed_months
#    <chr>              <int> <chr>                     <int>
#  1 CS001113000004  20190308 20151105                     40
#  2 CS001114000005  20180503 20160412                     24
#  3 CS001114000005  20190731 20160412                     39
#  4 CS001115000010  20171228 20150417                     32
#  5 CS001115000010  20180701 20150417                     38
#  6 CS001115000010  20190405 20150417                     47
#  7 CS001205000004  20170914 20160615                     14
#  8 CS001205000004  20180821 20160615                     26
#  9 CS001205000004  20180904 20160615                     26
# 10 CS001205000004  20190312 20160615                     32

# sample.2
df_receipt %>%
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    df_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    elapsed_months = 
    lubridate::interval(
      strptime(application_date, "%Y%m%d"), 
      strptime(as.character(sales_ymd), "%Y%m%d")
    ) %/% 
    months(1L) %>% 
    as.integer()
  ) %>%
  arrange(customer_id, sales_ymd) %>% 
  head(10)  

# A tibble: 10 × 4
#    customer_id    sales_ymd application_date elapsed_months
#    <chr>              <int> <chr>                     <int>
#  1 CS001113000004  20190308 20151105                     40
#  2 CS001114000005  20180503 20160412                     24
#  3 CS001114000005  20190731 20160412                     39
#  4 CS001115000010  20171228 20150417                     32
#  5 CS001115000010  20180701 20150417                     38
#  6 CS001115000010  20190405 20150417                     47
#  7 CS001205000004  20170914 20160615                     14
#  8 CS001205000004  20180821 20160615                     26
#  9 CS001205000004  20180904 20160615                     26
# 10 CS001205000004  20190312 20160615                     32

#...............................................................................
# dplyr が認識できない関数をエラーにする 
options(dplyr.strict_sql = FALSE)

db_result = db_receipt %>% 
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    db_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    sales_ymd_d = STRPTIME(as.character(sales_ymd), "%Y%m%d"), 
    application_date_d = STRPTIME(application_date, "%Y%m%d")
  ) %>% 
  mutate(
    elapsed_months = DATEDIFF('month', application_date_d, sales_ymd_d)
    # elapsed_years = DATEDIFF('year', application_date_d, sales_ymd_d)
  ) %>% 
  select(-c(sales_ymd_d, application_date_d)) %>% 
  arrange(customer_id, sales_ymd) %>% 
  head(10)

# DATEDIFF('year', start_date, end_date) が年の境界を超えた回数を数えるため、28 ヶ月の差を 3 年とカウントする

db_result %>% collect()

#    customer_id    sales_ymd application_date elapsed_months
#    <chr>              <int> <chr>                     <dbl>
#  1 CS001113000004  20190308 20151105                     40
#  2 CS001114000005  20180503 20160412                     25
#  3 CS001114000005  20190731 20160412                     39
#  4 CS001115000010  20171228 20150417                     32
#  5 CS001115000010  20180701 20150417                     39
#  6 CS001115000010  20190405 20150417                     48
#  7 CS001205000004  20170914 20160615                     15
#  8 CS001205000004  20180821 20160615                     26
#  9 CS001205000004  20180904 20160615                     27
# 10 CS001205000004  20190312 20160615                     33

db_result = db_receipt %>% 
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    db_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    sales_ymd_d = STRPTIME(as.character(sales_ymd), "%Y%m%d"), 
    application_date_d = STRPTIME(application_date, "%Y%m%d")
  ) %>% 
  mutate(
    time_age = AGE(sales_ymd_d, application_date_d)
  ) %>% 
  mutate(
    elapsed_months = 
      lubridate::year(time_age) * 12 + lubridate::month(time_age)
  ) %>% 
  select(-c(sales_ymd_d, application_date_d, time_age)) %>% 
  arrange(customer_id, sales_ymd) %>% 
  head(10)

db_result %>% collect()

# A tibble: 10 × 4
#    customer_id    sales_ymd application_date elapsed_months
#    <chr>              <int> <chr>                     <dbl>
#  1 CS001113000004  20190308 20151105                     40
#  2 CS001114000005  20180503 20160412                     24
#  3 CS001114000005  20190731 20160412                     39
#  4 CS001115000010  20171228 20150417                     32
#  5 CS001115000010  20180701 20150417                     38
#  6 CS001115000010  20190405 20150417                     47
#  7 CS001205000004  20170914 20160615                     14
#  8 CS001205000004  20180821 20160615                     26
#  9 CS001205000004  20180904 20160615                     26
# 10 CS001205000004  20190312 20160615                     32

#...............................................................................

db_result %>% show_query(cte = TRUE)

query = sql("
WITH receipt_distinct AS (
  SELECT DISTINCT 
    customer_id, sales_ymd
  FROM 
    receipt
),
customer_with_age AS (
  SELECT 
    r.customer_id,
    r.sales_ymd,
    c.application_date,
    AGE(
      strptime(CAST(r.sales_ymd AS STRING), '%Y%m%d'),
      strptime(c.application_date, '%Y%m%d')
    ) AS time_age
  FROM 
    receipt_distinct r
  INNER JOIN 
    customer c 
  USING (customer_id)
)
SELECT
  customer_id,
  sales_ymd,
  application_date,
  EXTRACT(YEAR FROM time_age) * 12 + 
    EXTRACT(MONTH FROM time_age) AS elapsed_months
FROM 
  customer_with_age
ORDER BY 
  customer_id, sales_ymd
LIMIT 10
"
)
query %>% db_get_query(con)

#-------------------------------------------------------------------------------
# R-074 ------------

# レシート明細データ（df_receipt）の売上日（sales_ymd）に対し、当該週の月曜日からの経過日数を
# 計算し、売上日、直前の月曜日付とともに10件表示せよ（sales_ymd は数値でデータを保持している点に注意）。

# 月曜日から売上日までの経過日数の計算

# 売上日から当該週の月曜日までの経過日数を計算し、売上日・直前の月曜日とともに表示する問題です。

# level: 2

# tag: 
# 日付処理, データ型変換

# 経過日数を計算し、月曜日を求める
df_result = df_receipt %>% 
  mutate(
    sales_date = 
      strptime(as.character(sales_ymd), "%Y%m%d") %>% 
      lubridate::as_date()
  ) %>% 
  mutate(
    # 曜日 : 月曜日を週の始まりとする
    dow = wday(sales_date, week_start = 1L) %>% as.integer(), 
    # 月曜日からの経過日数を計算
    elapsed_days = dow - 1L, 
    # その週の月曜日の日付を計算
    monday_ymd = sales_date - days(elapsed_days)
  ) %>%
  select(sales_date, elapsed_days, monday_ymd) %>%
  head(10)

df_result

# A tibble: 10 × 3
#    sales_date elapsed_days monday_ymd
#    <date>            <int> <date>    
#  1 2018-11-03            5 2018-10-29
#  2 2018-11-18            6 2018-11-12
#  3 2017-07-12            2 2017-07-10
#  4 2019-02-05            1 2019-02-04
#  5 2018-08-21            1 2018-08-20
#  6 2019-06-05            2 2019-06-03
#  7 2018-12-05            2 2018-12-03
#  8 2019-09-22            6 2019-09-16
#  9 2017-05-04            3 2017-05-01
# 10 2019-10-10            3 2019-10-07

#................................................
# 以下はブログに書かない

# sample.2
# 月曜日を求め、経過日数を計算
df_result = df_receipt %>% 
  mutate(
    sales_date = 
      strptime(as.character(sales_ymd), "%Y%m%d") %>% 
      lubridate::as_date()
  ) %>% 
  mutate(
    # 曜日 : 月曜日を週の始まりとする
    dow = wday(sales_date, week_start = 1L), 
    # その週の月曜日の日付を計算
    monday_ymd = sales_date - days(dow - 1L), 
    # 月曜日からの経過日数を計算
    elapsed_days = 
      lubridate::interval(monday_ymd, sales_date) %>% 
      lubridate::time_length("day") %>% 
      as.integer()
  ) %>%
  select(sales_ymd, sales_date, monday_ymd, elapsed_days) %>%
  head(10)

df_result

# A tibble: 10 × 4
#    sales_ymd sales_date monday_ymd elapsed_days
#        <int> <date>     <date>            <dbl>
#  1  20181103 2018-11-03 2018-10-29            5
#  2  20181118 2018-11-18 2018-11-12            6
#  3  20170712 2017-07-12 2017-07-10            2
#  4  20190205 2019-02-05 2019-02-04            1
#  5  20180821 2018-08-21 2018-08-20            1
#  6  20190605 2019-06-05 2019-06-03            2
#  7  20181205 2018-12-05 2018-12-03            2
#  8  20190922 2019-09-22 2019-09-16            6
#  9  20170504 2017-05-04 2017-05-01            3
# 10  20191010 2019-10-10 2019-10-07            3

# sample.3
# 月曜日を求め、経過日数を計算
df_result = df_receipt %>% 
  mutate(
    sales_date = 
      strptime(as.character(sales_ymd), "%Y%m%d") %>% 
      lubridate::as_date()
  ) %>% 
  mutate(
    # 曜日 : 月曜日を週の始まりとする
    dow = wday(sales_date, week_start = 1L),  
    # その週の月曜日の日付を計算
    monday_ymd = sales_date - days(dow - 1L),
    # 月曜日からの経過日数を計算
    elapsed_days = 
      lubridate::interval(monday_ymd, sales_date) %/% 
      lubridate::days(1L) %>% 
      as.integer()
  ) %>%
  select(sales_ymd, sales_date, monday_ymd, elapsed_days) %>%
  head(10)

df_result
# A tibble: 10 × 4
#    sales_ymd sales_date monday_ymd elapsed_days
#        <int> <date>     <date>            <int>
#  1  20181103 2018-11-03 2018-10-29            5
#  2  20181118 2018-11-18 2018-11-12            6
#  3  20170712 2017-07-12 2017-07-10            2
#  4  20190205 2019-02-05 2019-02-04            1
#  5  20180821 2018-08-21 2018-08-20            1
#  ...

# difftime()
# 月曜日を求め、経過日数を計算
df_result = df_receipt %>% 
  mutate(
    sales_date = 
      strptime(as.character(sales_ymd), "%Y%m%d") %>% 
      lubridate::as_date()
  ) %>% 
  mutate(
    # 曜日 : 月曜日を週の始まりとする
    dow = wday(sales_date, week_start = 1L),  
    # その週の月曜日の日付を計算
    monday_ymd = sales_date - days(dow - 1L),
    # 月曜日からの経過日数を計算
    elapsed_days = 
      difftime(
        sales_date, 
        monday_ymd, 
        units = "days"
      ) %>% 
      as.integer()
  ) %>%
  select(sales_ymd, sales_date, monday_ymd, elapsed_days) %>%
  head(10)

df_result

# A tibble: 10 × 4
#    sales_ymd sales_date monday_ymd elapsed_days
#        <int> <date>     <date>            <int>
#  1  20181103 2018-11-03 2018-10-29            5
#  2  20181118 2018-11-18 2018-11-12            6
#  3  20170712 2017-07-12 2017-07-10            2
#  4  20190205 2019-02-05 2019-02-04            1
#  5  20180821 2018-08-21 2018-08-20            1
#  6  20190605 2019-06-05 2019-06-03            2
#  7  20181205 2018-12-05 2018-12-03            2
#  8  20190922 2019-09-22 2019-09-16            6
#  9  20170504 2017-05-04 2017-05-01            3
# 10  20191010 2019-10-10 2019-10-07            3

#...............................................................................

db_result = db_receipt %>% 
  mutate(
    sales_date = 
      STRPTIME(as.character(sales_ymd), "%Y%m%d") %>% 
      lubridate::as_date()
  ) %>% 
  mutate(
    # 曜日 : 月曜日を週の始まりとする
    dow = wday(sales_date, week_start = 1L) %>% as.integer(), 
    # 月曜日からの経過日数を計算
    elapsed_days = dow - 1L, 
    # その週の月曜日の日付を計算
    monday_ymd = (sales_date - days(elapsed_days)) %>% lubridate::as_date()
  ) %>%
  select(sales_date, elapsed_days, monday_ymd) %>%
  head(10)

db_result %>% collect()

d = db_result %>% collect()
identical(df_result, d)
arsenal::comparedf(df_result, d)
arsenal::comparedf(df_result, d) %>% summary()

#...............................................................................

db_result %>% show_query(cte = TRUE)

query = sql("
WITH q01 AS (
  SELECT
    receipt.*,
    CAST(STRPTIME(CAST(sales_ymd AS TEXT), '%Y%m%d') AS DATE) AS sales_date
  FROM receipt
),
q02 AS (
  SELECT
    q01.*,
    CAST(EXTRACT('dow' FROM CAST(sales_date AS DATE) + 6) + 1 AS INTEGER) AS dow
  FROM q01
),
q03 AS (
  SELECT q01.*, dow - 1 AS elapsed_days
  FROM q02 q01
)
SELECT
  sales_date, 
  elapsed_days, 
  CAST((sales_date - TO_DAYS(CAST(elapsed_days AS INTEGER))) AS DATE) AS monday_ymd
FROM q03 q01
LIMIT 10
"
)

d1 = query %>% db_get_query(con)

query = sql("
SELECT
  sales_date,
  CAST(
    EXTRACT('dow' FROM sales_date + 6) AS INTEGER
  ) AS elapsed_days,
  CAST(
    sales_date - TO_DAYS(elapsed_days) AS DATE
  ) AS monday_ymd
FROM (
  SELECT
    CAST(
      STRPTIME(CAST(sales_ymd AS TEXT), '%Y%m%d') AS DATE
    ) AS sales_date
  FROM receipt
)
LIMIT 10
"
)
query %>% db_get_query(con)

d2 = query %>% db_get_query(con)
identical(d1, d2)
identical(df_result, d2)
arsenal::comparedf(df_result, d2)
arsenal::comparedf(df_result, d2) %>% summary()

# A tibble: 10 × 3
#    sales_date elapsed_days monday_ymd
#    <date>            <int> <date>    
#  1 2018-11-03            5 2018-10-29
#  2 2018-11-18            6 2018-11-12
#  3 2017-07-12            2 2017-07-10
#  4 2019-02-05            1 2019-02-04
#  5 2018-08-21            1 2018-08-20
#  6 2019-06-05            2 2019-06-03
#  7 2018-12-05            2 2018-12-03
#  8 2019-09-22            6 2019-09-16
#  9 2017-05-04            3 2017-05-01
# 10 2019-10-10            3 2019-10-07

# 参考
query = sql("
SELECT 
  sales_date,
  DATE_TRUNC('week', sales_date) AS monday_ymd,
  DATE_DIFF('day', DATE_TRUNC('week', sales_date), sales_date) AS elapsed_days
FROM (
  SELECT 
    CAST(STRPTIME(CAST(sales_ymd AS STRING), '%Y%m%d') AS DATE) AS sales_date
  FROM receipt
) AS subquery
"
)

query %>% db_get_query(con)

#-------------------------------------------------------------------------------
# R-075 ------------
# 顧客データ（customer）からランダムに1%のデータを抽出し、先頭から10件表示せよ。

# 顧客データのランダムサンプリング
# 顧客データからランダムに 1% を抽出する問題です。

# level: 2

# tag: 
# 乱数, サンプリング, ランキング関数, ウィンドウ関数, フィルタリング

df_customer %>% 
  slice_sample(prop = 0.01) %>% 
  withr::with_seed(14, .) %>% 
  select(customer_id, gender_cd, birth_day, age) %>% 
  head(10)

#...............................................................................

db_customer %>% 
  slice_sample(prop = 0.01) %>% 
  head(10)
# >
# Error in `slice_sample()`:
# ! Sampling by `prop` is not supported on database backends

db_customer %>% 
  slice_sample(n = 100) %>% 
  # slice_sample(n = 0.01 * n()) %>% 
  head(10)

#................................................
# シードを設定
dbExecute(con, "SELECT SETSEED(0.5)")

db_result = db_customer %>% 
  mutate(r = runif(n = n())) %>% 
  filter(r <= 0.01) %>% 
  select(customer_id, gender_cd, birth_day, age) %>% 
  head(10)

db_result %>% collect() %>% arrange(customer_id)

db_result %>% show_query()

#................................................
# シードを設定
dbExecute(con, "SELECT SETSEED(0.5)")
db_result = db_customer %>% 
  # mutate(prank = percent_rank(runif(n = n()))) %>% 
  mutate(r = runif(n = n())) %>% 
  mutate(prank = percent_rank(r)) %>% 
  filter(prank <= 0.01) %>% 
  select(customer_id, gender_cd, birth_day, age) %>% 
  head(10)

db_result %>% collect() %>% arrange(customer_id)

# A tibble: 10 × 4
#    customer_id    gender_cd birth_day    age
#    <chr>          <chr>     <date>     <int>
#  1 CS003315000484 1         1988-03-16    31
#  2 CS003513000181 1         1964-05-26    54
#  3 CS005503000015 0         1966-07-09    52
#  4 CS015513000041 1         1962-09-01    56
#  5 CS024313000089 1         1985-07-25    33
#  6 CS027512000028 1         1967-12-15    51
#  7 CS027715000080 1         1943-12-15    75
#  8 CS031312000076 1         1980-04-05    38
#  9 CS035515000219 1         1960-06-29    58
# 10 CS051313000008 1         1982-08-28    36

#................................................

# ランダムな行番号を生成する方法
# 列の一部を出力
dbExecute(con, "SELECT SETSEED(0.5)")
db_result = db_customer %>% 
  mutate(r = runif(n = n())) %>% 
  mutate(
    row_num = row_number(r)
  ) %>% 
  filter(row_num <= 0.01 * n()) %>% 
  # select(customer_id, customer_name, gender_cd, gender, r, row_num, cnt) %>% 
  select(customer_id, gender_cd, gender, birth_day, age) %>% 
  head(10)

db_result %>% collect() %>% arrange(customer_id)

# A tibble: 10 × 5
#    customer_id    gender_cd gender birth_day    age
#    <chr>          <chr>     <chr>  <date>     <int>
#  1 CS003315000484 1         女性   1988-03-16    31
#  2 CS003513000181 1         女性   1964-05-26    54
#  3 CS005503000015 0         男性   1966-07-09    52
#  4 CS015513000041 1         女性   1962-09-01    56
#  5 CS024313000089 1         女性   1985-07-25    33
#  6 CS027512000028 1         女性   1967-12-15    51
#  7 CS027715000080 1         女性   1943-12-15    75
#  8 CS031312000076 1         女性   1980-04-05    38
#  9 CS035515000219 1         女性   1960-06-29    58
# 10 CS051313000008 1         女性   1982-08-28    36

db_result %>% collect()
db_result %>% collect() %>% arrange(customer_id)

#...............................................................................

# PERCENT_RANK() を使用

dbExecute(con, "SELECT SETSEED(0.5)")
db_result = db_customer %>% 
  mutate(r = runif(n = n())) %>% 
  mutate(prank = percent_rank(r)) %>% 
  filter(prank <= 0.01) %>% 
  select(customer_id, gender_cd, birth_day, age)

db_result %>% show_query(cte = TRUE)

# set seed すること!!!
query = sql("
SELECT SETSEED(0.5);
WITH rand_customers AS (
  SELECT 
    *, 
    RANDOM() AS rand
  FROM 
    customer
),
ranked_customers AS (
  SELECT
    *,
    PERCENT_RANK() OVER (ORDER BY rand) AS prank
  FROM 
    rand_customers
)
SELECT 
  customer_id, 
  gender_cd, 
  gender, 
  birth_day, 
  age
FROM 
  ranked_customers
WHERE 
  prank <= 0.01
"
)

query %>% db_get_query(con) %>% arrange(customer_id)

# A tibble: 220 × 5
#    customer_id    gender_cd gender birth_day    age
#    <chr>          <chr>     <chr>  <date>     <int>
#  1 CS001305000005 0         男性   1979-01-02    40
#  2 CS001312000261 1         女性   1987-04-07    31
#  3 CS001313000376 1         女性   1980-03-09    39
#  4 CS001315000444 1         女性   1987-04-01    31
#  5 CS001512000180 1         女性   1963-03-26    56
#  6 CS001512000275 1         女性   1960-08-09    58
#  7 CS001513000084 1         女性   1962-07-01    56
#  8 CS001513000355 1         女性   1959-07-14    59
#  9 CS001515000118 1         女性   1967-08-07    51
# 10 CS001515000568 1         女性   1959-07-28    59

#................................................
# 以下はブログに書かない
# 再現性が確保されない方法

# set seed すること!!!
query = sql("
SELECT SETSEED(0.5);
WITH ranked_customers AS (
  SELECT 
    customer_id, gender_cd, gender, birth_day, age,
    PERCENT_RANK() OVER (ORDER BY RANDOM()) AS prank
  FROM customer
)
SELECT *
FROM ranked_customers
WHERE prank <= 0.01
"
)

query %>% db_get_query(con) %>% arrange(customer_id)

# A tibble: 220 × 6
#    customer_id    gender_cd gender birth_day    age      prank
#    <chr>          <chr>     <chr>  <date>     <int>      <dbl>
#  1 CS001305000005 0         男性   1979-01-02    40 0.0045972 
#  2 CS001312000261 1         女性   1987-04-07    31 0.0055985 
#  3 CS001313000376 1         女性   1980-03-09    39 0.0069640 
#  4 CS001315000444 1         女性   1987-04-01    31 0.0085116 
#  5 CS001512000180 1         女性   1963-03-26    56 0.0092399 
#  6 CS001512000275 1         女性   1960-08-09    58 0.0028220 
#  7 CS001513000084 1         女性   1962-07-01    56 0.0063268 
#  8 CS001513000355 1         女性   1959-07-14    59 0.00086482
#  9 CS001515000118 1         女性   1967-08-07    51 0.0018207 
# 10 CS001515000568 1         女性   1959-07-28    59 0.0015931 

#................................................
# 以下はブログに書かない

# set seed すること!!!
query = sql("
SELECT SETSEED(0.5);
WITH q01 AS (
  SELECT customer.*, RANDOM() AS r
  FROM customer
),
q02 AS (
  SELECT
    q01.*,
    ROW_NUMBER() OVER (ORDER BY r) AS row_num,
    COUNT(*) OVER () AS cnt
  FROM q01
)
SELECT customer_id, gender_cd, gender, birth_day, age
FROM q02 q01
WHERE (row_num <= (0.01 * cnt))
-- チェック用
-- order by row_num desc
LIMIT 10
"
)
query %>% db_get_query(con)

query %>% db_get_query(con) %>% arrange(customer_id)

#-------------------------------------------------------------------------------
# R-076 ------------
# 顧客データ（customer）から性別コード（gender_cd）の割合に基づきランダムに10%のデータを層化抽出し、
# 性別コードごとに件数を集計せよ。

# 性別コードに基づく層化抽出と集計
# 性別コードの割合に基づき、顧客データからランダムに 10% を層化抽出する問題です。

# level: 3

# tag: 
# 乱数, サンプリング, ランキング関数, ウィンドウ関数, グループ化, フィルタリング

# 層別サンプリング
df_customer %>% 
  rsample::initial_split(prop = 0.1, strata = "gender_cd") %>% 
  withr::with_seed(14, .) %>% 
  training() %>% 
  count(gender_cd)

# slice_sample
df_customer %>% 
  slice_sample(prop = 0.1, by = gender_cd) %>% 
  withr::with_seed(14, .) %>% 
  count(gender_cd)

# 参考: グループ分割
# 同じ postal_cd が双方の分割データに含まれないように分割
df_customer %>% 
  rsample::group_initial_split(group = postal_cd, prop = 0.1) %>% 
  withr::with_seed(14, .) %>% 
  training() %>% 
  count(postal_cd)

#...............................................................................
# ランダムな行番号を生成する方法
# 列の一部を出力

db_customer %>% 
  select(gender_cd) %>% 
  group_by(gender_cd) %>% 
  mutate(r = runif(n = n())) %>% 
  ungroup() %>% 
  my_show_query(TRUE)

# 上記コードは、group_by(gender_cd) が効かない
# SELECT gender_cd, RANDOM() AS r
# FROM customer

#................................................

# ランダムシードを設定
con %>% dbExecute("SELECT SETSEED(0.5)")

# 上位10%を選択
db_result = db_customer %>%
  mutate(rand = runif(n = n())) %>% 
  group_by(gender_cd) %>%
  mutate(prank = percent_rank(rand)) %>%
  filter(prank <= 0.1) %>% 
  ungroup()

db_result %>% arrange(customer_id) %>% collect()

# A tibble: 2,199 × 13
#    customer_id    customer_name gender_cd gender birth_day    age postal_cd address        
#    <chr>          <chr>         <chr>     <chr>  <date>     <int> <chr>     <chr>          
#  1 CS001114000005 安 里穂       1         女性   2004-11-22    14 144-0056  東京都大田区西…
#  2 CS001205000006 福士 明       0         男性   1993-06-12    25 144-0056  東京都大田区西…
#  3 CS001211000018 西脇 真悠子   1         女性   1997-01-16    22 212-0058  神奈川県川崎市…
#  4 CS001212000045 保坂 ヒカル   1         女性   1994-10-27    24 210-0822  神奈川県川崎市…
#  5 CS001212000099 宇野 郁恵     1         女性   1990-03-28    29 210-0025  神奈川県川崎市…
#  ...

# db_result %>% select(customer_id, rand, prank) %>% arrange(rand) %>% collect()

db_result %>% count(gender_cd)

#   gender_cd     n
#       <int> <dbl>
# 1         0   299
# 2         1  1792
# 3         9   108

#................................................
# 以下は、ブログには掲載しない

# customer をランダムに並び替えてからグループ内で順番付けをする

# ランダムシードを設定
con %>% dbExecute("SELECT SETSEED(0.5)")

db_result = db_customer %>%
  mutate(rand = runif(n = n())) %>% 
  group_by(gender_cd) %>%
  mutate(
    row_num = row_number(rand), # グループ内で順番付け
    cnt = n()
  ) %>%
  # 上位10%を選択
  filter(row_num <= 0.1 * cnt) %>% 
  ungroup()

db_result %>% arrange(customer_id) %>% collect()

db_result %>% count(gender_cd) %>% collect()

#   gender_cd     n
#   <chr>     <dbl>
# 1 0           298
# 2 1          1791
# 3 9           107

db_result %>% show_query(cte = TRUE)

#................................................

db_result
db_result %>% collect() %>% head(30)
db_result %>% collect() %>% tail(30)
db_result %>% collect() %>% count(gender_cd)
db_result %>% collect() %>% group_by(gender_cd) %>% reframe(x = quantile(rand))

df_customer %>% arrange(customer_id)

#...............................................................................

con %>% dbExecute("SELECT SETSEED(0.5)")

db_result = db_customer %>%
  mutate(rand = runif(n = n())) %>% 
  group_by(gender_cd) %>%
  mutate(prank = percent_rank(rand)) %>%
  filter(prank <= 0.1) # 上位10%を選択

db_result %>% count(gender_cd) %>% show_query(cte = TRUE)

# 以下、前者の方が再現性が高く、パフォーマンス的にも安定する可能性がある

query = sql("
SELECT SETSEED(0.5);
WITH rand_customers AS (
  SELECT 
    *, 
    RANDOM() AS rand
  FROM 
    customer
),
ranked_customers AS (
  SELECT
    *,
    PERCENT_RANK() OVER (
      partition by gender_cd ORDER BY rand
    ) AS prank
  FROM 
    rand_customers
)
SELECT 
  gender_cd, 
  COUNT(*) AS n
FROM 
  ranked_customers
WHERE 
  prank <= 0.1
GROUP BY 
  gender_cd
"
)

query %>% db_get_query(con)

#................................................
# 以下の方法だと、再現性が確保されない

query = sql("
SELECT SETSEED(0.5);
WITH customer_random AS (
  SELECT
    *, 
    PERCENT_RANK() OVER (partition by gender_cd ORDER BY RANDOM()) AS prank
  FROM customer
)
SELECT *
FROM customer_random
WHERE prank <= 0.1
"
)
query %>% db_get_query(con) %>% arrange(customer_id)
query %>% db_get_query(con) %>% count(gender_cd)
df_customer %>% count(gender_cd)

query = sql("
SELECT SETSEED(0.5);
WITH customer_random AS (
  SELECT
    *, 
    PERCENT_RANK() OVER (partition by gender_cd ORDER BY RANDOM()) AS prank
  FROM customer
)
SELECT gender_cd, COUNT(*) AS n
FROM customer_random
WHERE prank <= 0.1
GROUP BY gender_cd
"
)

query %>% db_get_query(con)

#...............................................................................
# 以下の方法はブログには書かない

query = sql("
WITH q01 AS (
  SELECT customer.*, RANDOM() AS r
  FROM customer
),
q02 AS (
  SELECT
    q01.*,
    ROW_NUMBER() OVER (PARTITION BY gender_cd ORDER BY r) AS row_num,
    COUNT(*) OVER (PARTITION BY gender_cd) AS cnt
  FROM q01
),
q03 AS (
  SELECT q01.*
  FROM q02 q01
  WHERE (row_num <= (0.1 * cnt))
)
SELECT gender_cd, COUNT(*) AS n
FROM q03 q01
GROUP BY gender_cd
"
)
query %>% db_get_query(con)

query = sql("
SELECT SETSEED(0.5);
WITH cusotmer_r AS (
  SELECT customer.*, RANDOM() AS r
  FROM customer
),
cusotmer_random AS (
  SELECT
    *,
    ROW_NUMBER() OVER (win ORDER BY r) AS row_num,
    COUNT(*) OVER win AS cnt
  FROM cusotmer_r
  WINDOW win as (partition by gender_cd)
)
SELECT gender_cd, COUNT(*) AS n
FROM cusotmer_random
WHERE (row_num <= (0.1 * cnt))
GROUP BY gender_cd
"
)
query %>% db_get_query(con)

# A tibble: 3 × 2
#   gender_cd     n
#       <int> <dbl>
# 1         0   298
# 2         1  1791
# 3         9   107

#-------------------------------------------------------------------------------
# R-078 ------------
# レシート明細データ（df_receipt）の売上金額（amount）を顧客単位に合計し、合計した売上金額の外れ値を抽出せよ。
# ただし、顧客IDが"Z"から始まるのものは非会員を表すため、除外して計算すること。
# なお、ここでは外れ値を第1四分位と第3四分位の差であるIQRを用いて、「第1四分位数-1.5×IQR」を下回るもの、
# または「第3四分位数+1.5×IQR」を超えるものとする。結果は10件表示せよ。

# 売上金額の外れ値を四分位数を用いて抽出

# 非会員を除外した上で、顧客ごとの売上金額合計を算出し、四分位数を用いて外れ値を抽出する問題です。

# level: 2

# tag: 
# 外れ値・異常値, 統計量, 欠損値処理, 集約関数, ウィンドウ関数, パターンマッチング, グループ化, フィルタリング, データ結合

# 計算の対象となる amount が全て NA の場合、sum_amount は NA になる。
df_result = df_receipt %>% 
  filter(!str_detect(customer_id, "^Z")) %>% 
  summarise(
    sum_amount = sum(amount, na.rm = TRUE), 
    .by = customer_id
  ) %>% 
  drop_na(sum_amount) %>% 
  mutate(
    stat1 = 
      quantile(sum_amount, 0.25) - 1.5 * IQR(sum_amount), 
    stat2 = 
      quantile(sum_amount, 0.75) + 1.5 * IQR(sum_amount)
  ) %>% 
  filter(
    sum_amount < stat1 | sum_amount > stat2
  ) %>% 
  select(customer_id, sum_amount) %>% 
  arrange(desc(sum_amount), customer_id) %>% 
  head(10)

df_result

# A tibble: 10 × 2
#    customer_id    sum_amount
#    <chr>               <dbl>
#  1 CS017415000097      23086
#  2 CS015415000185      20153
#  3 CS031414000051      19202
#  4 CS028415000007      19127
#  5 CS001605000009      18925
#  6 CS010214000010      18585
#  7 CS006515000023      18372
#  8 CS016415000141      18372
#  9 CS011414000106      18338
# 10 CS038415000104      17847

#...............................................................................
# R-055: PERCENTILE_CONT() はウィンドウ関数 (OVER ()) として使えない!
db_receipt %>% 
  mutate(
    p25 = quantile(amount, 0.25, na.rm = TRUE)
  )

#................................................

# 計算の対象となる amount が全て NA の場合、sum_amount は NA になる。

db_sales_amount = db_receipt %>% 
  # filter(!str_detect(customer_id, "^Z")) %>% 
  filter(!(customer_id %LIKE% "Z%")) %>% 
  summarise(sum_amount = sum(amount), .by = customer_id) %>% 
  filter(!is.na(sum_amount))

#    customer_id    sum_amount
#    <chr>               <dbl>
#  1 CS028414000014       6222
#  2 CS040415000178       6149
#  3 CS040414000073       4715
#  4 CS012515000143       5659
#  5 CS018205000001       8739
#  ...

stats_amount = db_sales_amount %>% 
  summarise(
    p25 = quantile(sum_amount, 0.25), 
    p75 = quantile(sum_amount, 0.75)
  )

stats_amount
#      p25    p75
#    <dbl>  <dbl>
# 1 548.25 3649.8

db_result = db_sales_amount %>% 
  cross_join(stats_amount) %>% 
  mutate(
    stat1 = p25 - 1.5 * (p75 - p25), 
    stat2 = p75 + 1.5 * (p75 - p25)
  ) %>% 
  filter(
    sum_amount < stat1 | sum_amount > stat2
  ) %>% 
  select(customer_id, sum_amount) %>% 
  arrange(desc(sum_amount), customer_id) %>% 
  head(10)

db_result %>% collect()

identical(df_result, db_result %>% collect())

#...............................................................................

db_result %>% show_query(cte = TRUE)

query = sql("
WITH customer_sales AS (
  SELECT 
    customer_id, 
    SUM(amount) AS sum_amount
  FROM 
    receipt
  WHERE 
    customer_id NOT LIKE 'Z%'
  GROUP BY 
    customer_id
  HAVING 
    SUM(amount) IS NOT NULL
),
percentiles AS (
  SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY sum_amount) AS p25,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY sum_amount) AS p75
  FROM 
    customer_sales
)
SELECT 
  customer_id, 
  sum_amount
FROM 
  customer_sales
CROSS JOIN 
  percentiles
WHERE 
  sum_amount < p25 - 1.5 * (p75 - p25)
  OR sum_amount > p75 + 1.5 * (p75 - p25)
ORDER BY 
  sum_amount DESC, customer_id
LIMIT 10
"
)

query %>% db_get_query(con)
identical(df_result, query %>% db_get_query(con))

#-------------------------------------------------------------------------------
# R-079 ------------
# 商品データ（product）の各項目に対し、欠損数を確認せよ。

# 商品データの欠損数の集計
# 商品データの各項目に対し、欠損数を確認する問題です。

# level: 1

# tag: 
# 欠損値処理, CASE式, 集約関数

df_product %>% skimr::skim()

# シンプルで計算コストが低く、パフォーマンスが良い
df_product %>% 
  summarise(
    across(everything(), ~ is.na(.x) %>% sum())
  )

# パフォーマンスは下がる
df_product %>% 
  summarise(
    across(everything(), ~ sum(if_else(is.na(.x), 1L, 0L)))
  )

# A tibble: 1 × 6
#   product_cd category_major_cd category_medium_cd category_small_cd unit_price unit_cost
#        <int>             <int>              <int>             <int>      <int>     <int>
# 1          0                 0                  0                 0          7         7

#...............................................................................

db_product %>% skimr::skim()

db_result = db_product %>% 
  summarise(
    across(everything(), ~ sum(if_else(is.na(.), 1L, 0L)))
  )

db_result %>% collect()

# A tibble: 1 × 6
#   product_cd category_major_cd category_medium_cd category_small_cd unit_price unit_cost
#        <dbl>             <dbl>              <dbl>             <dbl>      <dbl>     <dbl>
# 1          0                 0                  0                 0          7         7

#...............................................................................

db_result %>% show_query()

# sample.1
query = sql("
SELECT 
  SUM(
    CASE WHEN product_cd IS NULL THEN 1 ELSE 0 END
  ) AS product_cd,
  SUM(
    CASE WHEN category_major_cd IS NULL THEN 1 ELSE 0 END
  ) AS category_major_cd,
  SUM(
    CASE WHEN category_medium_cd IS NULL THEN 1 ELSE 0 END
  ) AS category_medium_cd,
  SUM(
    CASE WHEN category_small_cd IS NULL THEN 1 ELSE 0 END
  ) AS category_small_cd,
  SUM(
    CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END
  ) AS unit_price,
  SUM(
    CASE WHEN unit_cost IS NULL THEN 1 ELSE 0 END
  ) AS unit_cost
FROM 
  product
"
)
query %>% db_get_query(con)

# sample.2
# COUNT(*) は全行数をカウントし、COUNT(column_name) は NULL 以外の値をカウントするため、
# 差分を取ることで NULL の数を求められる。

query = sql("
SELECT 
  COUNT(*) - COUNT(product_cd) AS product_cd,
  COUNT(*) - COUNT(category_major_cd) AS category_major_cd,
  COUNT(*) - COUNT(category_medium_cd) AS category_medium_cd,
  COUNT(*) - COUNT(category_small_cd) AS category_small_cd,
  COUNT(*) - COUNT(unit_price) AS unit_price,
  COUNT(*) - COUNT(unit_cost) AS unit_cost
FROM 
  product
"
)
query %>% db_get_query(con)

#-------------------------------------------------------------------------------
# R-081 ------------
# 単価（unit_price）と原価（unit_cost）の欠損値について、それぞれの平均値で補完した新たな
# 商品データを作成せよ。
# なお、平均値については1円未満を丸めること（四捨五入または偶数への丸めで良い）。
# 補完実施後、各項目について欠損が生じていないことも確認すること。

# 単価と原価の欠損値を平均値で補完

# 単価と原価の欠損値を、それぞれの平均値で補完した商品データを作成する問題です。

# level: 2

# tag: 
# 欠損値処理, データ補完, 統計量, 集約関数, ウィンドウ関数, データ結合

df_product %>% skimr::skim()

# sample.1
df_result = df_product %>% 
  recipes::recipe() %>% 
  step_impute_mean(starts_with("unit_")) %>% 
  prep() %>% bake(new_data = NULL) %>% 
  mutate(across(starts_with("unit_"), ~ round(.x)))
# 確認
df_result %>% skimr::skim()

# sample.2
avg_price = mean(df_product$unit_price, na.rm = TRUE) %>% round()
avg_cost = mean(df_product$unit_cost, na.rm = TRUE) %>% round()
df_result2 = df_product %>% 
  tidyr::replace_na(
    list(unit_price = avg_price, unit_cost = avg_cost)
  )
# 確認
df_result2 %>% skimr::skim()

# avg_price, avg_cost の計算結果が正しいことも確認できる.

df_result2
rm(avg_price, avg_cost)

#................................................
# rows_patch()を使用する方法

df_stats = df_product %>% 
  mutate(
    unit_price = mean(unit_price, na.rm = TRUE) %>% round(), 
    unit_cost = mean(unit_cost, na.rm = TRUE) %>% round()
  ) %>% 
  select(product_cd, starts_with("unit_"))

df_stats
df_result3 = df_product %>% rows_patch(df_stats)
df_result3 %>% skimr::skim()
# df_product %>% skimr::skim()

df_result3
# A tibble: 10,030 × 6
#    product_cd category_major_cd category_medium_cd category_small_cd unit_price unit_cost
#    <chr>      <chr>             <chr>              <chr>                  <dbl>     <dbl>
#  1 P040101001 04                0401               040101                   198       149
#  2 P040101002 04                0401               040101                   218       164
#  3 P040101003 04                0401               040101                   230       173
#  4 P040101004 04                0401               040101                   248       186
#  5 P040101005 04                0401               040101                   268       201
#  6 P040101006 04                0401               040101                   298       224
#  ...

#...............................................................................

# sample.1
# rows_patch
db_stats = db_product %>% 
  mutate(
    unit_price = mean(unit_price) %>% round(), 
    unit_cost = mean(unit_cost) %>% round()
  ) %>% 
  select(product_cd, starts_with("unit_"))

db_result = db_product %>% rows_patch(db_stats, unmatched = "ignore")
db_result %>% collect()
db_result %>% skimr::skim()

#................................................

# sample.2
db_result = db_product %>% 
  mutate(
    avg_price = mean(unit_price) %>% round(), 
    avg_cost = mean(unit_cost) %>% round()
  ) %>% 
  mutate(
    unit_price = coalesce(unit_price, avg_price), 
    unit_cost = coalesce(unit_cost, avg_cost)
  ) %>% 
  select(-starts_with("avg"))
  # select(starts_with("unit"), starts_with("avg"))

# 確認
db_result %>% skimr::skim()

#................................................
# sample.3
db_unit_avg = db_product %>% 
  summarise(
    avg_price = mean(unit_price) %>% round(), 
    avg_cost = mean(unit_cost) %>% round()
  )

db_result = db_product %>% 
  cross_join(db_unit_avg) %>% 
  mutate(
    unit_price = coalesce(unit_price, avg_price), 
    unit_cost = coalesce(unit_cost, avg_cost)
  ) %>% 
  select(-starts_with("avg"))
  # select(starts_with("unit"), starts_with("avg"))

# 確認
db_result %>% skimr::skim()

#...............................................................................

# sample.1

db_result %>% show_query(cte = TRUE)

# ROUND_EVEN を ROUND に変更する.

query = sql("
WITH product_with_avg AS (
  SELECT
    product.*,
    ROUND(AVG(unit_price) OVER (), 0) AS avg_price,
    ROUND(AVG(unit_cost) OVER (), 0) AS avg_cost
  FROM product
)
SELECT
  product_cd,
  category_major_cd,
  category_medium_cd,
  category_small_cd,
  COALESCE(unit_price, avg_price) AS unit_price,
  COALESCE(unit_cost, avg_cost) AS unit_cost
FROM product_with_avg
"
)
query %>% db_get_query(con)

#................................................
# sample.2

query = sql("
WITH unit_avg AS (
  SELECT
    ROUND(AVG(unit_price), 0) AS avg_price,
    ROUND(AVG(unit_cost), 0) AS avg_cost
  FROM product
)
SELECT
  product_cd,
  category_major_cd,
  category_medium_cd,
  category_small_cd,
  COALESCE(unit_price, avg_price) AS unit_price,
  COALESCE(unit_cost, avg_cost) AS unit_cost
FROM 
  product
CROSS JOIN 
  unit_avg
"
)
query %>% db_get_query(con)

# 確認
query %>% db_get_query(con) %>% skimr::skim()

# A tibble: 10,030 × 6
#    product_cd category_major_cd category_medium_cd category_small_cd unit_price unit_cost
#    <chr>      <chr>             <chr>              <chr>                  <dbl>     <dbl>
#  1 P040101001 04                0401               040101                   198       149
#  2 P040101002 04                0401               040101                   218       164
#  3 P040101003 04                0401               040101                   230       173
#  4 P040101004 04                0401               040101                   248       186
#  5 P040101005 04                0401               040101                   268       201
#  6 P040101006 04                0401               040101                   298       224
#  7 P040101007 04                0401               040101                   338       254
#  8 P040101008 04                0401               040101                   420       315
#  ...

#...............................................................................

## 各商品のカテゴリ小区分コード（category_small_cd）ごとに算出した平均値で補完する場合
query = sql("
with prod as (
  select
    product_cd, 
    category_small_cd, 
    unit_price, 
    unit_cost, 
    AVG(unit_price) OVER (partition by category_small_cd) as avg_price, 
    AVG(unit_cost) OVER (partition by category_small_cd) as avg_cost
  from
    product
)
select
  product_cd, 
  category_small_cd, 
  ROUND(COALESCE(unit_price, avg_price)) as unit_price, 
  ROUND(COALESCE(unit_cost, avg_cost)) as unit_cost, 
  avg_price, 
  avg_cost
from
  prod
-- チェック用
-- where unit_price IS NULL
"
)
query %>% db_get_query(con)

# A tibble: 10,030 × 6
#    product_cd category_small_cd unit_price unit_cost mean_price mean_cost
#    <chr>      <chr>                  <dbl>     <dbl>      <dbl>     <dbl>
#  1 P040101001 040101                   198       149     329.6     247.5 
#  2 P040101002 040101                   218       164     329.6     247.5 
#  3 P040101003 040101                   230       173     329.6     247.5 
#  4 P040101004 040101                   248       186     329.6     247.5 
#  5 P040101005 040101                   268       201     329.6     247.5 
#  ...

#-------------------------------------------------------------------------------
# R-083 ------------
# 単価（unit_price）と原価（unit_cost）の欠損値について、各商品のカテゴリ小区分コード
# （category_small_cd）
# ごとに算出した中央値で補完した新たな商品データを作成せよ。なお、中央値については1円未満を丸めること
# （四捨五入または偶数への丸めで良い）。補完実施後、各項目について欠損が生じていないことも確認すること。

# 商品カテゴリごとに単価と原価の欠損値を中央値で補完
# 単価と原価の欠損値を、カテゴリ小区分コードごとの中央値で補完した商品データを作成する問題です。

# level: 2

# tag: 
# 欠損値処理, データ補完, 統計量, 集約関数, ウィンドウ関数, グループ化, データ結合

df_result = df_product %>% 
  mutate(
    median_price = median(unit_price, na.rm = TRUE) %>% round(), 
    median_cost = median(unit_cost, na.rm = TRUE) %>% round(), 
    .by = category_small_cd
  ) %>% 
  mutate(
    unit_price = coalesce(unit_price, median_price), 
    unit_cost = coalesce(unit_cost, median_cost)
  ) %>% 
  select(-starts_with("median"))

df_result
# 確認
df_result %>% skimr::skim()

# A tibble: 10,030 × 6
#    product_cd category_major_cd category_medium_cd category_small_cd unit_price unit_cost
#    <chr>      <chr>             <chr>              <chr>                  <dbl>     <dbl>
#  1 P040101001 04                0401               040101                   198       149
#  2 P040101002 04                0401               040101                   218       164
#  3 P040101003 04                0401               040101                   230       173
#  4 P040101004 04                0401               040101                   248       186
#  5 P040101005 04                0401               040101                   268       201
#  6 P040101006 04                0401               040101                   298       224
#  7 P040101007 04                0401               040101                   338       254
#  ...

#...............................................................................

db_unit_median = db_product %>% 
  summarise(
    median_price = median(unit_price) %>% round(), 
    median_cost = median(unit_cost) %>% round(), 
    .by = "category_small_cd"
  )

db_unit_median

db_result = db_product %>% 
  inner_join(
    db_unit_median, 
    by = "category_small_cd"
  ) %>% 
  mutate(
    unit_price = coalesce(unit_price, median_price), 
    unit_cost = coalesce(unit_cost, median_cost)
  ) %>% 
  select(-starts_with("median"))

db_result %>% collect()
# 確認
db_result %>% skimr::skim()

#...............................................................................

db_result %>% show_query(cte = TRUE)

# ROUND_EVEN を ROUND に変更する.

query = sql("
WITH unit_median AS (
  SELECT
    category_small_cd,
    ROUND(
      PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY unit_price)
    ) AS median_price,
    ROUND(
      PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY unit_cost)
    ) AS median_cost
  FROM 
    product
  GROUP BY 
    category_small_cd
)
SELECT
  product_cd,
  category_major_cd,
  category_medium_cd,
  category_small_cd,
  COALESCE(unit_price, median_price) AS unit_price,
  COALESCE(unit_cost, median_cost) AS unit_cost
FROM 
  product
INNER JOIN 
  unit_median
USING (category_small_cd)
"
)

query %>% db_get_query(con)
# 確認
query %>% db_get_query(con) %>% skimr::skim()

#-------------------------------------------------------------------------------
# R-084 ------------
# 顧客データ（customer）の全顧客に対して全期間の売上金額に占める2019年売上金額の割合を計算し、
# 新たなデータを作成せよ。
# ただし、売上実績がない場合は0として扱うこと。そして計算した割合が0超のものを抽出し、結果を10件表示せよ。
# また、作成したデータに欠損が存在しないことを確認せよ。

# 顧客ごとに2019年売上金額の割合の計算

# 顧客ごとに、総売上金額に対する2019年の売上金額の割合を計算する問題です。

# level: 3

# tag: 
# 日付処理, CASE式, データ型変換, 集約関数, グループ化, フィルタリング, データ結合, 

# df_receipt %>% select(customer_id) %>% 
#   anti_join(df_customer, by = "customer_id") %>% 
#   distinct()
# 
#   customer_id   
#   <chr>         
# 1 ZZ000000000000

df_sales_rate = df_receipt %>% 
  select(customer_id, sales_ymd, amount) %>% 
  mutate(
    sales_year = sales_ymd %>% 
      as.character() %>% 
      strptime("%Y%m%d") %>% 
      lubridate::year()
  ) %>% 
  right_join(
    df_customer %>% select(customer_id), 
    by = "customer_id"
  ) %>% 
  mutate(
    amount_2019 = if_else(sales_year == 2019L, amount, 0.0)
  ) %>% 
  summarise(
    across(starts_with("amount"), 
    ~ sum(.x, na.rm = TRUE), 
    .names = "sales_{.col}"), 
    .by = customer_id
  ) %>% 
  mutate(
    sales_rate = if_else(
      sales_amount == 0.0, 
      0.0, 
      sales_amount_2019 / sales_amount
    )
  ) %>% 
  arrange(customer_id)

df_sales_rate

df_sales_rate %>% skimr::skim()

df_sales_rate %>% 
  summarise(
    across(everything(), ~ is.na(.x) %>% sum())
  )

df_sales_rate %>% 
  filter(sales_rate > 0.0) %>% 
  arrange(customer_id) %>% 
  head(10)

# A tibble: 10 × 4
#    customer_id    sales_amount sales_amount_2019 sales_rate
#    <chr>                 <dbl>             <dbl>      <dbl>
#  1 CS001113000004         1298              1298    1      
#  2 CS001114000005          626               188    0.30032
#  3 CS001115000010         3044               578    0.18988
#  4 CS001205000004         1988               702    0.35312
#  5 CS001205000006         3337               486    0.14564
#  6 CS001211000025          456               456    1      
#  7 CS001212000070          456               456    1      
#  8 CS001214000009         4685               664    0.14173
#  9 CS001214000017         4132              2962    0.71684
# 10 CS001214000048         2374              1889    0.79570

#...............................................................................

# 以下の箇所を追記する:
# sales_amount = coalesce(sales_amount, 0.0), 
# sales_amount_2019 = coalesce(sales_amount_2019, 0.0), 

db_sales_rate = db_receipt %>% 
  select(customer_id, sales_ymd, amount) %>% 
  mutate(
    sales_year = sales_ymd %>% 
      as.character() %>% 
      strptime("%Y%m%d") %>% 
      lubridate::year()
  ) %>% 
  right_join(
    db_customer %>% select(customer_id), 
    by = "customer_id"
  ) %>% 
  mutate(
    amount_2019 = if_else(sales_year == 2019L, amount, 0.0)
  ) %>% 
  summarise(
    across(starts_with("amount"), 
    ~ sum(.x), 
    .names = "sales_{.col}"), 
    .by = customer_id
  ) %>% 
  mutate(
    sales_amount = coalesce(sales_amount, 0.0), 
    sales_amount_2019 = coalesce(sales_amount_2019, 0.0), 
    sales_rate = if_else(
      sales_amount == 0.0, 
      0.0, 
      sales_amount_2019 / sales_amount
    )
  )

db_sales_rate %>% collect()

db_sales_rate %>% 
  filter(sales_rate > 0.0) %>% 
  arrange(customer_id) %>% 
  head(10) %>% 
  collect()

db_sales_rate %>% skimr::skim()

db_sales_rate %>% 
  summarise(
    across(everything(), ~ sum(if_else(is.na(.), 1L, 0L)))
  ) %>% 
  collect()

#...............................................................................

db_sales_rate %>% show_query(cte = TRUE)

query = sql("
WITH sales_data AS (
  SELECT
    customer_id,
    sales_ymd,
    amount,
    EXTRACT(
      year FROM strptime(CAST(sales_ymd AS TEXT), '%Y%m%d')
    ) AS sales_year
  FROM receipt
),
customer_sales AS (
  SELECT 
    customer.customer_id, 
    sales_ymd, 
    amount, 
    sales_year
  FROM 
    sales_data
  RIGHT JOIN 
    customer 
  USING (customer_id)
),
sales_with_2019 AS (
  SELECT
    *,
    CASE 
      WHEN sales_year = 2019 THEN amount ELSE 0.0 
    END AS amount_2019
  FROM 
    customer_sales
),
aggregated_sales AS (
  SELECT
    customer_id,
    COALESCE(SUM(amount), 0.0) AS sales_amount,
    COALESCE(SUM(amount_2019), 0.0) AS sales_amount_2019
  FROM 
    sales_with_2019
  GROUP 
    BY customer_id
)
SELECT
  *,
  CASE 
    WHEN sales_amount = 0.0 THEN 0.0 
    ELSE sales_amount_2019 / sales_amount 
  END AS sales_rate
FROM 
  aggregated_sales
"
)
query %>% db_get_query(con)

query %>% db_get_query(con) %>% skimr::skim()

#...............................................................................
con %>% dbExecute("DROP TABLE IF EXISTS cust_sales_rate")

query = sql("
CREATE TABLE cust_sales_rate AS 
WITH sales_data AS (
  SELECT
    customer_id,
    sales_ymd,
    amount,
    EXTRACT(
      year FROM strptime(CAST(sales_ymd AS TEXT), '%Y%m%d')
    ) AS sales_year
  FROM receipt
),
customer_sales AS (
  SELECT 
    customer.customer_id, 
    sales_ymd, 
    amount, 
    sales_year
  FROM 
    sales_data
  RIGHT JOIN 
    customer 
  USING (customer_id)
),
sales_with_2019 AS (
  SELECT
    *,
    CASE 
      WHEN sales_year = 2019 THEN amount ELSE 0.0 
    END AS amount_2019
  FROM 
    customer_sales
),
aggregated_sales AS (
  SELECT
    customer_id,
    COALESCE(SUM(amount), 0.0) AS sales_amount,
    COALESCE(SUM(amount_2019), 0.0) AS sales_amount_2019
  FROM 
    sales_with_2019
  GROUP 
    BY customer_id
)
SELECT
  *,
  CASE 
    WHEN sales_amount = 0.0 THEN 0.0 
    ELSE sales_amount_2019 / sales_amount 
  END AS sales_rate
FROM 
  aggregated_sales
"
)
con %>% dbExecute(q)
con %>% dbListTables()

query = sql("
SELECT * FROM cust_sales_rate
WHERE sales_rate > 0
ORDER BY customer_id
LIMIT 10
"
)
query %>% db_get_query(con)

# A tibble: 10 × 4
#    customer_id    sales_amount sales_amount_2019 sales_rate
#    <chr>                 <dbl>             <dbl>      <dbl>
#  1 CS001113000004         1298              1298    1      
#  2 CS001114000005          626               188    0.30032
#  3 CS001115000010         3044               578    0.18988
#  4 CS001205000004         1988               702    0.35312
#  5 CS001205000006         3337               486    0.14564
#  6 CS001211000025          456               456    1      
#  7 CS001212000070          456               456    1      
#  8 CS001214000009         4685               664    0.14173
#  9 CS001214000017         4132              2962    0.71684
# 10 CS001214000048         2374              1889    0.79570

query = sql("
SELECT 
  COUNT(*) - COUNT(sales_amount) AS sales_amount,
  COUNT(*) - COUNT(sales_amount_2019) AS sales_amount_2019,
  COUNT(*) - COUNT(sales_rate) AS sales_rate
FROM 
  cust_sales_rate
"
)
query %>% db_get_query(con)

# A tibble: 1 × 3
#   sales_amount sales_amount_2019 sales_rate
#          <dbl>             <dbl>      <dbl>
# 1            0                 0          0

#................................................
# インデックスを追加
query = sql("
CREATE UNIQUE INDEX idx_customer_id ON cust_sales_rate (customer_id)
"
)
con %>% dbExecute(q)
con %>% dbGetQuery("PRAGMA index_list(cust_sales_rate)")
#   seq            name unique origin partial
# 1   0 idx_customer_id      1      c       0

#-------------------------------------------------------------------------------
# R-087 ------------
# 顧客データ（customer）では、異なる店舗での申込みなどにより同一顧客が複数登録されている。
# 名前（customer_name）と郵便番号（postal_cd）が同じ顧客は同一顧客とみなして1顧客1レコードとなるように
# 名寄せした名寄顧客データを作成し、顧客データの件数、名寄顧客データの件数、重複数を算出せよ。
# ただし、同一顧客に対しては売上金額合計が最も高いものを残し、売上金額合計が同一もしくは売上実績がない顧客
# については顧客ID（customer_id）の番号が小さいものを残すこととする。

# 顧客データの名寄せと統合名寄IDの付与

# R-088 を含めての設問の概要

# 1. **顧客データの名寄せ**  
#    - 名前と郵便番号が同じ顧客を同一顧客とみなし、1顧客1レコードにする。  
#    - 売上金額合計が最も高い顧客を優先し、同額の場合は顧客IDが小さいものを残す。  
# 
# 2. **統合名寄IDの付与**  
#    - 顧客データに統合名寄IDを付与する。  
#    - 統合名寄IDのルール：  
#      - 重複のない顧客 → 顧客IDをそのまま使用  
#      - 重複している顧客 → 名寄せ顧客データの顧客IDを使用  

# level: 4

# tag: 
# 名寄せ, ランキング関数, 集約関数, ウィンドウ関数, 欠損値処理, CASE式, グループ化, データ結合

# R-088 も合わせての解答
# 重複のある顧客について簡単に確認できるようにする

df_amount = df_receipt %>% 
  summarise(sum_amount = sum(amount), .by = customer_id)

vars = c("customer_name", "postal_cd")

df_cust = df_customer %>% 
  left_join(df_amount, by = "customer_id") %>% 
  mutate(sum_amount = coalesce(sum_amount, 0.0)) %>% 
  group_by(across(!!vars)) %>% 
  # mutate(
  #   rank = row_number(tibble(desc(sum_amount), customer_id)), 
  #   n = n()
  # ) %>% 
  arrange(desc(sum_amount), customer_id) %>% 
  mutate(
    rank = row_number(), 
    n = n()
  ) %>% 
  mutate(
    integration_id = max(if_else(rank == 1L, customer_id, "")), 
    .before = 1
  ) %>% 
  ungroup()
  # arrange(across(!!vars), rank)

df_cust %>% glimpse()
df_cust %>% collect()

# for check
df_cust %>% 
  select(integration_id, customer_id, !!vars, sum_amount, rank, n) %>% 
  filter(n > 1) %>% 
  arrange(across(!!vars), rank) %>% 
  collect() %>% 
  head(20)

# A tibble: 20 × 7
#    integration_id customer_id    customer_name postal_cd sum_amount  rank     n
#    <chr>          <chr>          <chr>         <chr>          <dbl> <int> <int>
#  1 CS001515000422 CS001515000422 久野 みゆき   144-0052        1173     1     2
#  2 CS001515000422 CS016712000025 久野 みゆき   144-0052           0     2     2
#  3 CS038214000037 CS038214000037 今 充則       246-0001           0     1     2
#  4 CS038214000037 CS040601000007 今 充則       246-0001           0     2     2
#  5 CS001515000561 CS001515000561 伴 芽以       144-0051        2283     1     2
#  6 CS001515000561 CS004712000149 伴 芽以       144-0051           0     2     2
#  7 CS002215000052 CS002215000052 前田 美紀     185-0022        1002     1     2
#  8 CS002215000052 CS002615000172 前田 美紀     185-0022           0     2     2
#  9 CS017414000126 CS017414000126 原 優         166-0003        1497     1     2
# 10 CS017414000126 CS018413000015 原 優         166-0003           0     2     2
# ...
# 19 CS028414000005 CS028414000005 小市 礼子     185-0013        8323     1     2
# 20 CS028414000005 CS002815000025 小市 礼子     185-0013        1158     2     2

# 名寄顧客データ
df_customer_u = df_cust %>% 
  filter(rank == 1L) %>% 
  select(-c(sum_amount, rank, n))

# 名寄顧客データ
df_customer_u = df_cust %>% 
  filter(rank == 1L) %>% 
  select(-c(integration_id, sum_amount, rank, n))

df_customer_u %>% glimpse()

# 顧客データに統合名寄IDを付与したデータを作成する (R-088)
df_customer_n = df_customer %>% 
  inner_join(
    df_cust %>% select(integration_id, customer_id), 
    by = "customer_id"
  ) %>% 
  relocate(integration_id, .before = 1L)

df_customer_n %>% glimpse()
df_customer_n

# 顧客データの件数、名寄顧客データの件数、重複数
df_customer_n %>% 
  summarise(
    n_all = n(), 
    n_unique = n_distinct(integration_id)
  ) %>% 
  mutate(diff = n_all - n_unique)

#   n_all n_unique  diff
#   <int>    <int> <int>
# 1 21971    21941    30

tibble::tribble(
  ~name, ~count, 
  "顧客データの件数", nrow(df_customer), 
  "名寄顧客データの件数", nrow(df_customer_u), 
  "重複数", nrow(df_customer) - nrow(df_customer_u)
)

#   name                 count
#   <chr>                <int>
# 1 顧客データの件数     21971
# 2 名寄顧客データの件数 21941
# 3 重複数                  30

n.all = nrow(df_customer)
n.u = nrow(df_customer_u)
"顧客データの件数: %s\n名寄顧客データの件数: %s\n重複数: %s" %>% 
  sprintf(n.all, n.u, n.all - n.u) %>% cat()

# 顧客データの件数: 21971
# 名寄顧客データの件数: 21941
# 重複数: 30

#................................................
# row_number(tibble(desc(sum_amount), customer_id)) は時間がかかる
# d = df_customer %>% 
#   select(customer_id, customer_name, postal_cd) %>% 
#   left_join(df_amount, by = "customer_id") %>% 
#   mutate(sum_amount = coalesce(sum_amount, 0.0)) %>% 
#   mutate(
#     row = row_number(tibble(desc(sum_amount), customer_id)), 
#     .by = c(customer_name, postal_cd)
#   )

# d %>% filter(row > 1)

#...............................................................................
# dbplyr
db_amount = db_receipt %>% 
  summarise(sum_amount = sum(amount), .by = customer_id)

vars = c("customer_name", "postal_cd")
db_cust = db_customer %>% 
  left_join(db_amount, by = "customer_id") %>% 
  mutate(sum_amount = coalesce(sum_amount, 0.0)) %>% 
  group_by(across(!!vars)) %>% 
  mutate(
    rank = row_number(tibble(desc(sum_amount), customer_id)), 
    n = n()
  ) %>% 
  mutate(
    integration_id = max(if_else(rank == 1L, customer_id, "")), 
    .before = 1
  ) %>% 
  ungroup()
  # arrange(across(!!vars), rank)

db_cust %>% glimpse()
db_cust %>% collect()

# for check
db_cust %>% 
  select(integration_id, customer_id, !!vars, sum_amount, rank, n) %>% 
  filter(n > 1) %>% 
  arrange(across(!!vars), rank) %>% 
  collect() %>% 
  head(20)

#    integration_id customer_id    customer_name postal_cd sum_amount  rank     n
#    <chr>          <chr>          <chr>         <chr>          <dbl> <dbl> <dbl>
#  1 CS001515000422 CS001515000422 久野 みゆき   144-0052        1173     1     2
#  2 CS001515000422 CS016712000025 久野 みゆき   144-0052           0     2     2
#  3 CS038214000037 CS038214000037 今 充則       246-0001           0     1     2
#  4 CS038214000037 CS040601000007 今 充則       246-0001           0     2     2
#  5 CS001515000561 CS001515000561 伴 芽以       144-0051        2283     1     2
#  6 CS001515000561 CS004712000149 伴 芽以       144-0051           0     2     2
#  7 CS002215000052 CS002215000052 前田 美紀     185-0022        1002     1     2
#  8 CS002215000052 CS002615000172 前田 美紀     185-0022           0     2     2
#  9 CS017414000126 CS017414000126 原 優         166-0003        1497     1     2
# 10 CS017414000126 CS018413000015 原 優         166-0003           0     2     2
# 11 CS001412000304 CS001412000304 多部 あさみ   222-0032           0     1     2
# 12 CS001412000304 CS010413000041 多部 あさみ   222-0032           0     2     2
# 13 CS004315000058 CS004315000058 宇多田 文世   165-0027         490     1     2
# 14 CS004315000058 CS023403000036 宇多田 文世   165-0027           0     2     2
# 15 CS007315000087 CS007315000087 宇野 真悠子   285-0855           0     1     2
# 16 CS007315000087 CS007715000041 宇野 真悠子   285-0855           0     2     2
# 17 CS020515000002 CS020515000002 宮下 陽子     115-0053        4905     1     2
# 18 CS020515000002 CS003502000148 宮下 陽子     115-0053           0     2     2
# 19 CS028414000005 CS028414000005 小市 礼子     185-0013        8323     1     2
# 20 CS028414000005 CS002815000025 小市 礼子     185-0013        1158     2     2

# 名寄顧客データ
db_customer_u = db_cust %>% 
  filter(rank == 1L) %>% 
  select(-c(integration_id, sum_amount, rank, n))

db_customer_u %>% glimpse()
db_customer_u %>% collect()

#................................................
# 顧客データに統合名寄IDを付与したデータを作成する (R-088)
db_customer_n = db_customer %>% 
  inner_join(
    db_cust %>% select(integration_id, customer_id), 
    by = "customer_id"
  ) %>% 
  relocate(integration_id, .before = 1)

db_customer_n %>% glimpse()
db_customer_n %>% collect()

# 顧客データの件数、名寄顧客データの件数、重複数
db_customer_n %>% 
  summarise(
    n_all = n(), 
    n_unique = n_distinct(integration_id)
  ) %>% 
  mutate(diff = n_all - n_unique) %>% 
  collect()

#   n_all n_unique  diff
#   <dbl>    <dbl> <dbl>
# 1 21971    21941    30

#...............................................................................

db_customer_n %>% show_query(cte = TRUE)

query = sql("
WITH sales_amount AS (
  SELECT 
    customer_id, 
    SUM(amount) AS sum_amount
  FROM receipt
  GROUP BY customer_id
),
cust_sales_amount AS (
  SELECT 
    *, 
    COALESCE(sum_amount, 0.0) AS sum_amount
  FROM customer
  LEFT JOIN sales_amount 
  USING (customer_id)
),
cust_sales_rank AS (
  SELECT
    *, 
    ROW_NUMBER() OVER (
      PARTITION BY customer_name, postal_cd 
      ORDER BY sum_amount DESC, customer_id
    ) AS rank
  FROM 
    cust_sales_amount
),
integration AS (
  SELECT
    MAX(
      CASE WHEN (rank = 1) THEN customer_id ELSE '' END
    ) OVER (
      PARTITION BY customer_name, postal_cd
    ) AS integration_id,
    customer_id
  FROM 
    cust_sales_rank
)
SELECT i.integration_id, c.*
FROM customer c
INNER JOIN integration i
USING (customer_id)
"
)

query %>% db_get_query(con)
query %>% db_get_query(con) %>% glimpse()

# A tibble: 21,971 × 12
#    integration_id customer_id  customer_name gender_cd gender birth_day    age postal_cd
#    <chr>          <chr>        <chr>         <chr>     <chr>  <date>     <int> <chr>    
#  1 CS021313000114 CS021313000… 大野 あや子   1         女性   1981-04-29    37 259-1113 
#  2 CS037613000071 CS037613000… 六角 雅彦     9         不明   1952-04-01    66 136-0076 
#  3 CS031415000172 CS031415000… 宇多田 貴美子 1         女性   1976-10-04    42 151-0053 
#  4 CS028811000001 CS028811000… 堀井 かおり   1         女性   1933-03-27    86 245-0016 
#  5 CS001215000145 CS001215000… 田崎 美紀     1         女性   1995-03-29    24 144-0055 
#  6 CS020401000016 CS020401000… 宮下 達士     0         男性   1974-09-15    44 174-0065 
#  7 CS015414000103 CS015414000… 奥野 陽子     1         女性   1977-08-09    41 136-0073 
#  8 CS029403000008 CS029403000… 釈 人志       0         男性   1973-08-17    45 279-0003 
#  9 CS015804000004 CS015804000… 松谷 米蔵     0         男性   1931-05-02    87 136-0073 
# 10 CS033513000180 CS033513000… 安斎 遥       1         女性   1962-07-11    56 241-0823 

#-------------------------------------------------------------------------------
# R-088 ------------
# 087で作成したデータを元に、顧客データに統合名寄IDを付与したデータを作成せよ。
# ただし、統合名寄IDは以下の仕様で付与するものとする。
# - 重複していない顧客：顧客ID（customer_id）を設定
# - 重複している顧客：前設問で抽出したレコードの顧客IDを設定
# 顧客IDのユニーク件数と、統合名寄IDのユニーク件数の差も確認すること。

d.integ = d.customer.u %>% select(-c(sum_amount, n)) %>% 
  rename(integration_id = customer_id)
d.integ

d.customer.n = customer %>% 
  inner_join(d.integ, join_by(customer_name, postal_cd)) %>% 
  select(integration_id, everything())

d.customer.n %>% summarise(n_all = n(), n_i = n_distinct(integration_id)) %>% 
  mutate(diff = n_all - n_i)
#   n_all   n_i  diff
#   <int> <int> <int>
# 1 21971 21941    30

#...............................................................................
query = sql("
with cust_0 as (
  select 
    c.customer_id, 
    c.customer_name, 
    c.postal_cd, 
    SUM(IFNULL(r.amount, 0)) as amount_all
  from 
    customer as c
  left join 
    receipt as r USING(customer_id)
  group by
    c.customer_id
), 
cust as (
  select
    *, 
    ROW_NUMBER() OVER (
      partition by customer_name, postal_cd
      order by amount_all DESC, customer_id
    ) as row, 
  count(*) over (partition by customer_name, postal_cd) as n -- チェック用
  from
    cust_0
  -- チェック用
  -- order by customer_name, postal_cd
)
select 
  MAX(case when row = 1 then customer_id else NULL end) 
    OVER (partition by customer_name, postal_cd) as integration_id, 
  *
from 
  cust
where n > 1 -- チェック用
order by 
  customer_name, postal_cd, row
"
)
query %>% db_get_query(con)

#    integration_id customer_id    customer_name postal_cd amount_all   row     n
#    <chr>          <chr>          <chr>         <chr>          <dbl> <int> <int>
#  1 CS001515000422 CS001515000422 久野 みゆき   144-0052        1173     1     2
#  2 CS001515000422 CS016712000025 久野 みゆき   144-0052           0     2     2
#  3 CS038214000037 CS038214000037 今 充則       246-0001           0     1     2
#  4 CS038214000037 CS040601000007 今 充則       246-0001           0     2     2
#  5 CS001515000561 CS001515000561 伴 芽以       144-0051        2283     1     2
#  6 CS001515000561 CS004712000149 伴 芽以       144-0051           0     2     2
#  7 CS002215000052 CS002215000052 前田 美紀     185-0022        1002     1     2
#  8 CS002215000052 CS002615000172 前田 美紀     185-0022           0     2     2
#  9 CS017414000126 CS017414000126 原 優         166-0003        1497     1     2
# 10 CS017414000126 CS018413000015 原 優         166-0003           0     2     2
# ...

#-------------------------------------------------------------------------------
# R-089 ------------
# 売上実績がある顧客を、予測モデル構築のため学習用データとテスト用データに分割したい。
# それぞれ 8:2 の割合でランダムにデータを分割せよ。

# 売上実績がある顧客データをランダムに分割
# 売上実績がある顧客データを 8:2 の割合でランダムに分割する問題です。

# level: 3

# tag: 
# データ分割, 乱数, 集合演算, ランキング関数, 集約関数, ウィンドウ関数, グループ化, フィルタリング, データ結合

df_sales_customer = df_receipt %>% 
  summarise(
    sum_amount = sum(amount), 
    .by = customer_id
  ) %>% 
  filter(sum_amount > 0.0) %>% 
  select(-sum_amount) %>% 
  inner_join(df_customer, by = "customer_id")

df_sales_customer

rsplit = df_sales_customer %>% 
  rsample::initial_split(prop = 0.8) %>% 
  withr::with_seed(14, .)

df_train = rsplit %>% training()
df_test = rsplit %>% testing()

df_train
# A tibble: 6,644 × 11
#    customer_id    customer_name gender_cd gender birth_day    age postal_cd address    
#    <chr>          <chr>         <chr>     <chr>  <date>     <int> <chr>     <chr>      
#  1 CS032415000205 細谷 真奈美   1         女性   1970-05-27    48 144-0056  東京都大田…
#  2 CS032513000167 大後 たまき   1         女性   1966-07-13    52 144-0054  東京都大田…
#  3 CS028415000226 小柳 まさみ   1         女性   1974-04-24    44 246-0021  神奈川県横…
#  4 CS029512000122 野口 季衣     1         女性   1964-07-12    54 279-0021  千葉県浦安…
#  5 CS010411000006 森口 めぐみ   1         女性   1973-12-26    45 223-0058  神奈川県横…
#  ...

df_test
#  A tibble: 1,662 × 11
#    customer_id    customer_name gender_cd gender birth_day    age postal_cd address    
#    <chr>          <chr>         <chr>     <chr>  <date>     <int> <chr>     <chr>      
#  1 CS008415000097 中田 光       1         女性   1971-05-21    47 182-0004  東京都調布…
#  2 CS028414000014 米倉 ヒカル   1         女性   1977-02-05    42 246-0023  神奈川県横…
#  3 CS003515000195 梅村 真奈美   1         女性   1963-05-31    55 182-0022  東京都調布…
#  4 CS027514000015 小宮 菜々美   1         女性   1960-08-20    58 251-0016  神奈川県藤…
#  5 CS025415000134 小杉 優       1         女性   1977-02-03    42 242-0024  神奈川県大…
#  ...

#...............................................................................
# ランダムな番号付けをする際、通常は
# percent_rank(runif(n = n()))
# を用いるが、再現性がない。
# そのため、
# 一意な識別子である customer_id を使い、SQL MD5関数(ハッシュ関数) でランダムな文字列を生成し、
# その辞書順によりランダムな番号付けをする

con %>% dbExecute("SELECT SETSEED(0.5)")

db_sales_customer = db_customer %>% 
  select(customer_id) %>% 
  inner_join(
    db_receipt %>% select(customer_id, amount), 
    by = "customer_id"
  ) %>% 
  summarise(
    sum_amount = sum(amount), 
    .by = customer_id
  ) %>% 
  filter(sum_amount > 0.0) %>% 
  mutate(rnum = row_number()) %>% 
  mutate(rand = runif(n = n())) %>% 
  mutate(prank = percent_rank(rand)) %>% 
  select(customer_id, prank)

db_sales_customer %>% 
  collect() %>% 
  arrange(customer_id)

# db_sales_customer %>% pull(prank) %>% sort() %>% diff()
# db_sales_customer %>% glimpse()
# db_sales_customer %>% collect()
# db_sales_customer %>% show_query(cte = TRUE)

# データベースに一時テーブルとして保存
db_sales_customer %>% 
  compute(
    name = "sales_customer", temporary = TRUE, overwrite = T
  )
# テーブルの確認
dbReadTable(con, "sales_customer") %>% glimpse()

# Rows: 8,306
# Columns: 2
# $ customer_id <chr> "CS011615000069", "CS027615000105", "CS033415000085", "CS003415000…
# $ prank       <dbl> 0.00000, 0.00012, 0.00024, 0.00036, 0.00048, 0.00060, 0.00072, 0.0…

# 保存したテーブルの参照を取得
db_sales_c = tbl(con, "sales_customer")

db_customer_train = db_sales_c %>% 
  filter(prank <= 0.8) %>% 
  select(-prank) %>% 
  inner_join(
    db_customer, 
    by = "customer_id"
  )

# db_customer_train
# db_customer_train %>% collect()
# db_customer_train %>% glimpse()
# db_customer_train %>% show_query(cte = TRUE)

# データベースに保存
db_customer_train %>% 
  compute(
    name = "customer_train", temporary = FALSE, overwrite = T
  )
# テーブルの確認
dbReadTable(con, "customer_train") %>% glimpse()
dbReadTable(con, "customer_train") %>% as_tibble()

# A tibble: 6,645 × 11
#    customer_id    customer_name gender_cd gender birth_day    age postal_cd address    
#    <chr>          <chr>         <chr>     <chr>  <date>     <int> <chr>     <chr>      
#  1 CS031415000172 宇多田 貴美子 1         女性   1976-10-04    42 151-0053  東京都渋谷…
#  2 CS001215000145 田崎 美紀     1         女性   1995-03-29    24 144-0055  東京都大田…
#  3 CS015414000103 奥野 陽子     1         女性   1977-08-09    41 136-0073  東京都江東…
#  4 CS033513000180 安斎 遥       1         女性   1962-07-11    56 241-0823  神奈川県横…
#  5 CS040412000191 川井 郁恵     1         女性   1977-01-05    42 226-0021  神奈川県横…
#  ...

# 保存したテーブルの参照を取得
db_train = tbl(con, "customer_train")

db_customer_test = db_sales_c %>% 
  select(-prank) %>% 
  inner_join(
    db_customer, 
    by = "customer_id"
  ) %>% 
  setdiff(db_train)

# db_customer_test
# db_customer_test %>% collect()
# db_customer_test %>% glimpse()
# db_customer_test %>% show_query(cte = TRUE)

# データベースに保存
db_customer_test %>% 
  compute(name = "customer_test", temporary = FALSE, overwrite = TRUE)
# テーブルの確認
dbReadTable(con, "customer_test") %>% glimpse()

dbReadTable(con, "customer_test") %>% as_tibble() %>% head(10)

# A tibble: 10 × 11
#    customer_id    customer_name gender_cd gender birth_day    age postal_cd address 
#   <chr>          <chr>         <chr>     <chr>  <date>     <int> <chr>   <chr> 
#  1 CS035513000025 松永 桃子     1         女性   1964-08-10    54 154-0015  東京都世田谷区桜新…
#  2 CS043415000028 市川 涼子     1         女性   1975-02-13    44 140-0013  東京都品川区南大井…
#  3 CS033415000074 相田 瞳       1         女性   1971-04-04    47 246-0023  神奈川県横浜市瀬谷…
#  4 CS018515000047 栗田 千夏     1         女性   1959-11-27    59 204-0013  東京都清瀬市上清戸…
#  5 CS005515000094 西本 遥       1         女性   1960-06-08    58 165-0032  東京都中野区鷺宮**…
#  6 CS004513000085 石井 夏空     1         女性   1962-05-11    56 166-0001  東京都杉並区阿佐谷…
#  7 CS013414000079 藤村 未來     1         女性   1973-06-04    45 275-0022  千葉県習志野市香澄…
#  8 CS011615000134 合田 花       1         女性   1950-10-03    68 223-0053  神奈川県横浜市港北…
#  9 CS003515000209 奥貫 璃子     1         女性   1961-06-12    57 201-0001  東京都狛江市西野川…
# 10 CS001512000448 倉田 貴美子   1         女性   1967-02-11    52 210-0813  神奈川県川崎市川崎…

# データベースに保存されているテーブルのリストを確認
con %>% dbListTables()
# [1] "category"       "customer"       "customer_test"  "customer_train" "geocode"       
# [6] "product"        "receipt"        "sales_customer" "store"   

#> sales_customer, customer_train, customer_test が作成されている
# sales_customer は一時テーブルなので、Rセッションが切れると消去される

#...............................................................................
# SQLクエリ

# MD5(customer_id)
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

query %>% db_get_query(con) %>% arrange(customer_id)
query %>% db_get_query(con) %>% glimpse()

#................................................

db_sales_customer %>% show_query(cte = TRUE)

# PERCENT_RANK()
query = sql("
SELECT SETSEED(0.5);
WITH q01 AS (
  SELECT customer_id
  FROM customer
  INNER JOIN receipt 
  USING (customer_id)
  GROUP BY customer_id
  HAVING SUM(amount) > 0.0
),
q02 AS (
  SELECT *, ROW_NUMBER() OVER () AS rnum
  FROM q01
),
q03 AS (
  SELECT *, RANDOM() AS rand
  FROM q02
)
SELECT
  customer_id, 
  PERCENT_RANK() OVER (ORDER BY rand) AS prank
FROM q03
"
)

query %>% db_get_query(con) %>% glimpse()
query %>% db_get_query(con) %>% arrange(customer_id)

# A tibble: 8,306 × 2
#    customer_id       prank
#    <chr>             <dbl>
#  1 CS001113000004 0.23998 
#  2 CS001114000005 0.43636 
#  3 CS001115000010 0.76123 
#  4 CS001205000004 0.54871 
#  5 CS001205000006 0.96677 
#  6 CS001211000025 0.15521 
#  7 CS001212000027 0.054425
#  8 CS001212000031 0.20554 
#  ...

#................................................

db_customer_train %>% show_query()

query = sql("
SELECT
  c.*
FROM
  sales_customer s
INNER JOIN 
  customer c
USING (customer_id)
WHERE 
  s.prank <= 0.8
"
)

query %>% db_get_query(con) %>% glimpse()

#................................................

db_customer_test %>% show_query()

query = sql("
SELECT
  c.*
FROM 
  sales_customer
INNER JOIN 
  customer c
USING (customer_id)
EXCEPT
  SELECT * FROM customer_train
"
)

query %>% db_get_query(con) %>% glimpse()

#...............................................................................
# テーブル作成

# PERCENT_RANK() OVER (ORDER BY MD5(customer_id))

con %>% dbExecute("DROP TABLE IF EXISTS sales_customer")

query = sql("
CREATE TEMP TABLE sales_customer AS 
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

con %>% dbExecute(q)
con %>% dbReadTable("sales_customer") %>% as_tibble() %>% arrange(customer_id)

#................................................

# PERCENT_RANK() OVER (ORDER BY rand)

con %>% dbExecute("DROP TABLE IF EXISTS sales_customer")

con %>% dbExecute("SELECT SETSEED(0.5)")

query = sql("
CREATE TEMP TABLE sales_customer AS 
WITH q01 AS (
  SELECT customer_id
  FROM customer
  INNER JOIN receipt 
  USING (customer_id)
  GROUP BY customer_id
  HAVING SUM(amount) > 0.0
),
q02 AS (
  SELECT *, ROW_NUMBER() OVER () AS rnum
  FROM q01
),
q03 AS (
  SELECT *, RANDOM() AS rand
  FROM q02
)
SELECT
  customer_id, 
  PERCENT_RANK() OVER (ORDER BY rand) AS prank
FROM q03
"
)

con %>% dbExecute(q)

con %>% dbReadTable("sales_customer") %>% as_tibble() %>% arrange(customer_id)

# A tibble: 8,306 × 2
#    customer_id       prank
#    <chr>             <dbl>
#  1 CS001113000004 0.23998 
#  2 CS001114000005 0.43636 
#  3 CS001115000010 0.76123 
#  4 CS001205000004 0.54871 
#  5 CS001205000006 0.96677 
#  ...

#...............................................................................

con %>% dbExecute("DROP TABLE IF EXISTS customer_train")

query = sql("
CREATE TABLE customer_train AS
SELECT
  c.*
FROM
  sales_customer s
INNER JOIN 
  customer c
USING (customer_id)
WHERE 
  s.prank <= 0.8
"
)
con %>% dbExecute(q)

con %>% dbReadTable("customer_train") %>% as_tibble() %>% arrange(customer_id)

#................................................

con %>% dbExecute("DROP TABLE IF EXISTS customer_test")

query = sql("
CREATE TABLE customer_test AS
SELECT
  c.*
FROM 
  sales_customer
INNER JOIN 
  customer c
USING (customer_id)
EXCEPT
  SELECT * FROM customer_train
"
)
con %>% dbExecute(q)

con %>% dbReadTable("customer_test") %>% as_tibble() %>% arrange(customer_id)

# データベースに保存されているテーブルのリストを確認
con %>% dbListTables()
# [1] "category"       "customer"       "customer_test"  "customer_train" "geocode"       
# [6] "product"        "receipt"        "sales_customer" "store"   

#> sales_customer は一時テーブルなので、Rセッションが切れると消去される

# テーブルの内容を確認

con %>% dbReadTable("customer_train") %>% as_tibble() %>% arrange(customer_id)

# A tibble: 6,645 × 11
#    customer_id    customer_name gender_cd gender birth_day    age postal_cd address    
#    <chr>          <chr>         <chr>     <chr>  <date>     <int> <chr>     <chr>      
#  1 CS001113000004 葛西 莉央     1         女性   2003-02-22    16 144-0056  東京都大田…
#  2 CS001114000005 安 里穂       1         女性   2004-11-22    14 144-0056  東京都大田…
#  3 CS001115000010 藤沢 涼       1         女性   2006-05-16    12 144-0056  東京都大田…
#  4 CS001205000004 奥山 秀隆     0         男性   1993-02-28    26 144-0056  東京都大田…
#  5 CS001205000006 福士 明       0         男性   1993-06-12    25 144-0056  東京都大田…
#  6 CS001211000025 河野 夏希     1         女性   1996-06-09    22 140-0013  東京都品川…
#  7 CS001212000031 平塚 恵望子   1         女性   1990-07-26    28 210-0007  神奈川県川…
#  8 CS001212000046 伊東 愛       1         女性   1994-09-08    24 210-0014  神奈川県川…
#  ...

con %>% dbReadTable("customer_test") %>% as_tibble() %>% arrange(customer_id)

# A tibble: 1,661 × 11
#    customer_id    customer_name gender_cd gender birth_day    age postal_cd address    
#    <chr>          <chr>         <chr>     <chr>  <date>     <int> <chr>     <chr>      
#  1 CS001205000006 福士 明       0         男性   1993-06-12    25 144-0056  東京都大田…
#  2 CS001212000046 伊東 愛       1         女性   1994-09-08    24 210-0014  神奈川県川…
#  3 CS001215000080 池谷 菜摘     1         女性   1994-04-28    24 144-0055  東京都大田…
#  4 CS001305000016 梅本 真一     0         男性   1982-02-18    37 144-0046  東京都大田…
#  5 CS001311000059 浜口 菜々美   1         女性   1985-04-22    33 212-0004  神奈川県川…
#  6 CS001314000051 生瀬 杏       1         女性   1978-12-23    40 144-0055  東京都大田…
#  7 CS001411000054 筒井 花       1         女性   1973-06-19    45 210-0007  神奈川県川…
#  8 CS001412000026 美木 彩華     1         女性   1973-01-04    46 212-0058  神奈川県川…
#  ...

#-------------------------------------------------------------------------------
# R-090 ------------
# レシート明細データ（receipt）は2017年1月1日〜2019年10月31日までのデータを有している。
# 売上金額（amount）を月次で集計し、学習用に12ヶ月、テスト用に6ヶ月の時系列モデル構築用データを3セット作成せよ。

# ブログに掲載しない

d = receipt %>% mutate(ym = my.date_format(sales_ymd, fmt2 = "%Y-%m")) %>% 
  summarise(sum_amount = sum(amount), .by = ym) %>% 
  arrange(ym)

# index: 1-18, 9-25, 16-34
obj.ro = d %>% rsample::rolling_origin(
    initial = 12, assess = 6, cumulative = FALSE, skip = 7
  )

obj.ro
obj.ro %>% get_rsplit(1) %>% training()
obj.ro %>% get_rsplit(1) %>% assessment()
obj.ro %>% get_rsplit(2) %>% training()
obj.ro %>% get_rsplit(2) %>% assessment()
obj.ro %>% get_rsplit(3) %>% training()
obj.ro %>% get_rsplit(3) %>% assessment()

#...............................................................................
# SQL向きではないため、やや強引に記載する（分割数が多くなる場合はSQLが長くなるため現実的ではない）
# 学習データ(0)とテストデータ(1)を区別するフラグを付与する

# 下準備として年月ごとに売上金額を集計し、連番を付与

con %>% dbExecute("DROP TABLE IF EXISTS ts_amount")

query = sql("
CREATE TEMP TABLE ts_amount AS
select
  SUBSTR(sales_ymd, 1, 6) as sales_ym, 
  SUM(amount) as sum_amount, 
  ROW_NUMBER() OVER (order by SUBSTR(sales_ymd, 1, 6)) as row
from
  receipt
group by 
  sales_ym
"
)
con %>% dbExecute(q)

con %>% dbReadTable("ts_amount") %>% as_tibble()

# A tibble: 34 × 3
#    sales_ym sum_amount    row
#    <chr>         <dbl> <int>
#  1 201701       902056     1
#  2 201702       764413     2
#  3 201703       962945     3
#  4 201704       847566     4
# ...
# 33 201909      1105696    33
# 34 201910      1143062    34

query = sql("
with lag_amount as (
select
  sales_ym, 
  sum_amount, 
  row, 
  LAG(row, 12) OVER (order by row) as rn
from
  ts_amount
)
select 
  *, 
  case 
    when rn <= 12 then 0 else 1
  end as test_flg
from
  lag_amount
where
  rn between 1 and 18
"
)
query %>% db_get_query(con)

# A tibble: 18 × 5
#    sales_ym sum_amount   row    rn test_flg
#    <chr>         <dbl> <int> <int>    <int>
#  1 201801       944509    13     1        0
#  2 201802       864128    14     2        0
#  3 201803       946588    15     3        0
#  4 201804       937099    16     4        0
#  5 201805      1004438    17     5        0
#  6 201806      1012329    18     6        0
#  7 201807      1058472    19     7        0
#  8 201808      1045793    20     8        0
#  9 201809       977114    21     9        0
# 10 201810      1069939    22    10        0
# 11 201811       967479    23    11        0
# 12 201812      1016425    24    12        0
# 13 201901      1064085    25    13        1
# 14 201902       959538    26    14        1
# 15 201903      1093753    27    15        1
# 16 201904      1044210    28    16        1
# 17 201905      1111985    29    17        1
# 18 201906      1089063    30    18        1

#-------------------------------------------------------------------------------
# R-091 ------------
# 顧客データ（customer）の各顧客に対し、売上実績がある顧客数と売上実績がない顧客数が 1:1 と
# なるようにアンダーサンプリングで抽出せよ。

# ブログに掲載しない

d = customer %>% 
  mutate(
    sales_flg = 
      if_else(customer_id %in% unique(receipt$customer_id), TRUE, FALSE) %>% 
      as.factor()
  )

d %>% glimpse()
library(recipes); library(themis)

d.cust = d %>% recipe() %>% 
  themis::step_downsample(sales_flg, under_ratio = 1.0, seed = 14) %>% 
  prep() %>% bake(new_data = NULL)

d.cust
d.cust %>% count(sales_flg)

#...............................................................................
d = customer %>% 
  mutate(
    sales_flg = if_else(customer_id %in% unique(receipt$customer_id), TRUE, FALSE)
  )

d.t = d %>% filter(sales_flg)
d.f = d %>% filter(!sales_flg)
n.t = d.t %>% nrow()
n.f = d.f %>% nrow()
if (n.t > n.f) {
  d.cust = d.t %>% slice_sample(n = n.f) %>% my_with_seed(14) %>% bind_rows(d.f)
} else {
  d.cust = d.f %>% slice_sample(n = n.t) %>% my_with_seed(14) %>% bind_rows(d.t)
}

d.cust %>% count(sales_flg)

#...............................................................................
con %>% dbExecute("DROP TABLE IF EXISTS down_sampling")

# SET SEED TO 0.25;

query = sql("
CREATE TABLE down_sampling AS
with pre_table_1 as (
  select 
    c.customer_id, 
    IFNULL(SUM(r.amount), 0) as sum_amount
  from
    customer as c
  left join receipt as r USING (customer_id)
  group by
    c.customer_id
), 
pre_table_2 as (
  select
    *, 
    case when sum_amount > 0 then 1 else 0 end as is_buy_flag, 
    case when sum_amount > 0 then 0 else 1 end as is_not_buy_flag
  from
    pre_table_1
), 
pre_table_3 as (
  select
    *, 
    row_number() over (partition by is_buy_flag order by random()) as row, 
    SUM(is_buy_flag) over () as n_buy, 
    SUM(is_not_buy_flag) over () as n_not_buy
  from 
    pre_table_2
)
select 
  *
from
  pre_table_3
where 
  row <= n_buy 
  and row <= n_not_buy
"
)
con %>% dbExecute(q)
con %>% dbReadTable("down_sampling") %>% as_tibble()

# A tibble: 16,612 × 7
#    customer_id    sum_amount is_buy_flag is_not_buy_flag   row n_buy n_not_buy
#    <chr>               <dbl>       <int>           <int> <int> <int>     <int>
#  1 CS018602000024          0           0               1     1  8306     13665
#  2 CS001713000232          0           0               1     2  8306     13665
#  3 CS003502000060          0           0               1     3  8306     13665
#  4 CS027712000043          0           0               1     4  8306     13665
#  5 CS007212000006          0           0               1     5  8306     13665
#  6 CS010303000005          0           0               1     6  8306     13665
#  ...

query = sql("
select is_buy_flag, count(*) as n from down_sampling group by is_buy_flag"
)
query %>% db_get_query(con)
#   is_buy_flag     n
#         <int> <int>
# 1           0  8306
# 2           1  8306

#-------------------------------------------------------------------------------

con %>% dbExecute("DROP TABLE IF EXISTS customer_std")

query = sql("
CREATE TABLE customer_std AS
  SELECT
    customer_id,
    customer_name,
    gender_cd,
    birth_day,
    age,
    postal_cd,
    application_store_cd,
    application_date,
    status_cd
  FROM
    customer
"
)
con %>% dbExecute(q)
con %>% dbReadTable("customer_std") %>% glimpse()

con %>% dbExecute("DROP TABLE IF EXISTS gender_std")
query = sql("
CREATE TABLE gender_std as
  select 
    distinct gender_cd, gender
  from
    customer
"
)
con %>% dbExecute(q)
con %>% dbReadTable("gender_std") %>% as_tibble()
#   gender_cd gender
#       <int> <chr> 
# 1         1 女性  
# 2         9 不明  
# 3         0 男性  

# ユニークインデックスを追加する
query = sql("
CREATE UNIQUE INDEX idx_customer_id ON customer_std (customer_id)
"
)
con %>% dbExecute(q)

"PRAGMA index_list(customer_std)" %>% dbGetQuery(con, .)
#   seq            name unique origin partial
# 1   0 idx_customer_id      1      c       0

query = sql("
CREATE UNIQUE INDEX idx_gender_cd ON gender_std (gender_cd)
"
)
con %>% dbExecute(q)

"PRAGMA index_list(gender_std)" %>% dbGetQuery(con, .)
#   seq          name unique origin partial
# 1   0 idx_gender_cd      1      c       0

#-------------------------------------------------------------------------------
