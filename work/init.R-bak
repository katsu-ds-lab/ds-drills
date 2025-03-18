#===============================================================================
# R 起動後のセットアップ
#===============================================================================

# pacman のロード ------------
if (!require("pacman")) {
  install.packages("pacman")
  library("pacman")
}

# rstudioapi, tictoc のロード ------------
# 無い場合は自動でインストールした後にロードする.
pacman::p_load(
  rstudioapi,  # ローカルファイルパスの取得向け
  tictoc,      # 処理時間の計測向け
  install = T, # 存在しないパッケージをインストールする
  update = F   # 古いパッケージを更新しない
)

tictoc::tic("init") # タイマーの開始

# 作業ディレクトリの設定 ------------
# work_dir_path をローカル環境に合わせて適宜書き換えてください: 
work_dir_path = 
  rstudioapi::getSourceEditorContext()$path |> dirname()

work_dir_path |> setwd()
getwd() |> print() #> "your_directory_path/work"
cat("\n")

# env_setup.R の実行 ------------
source("env_setup.R", encoding = 'UTF-8')

# functions.R の実行 ------------
source("functions.R", encoding = 'UTF-8')

# data_setup.R の実行 ------------
source("data_setup.R", encoding = 'UTF-8')

tictoc::toc() # 経過時間の出力
# tictoc::tic.clear() # tic/toc スタックのクリア

#-------------------------------------------------------------------------------
