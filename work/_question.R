#-------------------------------------------------------------------------------

# slice_max ------------
各店舗ごとに最も売上金額 (amount) が高い3つの商品の情報を抽出してください。
ただし、売上金額が同じ商品が複数ある場合は、全てを抽出してください。

db_receipt %>% 
  group_by(store_cd, product_cd) %>% 
  summarise(total_amount = sum(amount), .groups = "drop_last") %>% 
  slice_max(total_amount, n = 3, with_ties = TRUE) %>% 
  # ungroup() %>% 
  # arrange(store_cd, desc(total_amount)) %>% 
  arrange(desc(total_amount), .by_group = T) %>% 
  my_show_query(F)

# complete ------------
都道府県ごとの売上集計を行い、売上がない都道府県を含めて表示せよ
各都道府県ごとの売上金額の合計を集計し、売上がない都道府県を含めて結果を表示してください。
この際、group_byを使用して都道府県ごとに集計し、completeを使用して売上がない都道府県を含む完全な結果を表示してください。

年齢別の商品売上合計を集計せよ
顧客を年齢別にグループ化し、各年齢層ごとの商品別売上金額を集計してください。
この際、group_byを使用して年齢別にグループ化し、各年齢層ごとの売上を集計してください。また、年齢別に売上がゼロの商品が含まれるように、completeを使用してください。

商品カテゴリーごとの販売金額の合計を集計せよ
各商品カテゴリーごとの売上金額を集計し、売上金額がゼロのカテゴリーも表示するようにしてください。
group_byを使用してカテゴリーごとに集計し、completeを使用して売上金額がゼロのカテゴリーも含めて表示してください。

# cumsum() ------------
各顧客の累積購入金額を計算せよ
各顧客について、購入日順に累積購入金額（cumsum()を用いた計算）を求めてください。
また、顧客ごとの最終的な累積購入金額が高い順に並べて表示してください。

商品カテゴリー別の累積売上金額を計算せよ
各商品カテゴリーについて、販売日順に累積売上金額を求めてください。
この際、cumsum()を用いて計算を行い、カテゴリーごとに累積金額がわかるようにしてください。

店舗ごとの累積売上金額の推移を表示せよ
各店舗について、販売日順に累積売上金額を計算し、店舗ごとの売上推移を表示してください。
売上推移が視覚的にわかるように、データを時系列で並べてください。

# cumany() ------------
特定のカテゴリーの商品を購入したことがある顧客を判定せよ
各顧客について、指定されたカテゴリー（例: 大カテゴリーコードが01）の商品を一度でも購入したかどうかを判定してください。
この際、cumany()を使用して条件を満たしたかどうかを累積的に確認し、結果を顧客ごとにまとめてください。

店舗ごとに一定金額以上の売上が発生したことがある日を判定せよ
各店舗について、売上金額が10万円以上の日が一度でもあったかどうかを判定してください。
この際、cumany()を使用して条件を満たしたかどうかを累積的に確認し、店舗ごとの結果を出力してください。

顧客の累積購入金額が一定額を超えた時点を判定せよ
各顧客について、累積購入金額が5万円以上に達したかどうかを判定してください。
この際、cumany()を使用して累積的に条件を確認し、条件を満たした日付を結果として出力してください。

# window_frame, window_order ------------
顧客ごとの累積購入金額の移動平均を計算せよ
各顧客について、購入日順に累積購入金額の3件ごとの移動平均を計算してください。
この際、window_order を利用して購入日順にデータを並べ、window_frame を用いて計算範囲を指定してください。

店舗ごとの日別売上金額のランクを算出せよ
各店舗について、販売日ごとに売上金額をランク付けしてください（例: その日の売上金額が店舗内で何位かを表示）。
この際、window_order を用いて販売日ごとにデータを並べ、ランクを算出してください。

都道府県別に累積売上金額の順位を計算せよ
都道府県ごとに累積売上金額を計算し、各都道府県の売上金額が全国で何位かを計算してください。
window_order を用いて累積売上金額順にデータを並べ、ウィンドウ関数を使って順位を計算してください。

