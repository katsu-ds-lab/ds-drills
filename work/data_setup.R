#===============================================================================
# データの準備
# 1. 各CSVファイルを読み込む.
# 2. データベース・コネクションを作成する.
# 3. データフレームを DuckDB に書き込み, テーブル参照を取得する.
#===============================================================================a

# 各CSVファイルの読み込み ------------

my_vroom = function(file, col_types, .subdir = "data") {
  tictoc::tic(file)
  on.exit(tictoc::toc())
  on.exit(cat("\n"), add = TRUE)
  d = file %>% 
    my_path_join(.subdir = .subdir) %>% 
    { print(.); flush.console(); . } %>% 
    vroom::vroom(col_types = col_types) %>% 
    janitor::clean_names() %>% 
    dplyr::glimpse() %T>% 
    { cat("\n") }
  return(d)
}

# (エディターのコード補完を利用できるように assign() を用いてオブジェクトを作成しない)
# customer.birth_day は Dateクラス
df_customer = "customer.csv" %>% my_vroom(col_types = "ccccDiccccc")
# receipt.sales_ymd は integer
df_receipt = "receipt.csv" %>% my_vroom(col_types = "iiciiccnn")
df_store = "store.csv" %>% my_vroom(col_types = "cccccccddd")
df_product = "product.csv" %>% my_vroom(col_types = "ccccnn")
df_category = "category.csv" %>% my_vroom(col_types = "cccccc")
df_geocode = "geocode.csv" %>% my_vroom(col_types = "cccccccnn")

#-------------------------------------------------------------------------------
# データベース・コネクションの作成 ------------

is_fbmode = TRUE  # ファイルベースモードで作成する場合
# 一時的にメモリ上に作成する場合は, 以下の行のコメントアウトを外してください.
# is_fbmode = FALSE

if (is_fbmode) {
  # DuckDB データベースファイルのパス
  dbpath = my_path_join("supermarket.duckdb", .subdir = "database")
  # dbpath の親ディレクトリが無ければ作成する (あれば何もしない)
  dbpath %>% fs::path_dir() %>% fs::dir_create()
} else {
  dbpath = ""
}

# duckdb_driverオブジェクト
drv = duckdb::duckdb(dbdir = dbpath)

con = duckdb::dbConnect(
    drv = drv
    # timezone_out = Sys.timezone() # ローカルのタイムゾーンで日時の値を表示する
  )

# db.version, dbname などを表示する
con %>% DBI::dbGetInfo() %>% dplyr::glimpse()
cat("\n")

# データベース・コネクションを切断する場合: 
# con %>% duckdb::dbDisconnect()

#-------------------------------------------------------------------------------
# データフレームの DuckDB への書き込みとテーブル参照の取得 ------------

# - テーブルが既に存在する場合は上書きする
# - エディターのコード補完を利用できるように assign() を用いてオブジェクトを作成しない
db_receipt = con %>% my_tbl(df = df_receipt, overwrite = TRUE)
db_customer = con %>% my_tbl(df = df_customer, overwrite = TRUE)
db_product = con %>% my_tbl(df = df_product, overwrite = TRUE)
db_category = con %>% my_tbl(df = df_category, overwrite = TRUE)
db_store = con %>% my_tbl(df = df_store, overwrite = TRUE)
db_geocode = con %>% my_tbl(df = df_geocode, overwrite = TRUE)

# DuckDB 上に作成したテーブルのリスト
con %>% DBI::dbListTables() %>% print()

#-------------------------------------------------------------------------------
