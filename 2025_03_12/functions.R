#===============================================================================
# 関数の定義
#===============================================================================

# my_path_join ------------
# パスを作成する
# .dir, .subdir: 無効にする場合は NULL を設定する
my_path_join = function(..., .dir = getwd(), .subdir = "data") {
  c(.dir, .subdir, ...) %>% 
    fs::path_join() %>% 
    fs::path_norm()
}

# my_tbl ------------
# データフレームをデータベースに書き込み, テーブル参照を取得する
# con:        データベース接続オブジェクト(DBIオブジェクト)
# df:         データベースに書き込むデータフレーム
# name:       テーブル名. デフォルトでは df の名前を使用
# rm_pattern: nameからマッチしたパターンを削除する.(無効にする場合は NULL or "^$")
# print_list: データベースに作成済みのテーブルリストを表示するか否か
# row_names:  行名をテーブルに含めるか否か
# overwrite:  テーブルが既に存在する場合に上書きするか否か
# append:     テーブルにデータを追加するか否か
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
  # データフレームをデータベースにテーブルとして書き込む
  DBI::dbWriteTable(
    conn = con, name = name, value = df, 
    overwrite = overwrite, append = append, row.names = row_names, 
    field.types = field_types, temporary = temporary
  )
  sprintf("table name = %s\n", name) %>% cat()
  # テーブル参照を取得する
  con %>% dplyr::tbl(name)
}

# db_get_query ------------
# DBI::dbGetQuery() のラッパー
# SQLクエリを実行し, データフレーム(tibble)を返す
db_get_query = function(
    statement, con, convert_tibble = TRUE, params = NULL, ...
  ) {
  d = DBI::dbGetQuery(con, statement = statement, params = params, ...)
  if (convert_tibble) d %<>% tibble::as_tibble()
  return(d)
}

# sql_render_ext ------------
# dbplyr::sql_render のラッパー
# デフォルトでは, バッククォート(`)を削除する
sql_render_ext = function(
    query, con = NULL, 
    cte = TRUE, 
    qualify_all_columns = TRUE, 
    use_star = TRUE, 
    sql_op = 
      dbplyr::sql_options(
        cte = cte, 
        use_star = use_star, 
        qualify_all_columns = qualify_all_columns
      ), 
    subquery = FALSE, lvl = 0, 
    pattern = "`", replacement = ""
  ) {
  s = query %>% 
    dbplyr::sql_render(
      con = con, sql_options = sql_op, subquery = subquery, lvl = lvl
    )
  if (!is.null(pattern)) {
    s %<>% gsub(pattern, replacement, .)
  }
  return(s)
}

#-------------------------------------------------------------------------------
