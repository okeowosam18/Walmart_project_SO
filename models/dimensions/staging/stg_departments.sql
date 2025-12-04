-- models/staging/stg_departments.sql
-- Staging model for department sales data

{{ config(
    materialized='view',
    schema='staging'
) }}

with source_data as (
    select
        Store,
        Dept,
        Date as Store_Date,
        Weekly_Sales,
        IsHoliday
    from {{ source('raw_walmart', 'department') }}
)

select
    Store,
    Dept,
    Store_Date,
    Weekly_Sales,
    case 
        when upper(IsHoliday) in ('TRUE', 'T', '1', 'YES') then 'TRUE'
        else 'FALSE'
    end as IsHoliday,
    current_timestamp() as loaded_at
from source_data
where Store_Date is not null