# ntile ------------
顧客を累積購入金額の分位数でグループ分けせよ
各顧客の累積購入金額を計算し、その値に基づいてntileを使って4つのグループ（四分位数）に分けてください。
グループごとの顧客数を集計し、各グループの累積購入金額の範囲も出力してください。

店舗の日別売上金額を分位数で分類せよ
各店舗の日別売上金額を計算し、その値に基づいてntileを使って3つのグループ（上位、中位、下位）に分けてください。
グループごとに日別売上金額の平均を出力してください。

商品の単価を分位数でカテゴリー化せよ
商品の単価 (unit_price) を基準に、ntileを使って5つのカテゴリー（五分位数）に分けてください。
各カテゴリーに属する商品数を集計し、カテゴリーごとの単価範囲を出力してください。

# setdiff ------------
購入が記録されていない商品を抽出せよ
product テーブルに存在するが、receipt テーブルで一度も購入されていない商品を特定してください。これには setdiff を使用してください。

来店履歴がない顧客を抽出せよ
customer テーブルに存在するが、receipt テーブルで一度も購入を記録していない顧客を特定してください。これには setdiff を使用してください。

特定の都道府県に含まれない店舗を抽出せよ
store テーブルに存在するが、geocode テーブルの prefecture に対応しない都道府県の店舗を特定してください。

# semi_join ------------
商品を購入したことのある顧客のリストを取得してください。
条件
receipt テーブルに基づいて、購入履歴がある customer_id を特定すること。
customer テーブルを基に、購入履歴がある顧客の詳細情報（customer_id, customer_name, gender, age）を取得すること。
semi_join を使用すること。

# complete, ranking関数, join ------------
以下の条件に基づいて、各店舗の月ごとの売上金額合計を算出し、すべての店舗・月の組み合わせが表示されるようにデータを補完してください。さらに、各店舗ごとに売上金額の累積順位を付けてください。

条件
1. receipt テーブルを基に、店舗ごとの月ごとの売上金額合計を計算する。
- 売上金額は amount 列の合計値。
- 売上日 (sales_ymd) から月を取得し、集計単位とする。
2. 集計後、すべての店舗とすべての月（データ中の最小月から最大月まで）の組み合わせが表示されるようにデータを補完する。
- 欠損する店舗・月の組み合わせは amount = 0 として補完する。
3. 補完されたデータに対して、各店舗ごとに売上金額の累積順位を付ける。
- 累積順位は売上金額が高い順に付ける（降順）。
4. store テーブルを用いて店舗名を追加し、最終結果を見やすくする。

# RFM分析 ------------
RFM分析の指標を計算せよ
顧客ごとに以下のRFM指標を計算してください:

Recency (R): 最終購入日から現在までの日数
Frequency (F): 購入回数
Monetary (M): 購入総額
RFMスコアを算出せよ
各指標を5段階でスコアリングしてください（例: 五分位に基づくスコアリング）。スコアの計算後、R, F, M の値を足して総合スコアを算出してください。

顧客セグメントを作成せよ
総合スコアを基に、以下のようなセグメントを作成してください:

VIP: スコアが上位20%の顧客
Regular: スコアが中央値付近の顧客
Lost: スコアが下位20%の顧客
セグメントごとの分析を行え
各セグメントについて、以下の項目を集計してください:

セグメント内の顧客数
平均購買金額
平均購買頻度

#-------------------------------------------------------------------------------
* 問題作成

-- customer
DROP TABLE IF EXISTS customer;
CREATE TABLE customer(
  customer_id            VARCHAR(14),
  customer_name          VARCHAR(20),
  gender_cd              VARCHAR(1),
  gender                 VARCHAR(2),
  birth_day              DATE,
  age                    INTEGER,
  postal_cd              VARCHAR(8),
  address                VARCHAR(128),
  application_store_cd   VARCHAR(6),
  application_date       VARCHAR(8),
  status_cd              VARCHAR(12),
  PRIMARY KEY (customer_id)
);

