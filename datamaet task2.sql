use datamart_db;

## 어떤 총괄 책임자가 특정 고객을 처리하고 추적합니까?
SELECT
    SR.NAME AS SALES_REP_NAME,
    A.NAME AS ACCOUNT_NAME
FROM
    SALES_REP SR
JOIN
    ACCOUNTS A ON SR.ID = A.SALES_REP_ID
ORDER BY
    SR.NAME, A.NAME;

use datamart_db

## 회사는 어떤 계정이 수익의 대부분을 차지하는지 알아야 하며,
## 또한 기업에서는 각 계정의 수익 기여도에 대한 연간 추세를 확인

WITH YearlyRevenue AS (
    SELECT
        EXTRACT(YEAR FROM ORDERS.occurred_at) AS `Year`,
        ACCOUNTS.NAME AS `Account Name`,
        SUM(ORDERS.TOTAL_AMT_USD) AS `Yearly Revenue`
    FROM
        ORDERS
    JOIN
        ACCOUNTS ON ORDERS.ACCOUNT_ID = ACCOUNTS.ID
    GROUP BY
        `Year`, `Account Name`
),
TotalYearlyRevenue AS (
    SELECT
        EXTRACT(YEAR FROM ORDERS.occurred_at) AS `Year`,
        SUM(ORDERS.TOTAL_AMT_USD) AS `Total Yearly Revenue`
    FROM
        ORDERS
    GROUP BY
        `Year`
)
SELECT
    YR.`Year`,
    YR.`Account Name`,
    YR.`Yearly Revenue`,
    TYR.`Total Yearly Revenue`,
    (YR.`Yearly Revenue` / TYR.`Total Yearly Revenue`) * 100 AS `Revenue Contribution (%)`
FROM
    YearlyRevenue YR
JOIN
    TotalYearlyRevenue TYR ON YR.`Year` = TYR.`Year`
ORDER BY
    YR.`Year`, `Revenue Contribution (%)` DESC;

## 마지막 표에는 매년 총 수익 중 각 계정의 수익 표시를 표시합니다
## 최종 테이블은 다음과 같습니다.

WITH YearlyRevenue AS (
    SELECT
        EXTRACT(YEAR FROM orders.occurred_at) AS `Year`,
        ACCOUNTS.NAME AS `Account Name`,
        SUM(ORDERS.TOTAL_AMT_USD) AS `Yearly Revenue`
    FROM
        ORDERS
    JOIN
        ACCOUNTS ON ORDERS.ACCOUNT_ID = ACCOUNTS.ID
    GROUP BY
        `Year`, `Account Name`
),
TotalYearlyRevenue AS (
    SELECT
        EXTRACT(YEAR FROM orders.occurred_at) AS `Year`,
        SUM(ORDERS.TOTAL_AMT_USD) AS `Total Yearly Revenue`
    FROM
        ORDERS
    GROUP BY
        `Year`
)
SELECT
    YR.`Year`,
    YR.`Account Name`,
    YR.`Yearly Revenue`,
    TYR.`Total Yearly Revenue`,
    (YR.`Yearly Revenue` / TYR.`Total Yearly Revenue`) * 100 AS `Revenue Share (%)`
FROM
    YearlyRevenue YR
JOIN
    TotalYearlyRevenue TYR ON YR.`Year` = TYR.`Year`
ORDER BY
    YR.`Year`, `Account Name`;

