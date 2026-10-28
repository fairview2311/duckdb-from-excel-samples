FROM 'data/2026-09/売上_2026-09_渋谷店.xlsx';

DESCRIBE FROM 'data/2026-09/売上_2026-09_渋谷店.xlsx';

SELECT count(*) AS 行数
FROM 'data/2026-09/売上_2026-09_渋谷店.xlsx';

SELECT 伝票番号, 日付, 店舗, 商品コード,
       CAST(数量 AS INTEGER) AS 数量,
       CAST(単価 AS INTEGER) AS 単価,
       CAST(金額 AS INTEGER) AS 金額
FROM read_xlsx('data/2026-09/売上_2026-09_渋谷店.xlsx',
               sheet = '売上');

SELECT 伝票番号, 日付, 商品コード, 数量, 金額
FROM read_xlsx('data/2026-09/売上_2026-09_渋谷店.xlsx',
               sheet = '売上')
WHERE 商品コード = 'A007'
ORDER BY 金額 DESC;

SELECT 伝票番号, 日付, 商品コード, 金額
FROM read_xlsx('data/2026-09/売上_2026-09_渋谷店.xlsx',
               sheet = '売上')
WHERE 商品コード IN ('A001', 'A002', 'A003')
  AND 日付 BETWEEN '2026-09-21' AND '2026-09-30';

SELECT 伝票番号, 日付, 商品コード, 金額
FROM read_xlsx('data/2026-09/売上_2026-09_渋谷店.xlsx',
               sheet = '売上')
WHERE 商品コード LIKE 'A%'
ORDER BY 金額 DESC
LIMIT 10;

SELECT sum(金額) AS 金額の合計
FROM read_xlsx('data/2026-09/売上_2026-09_渋谷店.xlsx',
               sheet = '売上')
WHERE 商品コード = 'A007';

SELECT 商品コード,
       sum(金額) AS 金額の合計,
       count(*) AS 件数
FROM read_xlsx('data/2026-09/売上_2026-09_渋谷店.xlsx',
               sheet = '売上')
GROUP BY 商品コード
ORDER BY 金額の合計 DESC;

SELECT 商品コード, sum(金額) AS 金額の合計
FROM read_xlsx('data/2026-09/売上_2026-09_渋谷店.xlsx',
               sheet = '売上')
GROUP BY 商品コード
HAVING sum(金額) >= 100000
ORDER BY 金額の合計 DESC;

SELECT 日付, sum(金額) AS 金額の合計, count(*) AS 件数
FROM read_xlsx('data/2026-09/売上_2026-09_渋谷店.xlsx',
               sheet = '売上')
GROUP BY 日付
ORDER BY 日付;

SELECT sum(金額) AS 総計
FROM read_xlsx('data/2026-09/売上_2026-09_渋谷店.xlsx',
               sheet = '売上');

FROM read_xlsx('data/商品マスタ.xlsx',
               sheet = '商品マスタ');

SELECT s.伝票番号, s.商品コード, m.商品名, m.分類, s.金額
FROM read_xlsx('data/2026-09/売上_2026-09_渋谷店.xlsx',
                 sheet = '売上') AS s
JOIN read_xlsx('data/商品マスタ.xlsx',
                 sheet = '商品マスタ') AS m
  ON s.商品コード = m.商品コード;

SELECT s.伝票番号, s.商品コード, m.商品名, m.分類, s.金額
FROM read_xlsx('data/2026-09/売上_2026-09_渋谷店.xlsx',
                 sheet = '売上') AS s
LEFT JOIN read_xlsx('data/商品マスタ.xlsx',
                 sheet = '商品マスタ') AS m
  ON s.商品コード = m.商品コード
ORDER BY m.商品名 NULLS FIRST;

SELECT s.商品コード, count(*) AS 件数
FROM read_xlsx('data/2026-09/売上_2026-09_渋谷店.xlsx',
                 sheet = '売上') AS s
LEFT JOIN read_xlsx('data/商品マスタ.xlsx',
                 sheet = '商品マスタ') AS m
  ON s.商品コード = m.商品コード
WHERE m.商品コード IS NULL
GROUP BY s.商品コード;

SELECT m.分類, sum(s.金額) AS 金額の合計
FROM read_xlsx('data/2026-09/売上_2026-09_渋谷店.xlsx',
                 sheet = '売上') AS s
