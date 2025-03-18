# DuckDB では SELECT SETSEED(0.2); を実行しても、その後の RANDOM() の結果が再現されない場合がある
# ことが確認されています。これは、DuckDB が RANDOM() のシード管理をセッションレベルではなくスレッドレベル
# で行っている可能性があるためです。
# つまり、同じセッションで SETSEED(x) を変更しても、新しい RANDOM() の値が更新されないことがあります。
# DuckDB の SETSEED(x) は、現在のスレッドに影響を与えるだけの可能性があるため、新しいセッションを開始
# すると異なる乱数が得られることがあります。

# 完全に再現可能な疑似乱数として HASH(customer_id) を使用できます。

# メリット
# HASH(customer_id) は DuckDB の 組み込み関数 なので、高速に計算できる。
# HASH(customer_id) の結果は 64ビット整数 なので、 / CAST(2^64 AS DOUBLE) で 0〜1の範囲に正規化 できる。
# DuckDB では HASH() は 一貫性がある（同じ customer_id に対して常に同じ値）。
# デメリット
# HASH(customer_id) は内部的に整数のハッシュを作るため、ハッシュ値の分布が完全に均一でない可能性もある（通常は問題にならない）。

# MD5(customer_id) の場合

# メリット
# MD5(customer_id) は 暗号学的ハッシュ関数 なので、分布がほぼ均一になる可能性が高い。
# 文字列ベースの customer_id でも問題なく処理できる（HASH() もサポートされているが、DuckDB の実装による影響を受けることがある）。
# どの DB でも MD5() は使える
# デメリット
# MD5(customer_id) の結果は 16バイトのバイナリ（または32文字の16進数文字列） になるため、ORDER BY 時に数値比較より遅くなる可能性がある。パフォーマンスが落ちる可能性がある。
# MD5(customer_id) は 暗号学的な用途向け であり、一般的なランダム化の用途ではオーバーヘッドがある。
# DuckDB において MD5() の最適化が他のデータベースほど進んでいない可能性がある。

# 結論
# おすすめ： HASH(customer_id) / CAST(2^64 AS DOUBLE)
# 理由
# 計算が速い（整数演算 + 数値正規化のみ）
# DuckDB で組み込み関数として最適化されている
# ORDER BY のパフォーマンスが良い（数値比較は文字列比較より高速）
# MD5(customer_id) を使うべきケース
# データのランダム性が極めて重要 で、HASH(customer_id) の内部実装に依存したくない場合。
# customer_id が数値ではなく文字列 であり、HASH() の適用が適切でない場合（ただし、DuckDB の HASH() は文字列にも対応しているため、問題になるケースは少ない）。

# 最終的な選択
# 通常は HASH(customer_id) / CAST(2^64 AS DOUBLE) が最適
# > パフォーマンスを重視するなら、各データベースの組み込みハッシュ関数を使う。
# MD5 は特別な理由がある場合のみ使用を検討
# > 移植性を重視する場合など。

db_tmp = db_customer %>% 
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
  select(customer_id) %>% 
  # mutate(md = MD5(customer_id)) %>% 
  mutate(
    # prank = percent_rank(md)
    prank = percent_rank(MD5(customer_id))
  )

db_tmp %>% collect() %>% arrange(customer_id)

#...............................................................................

query = sql("
SELECT 
  customer_id, 
  HASH(customer_id) / CAST(2^64 AS DOUBLE) AS rand_value
FROM 
  customer
"
)
query %>% db_get_query(con)
query %>% db_get_query(con) %>% pull(rand_value) %>% range()

