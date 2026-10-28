-- 月次売上報告。毎月、次の行の月だけを書き換える
SET VARIABLE 対象の月 = '2026-09';

-- 今月の12店舗のファイルを読む（第6章）
SET VARIABLE 読む = (
  SELECT string_agg(
    format('SELECT * FROM read_xlsx(''{}'', sheet = ''売上'')', file),
    ' UNION ALL BY NAME ')
  FROM glob('data/' || getvariable('対象の月') || '/*.xlsx')
);
CREATE OR REPLACE TABLE 今月の売上 AS
SELECT 伝票番号, 日付, 店舗, 商品コード,
       CAST(数量 AS INTEGER) AS 数量,
       CAST(単価 AS INTEGER) AS 単価,
       CAST(金額 AS INTEGER) AS 金額
FROM query(getvariable('読む'));

-- 商品マスタ（第5章）
CREATE OR REPLACE TABLE 商品マスタ AS
FROM read_xlsx('data/商品マスタ.xlsx',
               sheet = '商品マスタ');

-- 全期間の売上（第8章）。今月の分を削除してから追加する
CREATE TABLE IF NOT EXISTS 全期間の売上 AS
SELECT CAST(伝票番号 AS VARCHAR) AS 伝票番号,
       日付, 店舗, 商品コード, 数量, 単価, 金額
FROM read_csv('data/過去分/*.csv');
DELETE FROM 全期間の売上
WHERE strftime(日付, '%Y-%m') = getvariable('対象の月');
INSERT INTO 全期間の売上 BY NAME
FROM 今月の売上;

-- 報告に載せる表（ビュー）
CREATE OR REPLACE VIEW 店舗別の売上 AS
SELECT 店舗, count(*) AS 行数, sum(金額) AS 金額の合計,
       rank() OVER (ORDER BY sum(金額) DESC) AS 順位
FROM 今月の売上
GROUP BY 店舗
ORDER BY 順位;

CREATE OR REPLACE VIEW 分類別の売上 AS
PIVOT (
  SELECT s.店舗, coalesce(m.分類, '分類なし') AS 分類, s.金額
  FROM 今月の売上 AS s
  LEFT JOIN 商品マスタ AS m
    ON s.商品コード = m.商品コード
)
ON 分類 IN ('筆記具', 'ノート', 'ファイル',
          '事務用品', '画材', '分類なし')
USING sum(金額)
GROUP BY 店舗
ORDER BY 店舗;

CREATE OR REPLACE VIEW 月別の売上 AS
SELECT date_trunc('month', 日付)::DATE AS 月,
       sum(金額) AS 金額
FROM 全期間の売上
GROUP BY 月;

CREATE OR REPLACE VIEW 前年比 AS
SELECT 月, 金額,
       lag(金額, 12) OVER (ORDER BY 月) AS 前年同月の金額,
       round(金額 / lag(金額, 12) OVER (ORDER BY 月), 3) AS 前年比
FROM 月別の売上
ORDER BY 月 DESC;

-- 結果を確かめる
SELECT getvariable('対象の月') AS 対象の月,
       count(*) AS 行数, sum(金額) AS 金額の合計
FROM 今月の売上;
FROM 前年比 LIMIT 3;