JOIN read_xlsx('data/商品マスタ.xlsx',
                 sheet = '商品マスタ') AS m
  ON s.商品コード = m.商品コード
GROUP BY m.分類
ORDER BY 金額の合計 DESC;

FROM glob('data/2026-09/*.xlsx');

SELECT 店舗, count(*) AS 行数
FROM read_xlsx('data/2026-09/*.xlsx',
               sheet = '売上')
GROUP BY 店舗;

SET VARIABLE 読む = (
  SELECT string_agg(
    format('SELECT * FROM read_xlsx(''{}'', sheet = ''売上'')', file),
    ' UNION ALL BY NAME ')
  FROM glob('data/2026-09/*.xlsx')
);
SELECT getvariable('読む') AS まとめて読むSQL;

CREATE OR REPLACE TABLE 今月の売上 AS
SELECT 伝票番号, 日付, 店舗, 商品コード,
       CAST(数量 AS INTEGER) AS 数量,
       CAST(単価 AS INTEGER) AS 単価,
       CAST(金額 AS INTEGER) AS 金額
FROM query(getvariable('読む'));
SELECT count(*) AS 行数 FROM 今月の売上;

SELECT 店舗, count(*) AS 行数, sum(金額) AS 金額の合計
FROM 今月の売上
GROUP BY 店舗
ORDER BY 金額の合計 DESC;

PIVOT (
  SELECT s.店舗, m.分類, s.金額
  FROM 今月の売上 AS s
  JOIN read_xlsx('data/商品マスタ.xlsx',
                 sheet = '商品マスタ') AS m
    ON s.商品コード = m.商品コード
)
ON 分類
USING sum(金額)
GROUP BY 店舗
ORDER BY 店舗;

FROM read_csv('data/基幹システム/法人売上_2026-09.csv',
              encoding = 'cp932');

SELECT '[' || 取引先 || ']' AS 取引先, count(*) AS 件数
FROM read_csv('data/基幹システム/法人売上_2026-09.csv',
              encoding = 'cp932')
GROUP BY 取引先
ORDER BY 取引先;

SELECT 取引先 AS 元の取引先,
       replace(replace(replace(replace(trim(取引先),
         '㈱', '（株）'),
         '（株）', '株式会社'),
         '（有）', '有限会社'),
         'ＭＩＮＡＴＯ学園', 'みなと学園') AS 取引先,
       count(*) AS 件数
FROM read_csv('data/基幹システム/法人売上_2026-09.csv',
              encoding = 'cp932')
GROUP BY ALL
ORDER BY 取引先;

SELECT 受注日,
       try_strptime(受注日,
         ['%Y-%m-%d', '%Y/%m/%d', '%Y年%m月%d日', '%Y%m%d']
       )::DATE AS 受注日_日付
FROM read_csv('data/基幹システム/法人売上_2026-09.csv',
              encoding = 'cp932')
LIMIT 10;

CREATE OR REPLACE TABLE 法人売上 AS
SELECT 注文番号,
       try_strptime(受注日,
         ['%Y-%m-%d', '%Y/%m/%d', '%Y年%m月%d日', '%Y%m%d']
       )::DATE AS 受注日,
       replace(replace(replace(replace(trim(取引先),
         '㈱', '（株）'),
         '（株）', '株式会社'),
         '（有）', '有限会社'),
         'ＭＩＮＡＴＯ学園', 'みなと学園') AS 取引先,
       商品コード, 数量, 金額, 担当店舗
FROM read_csv('data/基幹システム/法人売上_2026-09.csv',
              encoding = 'cp932');
SELECT count(DISTINCT 取引先) AS 取引先の数,
       count(*) FILTER (WHERE 受注日 IS NULL) AS 日付が読めない行
FROM 法人売上;

SELECT 取引先, count(*) AS 件数, sum(金額) AS 金額の合計
FROM 法人売上
GROUP BY 取引先
ORDER BY 金額の合計 DESC;

PIVOT (
  SELECT s.店舗, coalesce(m.分類, '分類なし') AS 分類, s.金額
  FROM 今月の売上 AS s
  LEFT JOIN read_xlsx('data/商品マスタ.xlsx',
                      sheet = '商品マスタ') AS m
    ON s.商品コード = m.商品コード
)
ON 分類
USING sum(金額)
GROUP BY 店舗
ORDER BY 店舗;