query = sql("
SELECT 
  customer_id, 
  PERCENT_RANK() OVER (ORDER BY HASH(customer_id) / CAST(2^64 AS DOUBLE)) AS prank
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

query %>% db_get_query(con)

#...............................................................................

# 以下、db_customer_id の並び順が確保できない理由は、summarise() を使用した後にデータフレーム
# の順序が保証されないためです。

con %>% dbExecute("SELECT SETSEED(0.5);")
db_customer_id = db_customer %>% 
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
  select(customer_id)

db_customer_id %>% collect()

# 以下の(A),(B)の処理は、(A)は再現性を確保できないが、(B)は確保できる模様です。
# mutate(row = row_number()) を加えると確保できるのは何故？

# (A) の問題点: 再現性が確保できない理由
# (A) の場合、runif(n = n()) で一様乱数を発生させていますが、customer_id の順序は確定していません。
# collect() を呼び出すときに customer_id の順序が変わる可能性があるため、異なる実行ごとに runif() 
# によるランダム値の対応関係が変わることがあります。そのため、prank = percent_rank(r) の結果も
# 異なる可能性があります。

# (B) の再現性が確保できる理由
# (B) では、mutate(row = row_number()) によって、customer_id の並び順が確定します。row_number() はデータベースの処理結果に対して一貫した順序を保証するため、後続の runif(n = n()) で生成される乱数の並びが固定されます。その結果、prank = percent_rank(r) も毎回同じ結果になります。

# まとめ
# (A) の問題点: customer_id の順序が保証されていないため、runif() の結果が実行ごとに異なり、再現性がない。
# (B) の利点: row_number() により customer_id の順序が固定されるため、runif() の結果も安定し、再現性が確保される。
# このように、row_number() を使うことでランダム処理の再現性を担保できます。

# (A)
con %>% dbExecute("SELECT SETSEED(0.5);")

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
  select(customer_id) %>% 
  # mutate(row = row_number()) %>% 
  mutate(r = runif(n = n())) %>% 
  mutate(
    prank = percent_rank(r)
  )

db_sales_customer %>% arrange(customer_id)
db_sales_customer %>% collect() %>% arrange(customer_id)

# (B)
con %>% dbExecute("SELECT SETSEED(0.5);")

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
  select(customer_id) %>% 
  mutate(row = row_number()) %>% 
  mutate(r = runif(n = n())) %>% 
  mutate(
    prank = percent_rank(r)
  )

db_sales_customer %>% arrange(row)
db_sales_customer %>% collect() %>% arrange(row)
db_sales_customer %>% collect() %>% arrange(customer_id)

#...............................................................................
# CREATE TABLE の場合: 
# 以下のように、始めに乱数を作成しておくと再現性が確保される模様

con %>% dbExecute("DROP TABLE IF EXISTS temp_random")
# ランダムシードを設定
con %>% dbExecute("SELECT SETSEED(0.5);")

query = sql("
CREATE TEMP TABLE temp_random AS 
WITH rand_customers AS (
  SELECT 
    *, 
    RANDOM() AS rand
  FROM customer
), 
ranked_customers AS (
  SELECT
    *,
    PERCENT_RANK() OVER (ORDER BY rand) AS prank
  FROM rand_customers
)
SELECT 
  customer_id, prank
FROM 
  ranked_customers
"
)

con %>% dbExecute(q)
con %>% dbReadTable("temp_random") %>% as_tibble() %>% arrange(customer_id)

# A tibble: 21,971 × 2
#    customer_id      prank
#    <chr>            <dbl>
#  1 CS001105000001 0.57383
#  2 CS001112000009 0.20178
#  3 CS001112000019 0.10878
#  4 CS001112000021 0.10464
#  5 CS001112000023 0.79659
#  6 CS001112000024 0.22804
#  ...

#................................................
# DuckDB では、クエリの中で RANDOM() を使う場合、並び順を決定するためのキーを明示的に指定しないと、
# 毎回異なる順序になることがあります。
# そのため、以下のように 固定のカラム（例えば customer_id）を ORDER BY に追加することで、
# 再現性を確保できます。

#> この方法でも再現性がない。
# 以下は再現性がない

con %>% dbExecute("DROP TABLE IF EXISTS temp_random")

# ランダムシードを設定
con %>% dbExecute("SELECT SETSEED(0.5);")

query = sql("
CREATE TEMP TABLE temp_random AS 
SELECT 
  customer_id, 
  PERCENT_RANK() OVER (ORDER BY RANDOM(), customer_id) AS prank
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
con %>% dbReadTable("temp_random") %>% as_tibble() %>% arrange(customer_id)

#...............................................................................

# DuckDB の RANDOM() はスレッドによって動作が変わることがあるので、乱数を事前に計算しておく方法がより確実！

con %>% dbExecute("SELECT SETSEED(0.5);")

db_tmp = db_customer %>% 
  # mutate(row = row_number()) %>% 
  mutate(r = runif(n = n())) %>% 
  mutate(
    prank = percent_rank(r)
  )

db_tmp %>% select(customer_id, r, prank) %>% collect() %>% arrange(customer_id)

#................................................

con %>% dbExecute("DROP TABLE IF EXISTS temp_random")

# ランダムシードを設定
con %>% dbExecute("SELECT SETSEED(0.5);")

# 事前にランダム値を計算して保存
con %>% dbExecute("
CREATE TEMP TABLE temp_random AS
SELECT customer_id, RANDOM() AS rand_value
FROM customer
")

con %>% dbReadTable("temp_random") %>% as_tibble() %>% arrange(customer_id)

# A tibble: 21,971 × 2
#    customer_id    rand_value
#    <chr>               <dbl>
#  1 CS001105000001    0.57232
#  2 CS001112000009    0.20058
#  3 CS001112000019    0.10819
#  4 CS001112000021    0.10360
#  5 CS001112000023    0.79893
#  6 CS001112000024    0.22710
#  7 CS001112000029    0.14619
#  8 CS001112000030    0.84485
#  9 CS001113000004    0.48754
# 10 CS001113000010    0.66790
# ...
