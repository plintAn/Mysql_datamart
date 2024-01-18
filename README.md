# Mysql_datamart
Mysql에서 데이터 마트를 수행합니다
### 데이터 구조 정의

```sql
-- 'datamart_db' 스키마 활성화
use datamart_db;

-- 지역 정보를 저장하는 REGION 테이블 생성
CREATE TABLE region (
  ID SERIAL PRIMARY KEY,  -- 각 지역의 고유 ID
  NAME VARCHAR(255) NOT NULL  -- 지역 이름
);

-- 영업 사원 정보를 저장하는 SALES_REP 테이블 생성
CREATE TABLE SALES_REP (
  ID SERIAL PRIMARY KEY,  -- 각 영업 사원의 고유 ID
  NAME VARCHAR(255) NOT NULL,  -- 영업 사원 이름
  REGION_ID INT REFERENCES REGION(ID)  -- 소속 지역 ID
);

-- 고객 계정을 저장하는 ACCOUNTS 테이블 생성
CREATE TABLE account (
  ID SERIAL PRIMARY KEY,  -- 각 계정의 고유 ID
  NAME VARCHAR(255) NOT NULL,  -- 계정 이름
  WEBSITE VARCHAR(255),  -- 계정 웹사이트
  LAT DECIMAL(9,6),  -- 계정 위도
  longitude float(9,6),  -- 계정 경도
  PRIMARY_POC VARCHAR(255),  -- 주요 연락처
  SALES_REP_ID INT REFERENCES SALES_REP(ID)  -- 담당 영업 사원 ID
);

-- 웹 활동 데이터를 저장하는 WEB_EVENTS 테이블 생성
CREATE TABLE WEB_EVENTS (
  ID SERIAL PRIMARY KEY,  -- 각 이벤트의 고유 ID
  ACCOUNT_ID INT REFERENCES ACCOUNTS(ID),  -- 이벤트와 관련된 계정 ID
  OCCURRED_AT TIMESTAMP,  -- 이벤트 발생 시간
  CHANNEL VARCHAR(255)  -- 이벤트 발생 채널 (예: 이메일, 웹사이트)
);

-- 주문 세부 정보를 저장하는 ORDERS 테이블 생성
CREATE TABLE ORDERS (
  ID SERIAL PRIMARY KEY,  -- 각 주문의 고유 ID
  ACCOUNT_ID INT REFERENCES ACCOUNTS(ID),  -- 주문한 계정 ID
  OCCURRED_AT TIMESTAMP,  -- 주문 발생 시간
  STANDARD_QTY INT,  -- 주문한 표준 제품 수량
  GLOSS_QTY INT,  -- 주문한 광택 제품 수량
  POSTER_QTY INT,  -- 주문한 포스터 제품 수량
  TOTAL INT,  -- 주문한 제품 총 수량
  STANDARD_AMOUNT_USD DECIMAL(10, 2),  -- 표준 제품 총 금액
  GLOSS_AMOUNT_USD DECIMAL(10, 2),  -- 광택 제품 총 금액
  POSTER_AMOUNT_USD DECIMAL(10, 2),  -- 포스터 제품 총 금액
  TOTAL_AMOUNT_USD DECIMAL(10, 2)  -- 주문 총 금액
);

```


* 각 테이블의 데이터 보기

![image](https://github.com/plintAn/Mysql_datamart/assets/124107186/d8ac2a0f-b589-4aa7-82ea-7189fa028e90)

### 데이터 스키마 원본 데이터 삽입

* datamart_db 스키마 탐색기에서 Table data import wizard 를 선택하여 각각의 데이터를 불러온다

![image](https://github.com/plintAn/Mysql_datamart/assets/124107186/42f16bd5-6f3e-4ca1-9db4-fa20454d6445)

* 다음과 같이 정해둔 데이터 구조에 데이터를 가져올 수 있다.

![image](https://github.com/plintAn/Mysql_datamart/assets/124107186/faab4be5-973a-4828-8e6f-1da80d98a85b)

```SQL
SHOW TABLES;
```

## 데이터 마트

* 1: 어떤 영업 담당자가 어떤 고객을 담당합니까?
```sql
SELECT
    SR.NAME AS SALES_REP_NAME,
    A.NAME AS ACCOUNT_NAME
FROM
    SALES_REP SR
JOIN
    ACCOUNTS A ON SR.ID = A.SALES_REP_ID
ORDER BY
    SR.NAME, A.NAME;
```

![image](https://github.com/plintAn/Mysql_datamart/assets/124107186/5a7e9cfe-1a25-4448-af7e-bcf793e36fab)


* 2 ## 회사는 어떤 계정이 수익의 대부분을 차지하는지 알아야 하며,
* 2 ## 또한 기업에서는 각 계정의 수익 기여도에 대한 연간 추세를 확인
```sql
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
```

![image](https://github.com/plintAn/Mysql_datamart/assets/124107186/29915a6b-e6de-47e9-aa86-a73ece81897b)



* 3 ## 마지막 표에는 매년 총 수익 중 각 계정의 수익 지분을 표시
* 3 ## 최종 테이블은 아래와 같다

```sql
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
```
![image](https://github.com/plintAn/Mysql_datamart/assets/124107186/87ab1635-b0b1-4f90-81f8-d8826fc19827)

