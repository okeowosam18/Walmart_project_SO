{{ config(
    materialized='view',
    schema='staging'
) }}

with source_data as (
    select
        Store,
        Date as Store_Date,
        Temperature,
        Fuel_Price,
        MarkDown1,
        MarkDown2,
        MarkDown3,
        MarkDown4,
        MarkDown5,
        CPI,
        Unemployment,
        IsHoliday
    from {{ source('raw_walmart', 'fact') }}
)

select
    Store,
    Store_Date,
    Temperature as Store_Temperature,
    Fuel_Price,
    coalesce(try_to_number(MarkDown1), 0) as MarkDown1,
    coalesce(try_to_number(MarkDown2), 0) as MarkDown2,
    coalesce(try_to_number(MarkDown3), 0) as MarkDown3,
    coalesce(try_to_number(MarkDown4), 0) as MarkDown4,
    coalesce(try_to_number(MarkDown5), 0) as MarkDown5,
    CPI,
    Unemployment,
    case 
        when upper(IsHoliday) in ('TRUE', 'T', '1', 'YES') then 'TRUE'
        else 'FALSE'
    end as IsHoliday,
    current_timestamp() as loaded_at
from source_data
where Store_Date is not null