-- category
DROP TABLE IF EXISTS category;
CREATE TABLE category(
  category_major_cd     VARCHAR(2),
  category_major_name   VARCHAR(32),
  category_medium_cd    VARCHAR(4),
  category_medium_name  VARCHAR(32),
  category_small_cd     VARCHAR(6),
  category_small_name   VARCHAR(32),
  PRIMARY KEY (category_small_cd)
);


-- product
DROP TABLE IF EXISTS product;
CREATE TABLE product(
  product_cd            VARCHAR(10),
  category_major_cd     VARCHAR(2),
  category_medium_cd    VARCHAR(4),
  category_small_cd     VARCHAR(6),
  unit_price            INTEGER,
  unit_cost             INTEGER,
  PRIMARY KEY (product_cd)
);

-- store
DROP TABLE IF EXISTS store;
CREATE TABLE store(
  store_cd      VARCHAR(6),
  store_name    VARCHAR(128),
  prefecture_cd VARCHAR(2),
  prefecture    VARCHAR(5),
  address       VARCHAR(128),
  address_kana  VARCHAR(128),
  tel_no        VARCHAR(20),
  longitude     NUMERIC,
  latitude      NUMERIC,
  floor_area    NUMERIC,
  PRIMARY KEY (store_cd)
);

-- receipt
DROP TABLE IF EXISTS receipt;
CREATE TABLE receipt(
  sales_ymd       INTEGER,
  sales_epoch     INTEGER,
  store_cd        VARCHAR(6),
  receipt_no      SMALLINT,
  receipt_sub_no  SMALLINT,
  customer_id     VARCHAR(14),
  product_cd      VARCHAR(10),
  quantity        INTEGER,
  amount          INTEGER,
  PRIMARY KEY (sales_ymd, store_cd, receipt_no, receipt_sub_no)
);

-- geocode
DROP TABLE IF EXISTS geocode;
CREATE TABLE geocode(
  postal_cd       VARCHAR(8),
  prefecture      VARCHAR(4),
  city            VARCHAR(30),
  town            VARCHAR(30),
  street          VARCHAR(30),
  address         VARCHAR(30),
  full_address    VARCHAR(80),
  longitude       NUMERIC,
  latitude        NUMERIC
);

上記6個のテーブルがDuckDB上にあります。
また、以下のように、これらのテーブル参照である db_receipt などがあります。

my_tbl = function(
    con, df, 
    name = deparse(substitute(df)), 
    rm_pattern = "^df_", 
    overwrite = FALSE, append = FALSE, row_names = FALSE, 
    field_types = NULL, temporary = FALSE
  ) {
  # name からマッチしたパターンを削除する
  if (!is.null(rm_pattern))
    name %<>% stringr::str_remove(pattern = rm_pattern)
  # データフレームをDBに書き込む
  DBI::dbWriteTable(
    conn = con, name = name, value = df, 
    overwrite = overwrite, append = append, row.names = row_names, 
    field.types = field_types, temporary = temporary
  )
  sprintf("table name = %s\n", name) %>% cat()
  # テーブル参照を取得する
  con %>% dplyr::tbl(name)
}

db_receipt = con %>% my_tbl(df = df_receipt, overwrite = T)
db_customer = con %>% my_tbl(df = df_customer, overwrite = T)
db_product = con %>% my_tbl(df = df_product, overwrite = T)
db_category = con %>% my_tbl(df = df_category, overwrite = T)
db_store = con %>% my_tbl(df = df_store, overwrite = T)
db_geocode = con %>% my_tbl(df = df_geocode, overwrite = T)

これら6個のテーブル参照をいくつか用いて、次の条件を満たすデータ処理向けの問題を考えてください。

条件: 
- Rの解答例付き
- 難易度: 上級
- group_by, complete, join, ranking関数 を使用すること。
