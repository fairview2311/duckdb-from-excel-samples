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
