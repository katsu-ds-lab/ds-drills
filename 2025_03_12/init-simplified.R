# pacman を使用してパッケージを管理
if (!require("pacman")) {
  install.packages("pacman")
  library("pacman")
}

# 必要なパッケージのロード
# 存在しない場合は自動でインストールした後にロードする.
pacman::p_load(
  # tidyverse: 
  magrittr, fs, tibble, dplyr, tidyr, stringr, lubridate, forcats, 
  DBI, dbplyr, duckdb,      # for database
  rsample, recipes, themis, # tidymodels
  vroom, tictoc, jsonlite, withr, janitor, skimr, epikit, 
  install = TRUE,  # 存在しないパッケージをインストールする
  update = FALSE   # 古いパッケージを更新しない
)

# CSVファイルをデータフレームとして読み込む
my_vroom = function(file, col_types) {
  data_url = "https://raw.githubusercontent.com/The-Japan-DataScientist-Society/100knocks-preprocess/master/docker/work/data/"
  tictoc::tic(file)
  on.exit(tictoc::toc())
  on.exit(cat("\n"), add = TRUE)
  csv_url = data_url %>% paste0(file)
  print(csv_url); flush.console()
  d = csv_url %>% 
    vroom::vroom(col_types = col_types) %>% 
    janitor::clean_names() %>% 
    dplyr::glimpse() %T>% 
    { cat("\n") }
  return(d)
}

# customer.birth_day は Dateクラス
df_customer = "customer.csv" %>% my_vroom(col_types = "ccccDiccccc")
# receipt.sales_ymd は integer
df_receipt = "receipt.csv" %>% my_vroom(col_types = "iiciiccnn")
df_store = "store.csv" %>% my_vroom(col_types = "cccccccddd")
df_product = "product.csv" %>% my_vroom(col_types = "ccccnn")
df_category = "category.csv" %>% my_vroom(col_types = "cccccc")
df_geocode = "geocode.csv" %>% my_vroom(col_types = "cccccccnn")

# インメモリモードで一時的な DuckDB 環境を作成する
con = duckdb::duckdb(dbdir = "") %>% duckdb::dbConnect()

# データフレームを DuckDB にテーブルとして書き込む
con %>% DBI::dbWriteTable("customer", df_customer, overwrite = TRUE)
con %>% DBI::dbWriteTable("receipt", df_receipt, overwrite = TRUE)
con %>% DBI::dbWriteTable("store", df_store, overwrite = TRUE)
con %>% DBI::dbWriteTable("product", df_product, overwrite = TRUE)
con %>% DBI::dbWriteTable("category", df_category, overwrite = TRUE)
con %>% DBI::dbWriteTable("geocode", df_geocode, overwrite = TRUE)

# DuckDB のテーブルを dplyr で参照する
db_customer = con %>% dplyr::tbl("customer")
db_receipt = con %>% dplyr::tbl("receipt")
db_store = con %>% dplyr::tbl("store")
db_product = con %>% dplyr::tbl("product")
db_category = con %>% dplyr::tbl("category")
db_geocode = con %>% dplyr::tbl("geocode")

# db_get_query() の定義
# SQLクエリを実行し, データフレーム(tibble)を返す
db_get_query = function(
    statement, con, convert_tibble = TRUE, params = NULL, ...
  ) {
  d = DBI::dbGetQuery(conn = con, statement = statement, params = params, ...)
  if (convert_tibble) d %<>% tibble::as_tibble()
  return(d)
}
