#===============================================================================
# データの準備
# 1. 各CSVファイル等をダウンロードする.
# 2. DBコネクションを作成する.
# 3. 各CSVファイルをDBに書き込み, テーブル参照を取得する.
# 4. データフレームを取得する
#===============================================================================

# 各CSVファイル等のダウンロード ------------

# GitHub API URL of 100knocks data
data_url = 
  "https://api.github.com/repos/The-Japan-DataScientist-Society/100knocks-preprocess/contents/docker/work/data"

# 各ファイルのURL
urls = data_url %>% 
  httr::GET() %>% 
  httr::content(as = "text") %>% 
  jsonlite::fromJSON() %>% 
  dplyr::pull(download_url)

# dataディレクトリの作成
data_dir = my_path_join()
if (!fs::dir_exists(data_dir))
  fs::dir_create(data_dir)

for (url in urls) {
  # ダウンロード先のファイルパス
  path = url %>% xfun::url_filename() %>% my_path_join()
  # ダウンロード (上書きはしない)
  if (!fs::file_exists(path))
    xfun::download_file(url, output = path)
}

#-------------------------------------------------------------------------------
# DBコネクションの作成 ------------

# DBファイルのパス
dbdir = my_path_join("100knocks.duckdb", .subdir = "DB")

# dbdir の親ディレクトリが無ければ作成する (あれば何もしない)
dbdir %>% fs::path_dir() %>% fs::dir_create()

# dbdir = "" #< DBを in-memory で一時的に作成する場合
drv = duckdb::duckdb(dbdir = dbdir) # duckdb_driverオブジェクト

duckdb::dbConnect(
  drv = drv
  # timezone_out = Sys.timezone() # ローカルのタイムゾーンで日時の値を表示する
) -> 
con

# db.version, dbname などを表示する
con %>% DBI::dbGetInfo() %>% dplyr::glimpse() 
cat("\n")

# DBコネクションを切断する場合: 
# con %>% duckdb::dbDisconnect()

#-------------------------------------------------------------------------------
# CSVファイルのDBへの書き込みとテーブル参照の取得 ------------

# テーブル情報のリスト (DuckDBデータ型)
col_types_list = tables = list(
  customer = c(
    customer_id = "VARCHAR(14)",
    customer_name = "VARCHAR(20)",
    gender_cd = "VARCHAR(1)",
    gender = "VARCHAR(2)",
    birth_day = "DATE",
    age = "INTEGER",
    postal_cd = "VARCHAR(8)",
    address = "VARCHAR(128)",
    application_store_cd = "VARCHAR(6)",
    application_date = "VARCHAR(8)",
    status_cd = "VARCHAR(12)"
  ),
  category = c(
    category_major_cd = "VARCHAR(2)",
    category_major_name = "VARCHAR(32)",
    category_medium_cd = "VARCHAR(4)",
    category_medium_name = "VARCHAR(32)",
    category_small_cd = "VARCHAR(6)",
    category_small_name = "VARCHAR(32)"
  ),
  product = c(
    product_cd = "VARCHAR(10)",
    category_major_cd = "VARCHAR(2)",
    category_medium_cd = "VARCHAR(4)",
    category_small_cd = "VARCHAR(6)",
    unit_price = "INTEGER",
    unit_cost = "INTEGER"
  ),
  store = c(
    store_cd = "VARCHAR(6)",
    store_name = "VARCHAR(128)",
    prefecture_cd = "VARCHAR(2)",
    prefecture = "VARCHAR(5)",
    address = "VARCHAR(128)",
    address_kana = "VARCHAR(128)",
    tel_no = "VARCHAR(20)",
    longitude = "DOUBLE",
    latitude = "DOUBLE",
    floor_area = "DOUBLE"
  ),
  receipt = c(
    sales_ymd = "INTEGER",
    sales_epoch = "INTEGER",
    store_cd = "VARCHAR(6)",
    receipt_no = "SMALLINT",
    receipt_sub_no = "SMALLINT",
    customer_id = "VARCHAR(14)",
    product_cd = "VARCHAR(10)",
    quantity = "INTEGER",
    amount = "INTEGER"
  ),
  geocode = c(
    postal_cd = "VARCHAR(8)",
    prefecture = "VARCHAR(4)",
    city = "VARCHAR(30)",
    town = "VARCHAR(30)",
    street = "VARCHAR(30)",
    address = "VARCHAR(30)",
    full_address = "VARCHAR(80)",
    longitude = "DOUBLE",
    latitude = "DOUBLE"
  )
)

for (table_name in names(col_types_list)) {
  # CSVファイルのフルパス
  path = 
    table_name %>% fs::path_ext_set("csv") %>% my_path_join()
  cat("read: \n", path, "\n\n")
  # 各カラムのデータ型
  col_types = col_types_list[[table_name]]
  # CSVファイルを DuckDB に直接書き込む (上書きはしない)
  if (!dbExistsTable(con, table_name)) {
    duckdb::duckdb_read_csv(
      con, table_name, files = path, col.types = col_types
    )
  }
  # テーブル参照を取得する (db_*)
  db_obj_name = paste0("db_", table_name)
  assign(db_obj_name, tbl(con, table_name))
  # テーブルの内容を表示する
  get(db_obj_name) %>% dplyr::glimpse()
  cat("\n")
  # データフレームを取得する (df_*)
  df_obj_name = paste0("df_", table_name)
  # assign(df_obj_name, get(db_obj_name) %>% collect())
  assign(df_obj_name, get(db_obj_name) %>% collect(), envir = globalenv())
  cat("\n")
}

# DB上に作成したテーブルリストを表示する
con %>% DBI::dbListTables() %>% print()

#-------------------------------------------------------------------------------
