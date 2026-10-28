SELECT count(*) AS 行数,
       min(日付) AS 最初の日, max(日付) AS 最後の日
FROM 全期間の売上;

PIVOT (
  SELECT 店舗, year(日付) AS 年, 金額
  FROM 全期間の売上
)
ON 年
USING sum(金額)
GROUP BY 店舗
ORDER BY 店舗;

LOAD excel;
COPY (
  PIVOT (
    SELECT 店舗, year(日付) AS 年, 金額
    FROM 全期間の売上
  )
  ON 年
  USING sum(金額)
  GROUP BY 店舗
  ORDER BY 店舗
)
TO '店舗別_年別の売上.xlsx'
(FORMAT xlsx, HEADER true, SHEET '店舗別_年別');

COPY 全期間の売上
TO '全期間の売上.parquet'
(FORMAT parquet);

PIVOT (
  SELECT 店舗, year(日付) AS 年, 金額
  FROM '全期間の売上.parquet'
)
ON 年
USING sum(金額)
GROUP BY 店舗
ORDER BY 店舗;
