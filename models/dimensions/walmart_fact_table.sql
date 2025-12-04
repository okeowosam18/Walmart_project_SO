{{ config(
    materialized='incremental',
    unique_key=['Store_id', 'Dept_id', 'Date_id'],
    schema='analytics'
) }}

with new_records as (
    select
        d.Store as Store_id,
        d.Dept as Dept_id,
        {{ dbt_utils.generate_surrogate_key(['f.Store_Date']) }} as Date_id,
        d.Weekly_Sales as Store_Weekly_sales,
        f.Fuel_Price,
        f.Store_Temperature,
        f.Unemployment,
        f.CPI,
        f.MarkDown1,
        f.MarkDown2,
        f.MarkDown3,
        f.MarkDown4,
        f.MarkDown5,
        current_timestamp() as Insert_date,
        current_timestamp() as Update_date,
        current_timestamp() as Vrsn_start_date,
        cast('9999-12-31 23:59:59' as timestamp) as Vrsn_end_date
    from {{ ref('stg_departments') }} d
    inner join {{ ref('stg_facts') }} f
        on d.Store = f.Store
        and d.Store_Date = f.Store_Date
    
    {% if is_incremental() %}
    where not exists (
        select 1 
        from {{ this }} existing
        where existing.Store_id = d.Store
          and existing.Dept_id = d.Dept
          and existing.Date_id = {{ dbt_utils.generate_surrogate_key(['f.Store_Date']) }}
          and existing.Vrsn_end_date = cast('9999-12-31 23:59:59' as timestamp)
    )
    {% endif %}
)

{% if is_incremental() %}
, changed_records as (
    select
        existing.Store_id,
        existing.Dept_id,
        existing.Date_id,
        existing.Store_Weekly_sales,
        existing.Fuel_Price,
        existing.Store_Temperature,
        existing.Unemployment,
        existing.CPI,
        existing.MarkDown1,
        existing.MarkDown2,
        existing.MarkDown3,
        existing.MarkDown4,
        existing.MarkDown5,
        existing.Insert_date,
        current_timestamp() as Update_date,
        existing.Vrsn_start_date,
        current_timestamp() as Vrsn_end_date
    from {{ this }} existing
    inner join (
        select
            d.Store as Store_id,
            d.Dept as Dept_id,
            {{ dbt_utils.generate_surrogate_key(['f.Store_Date']) }} as Date_id,
            d.Weekly_Sales as Store_Weekly_sales,
            f.Fuel_Price,
            f.Store_Temperature,
            f.Unemployment,
            f.CPI,
            f.MarkDown1,
            f.MarkDown2,
            f.MarkDown3,
            f.MarkDown4,
            f.MarkDown5
        from {{ ref('stg_departments') }} d
        inner join {{ ref('stg_facts') }} f
            on d.Store = f.Store
           and d.Store_Date = f.Store_Date
    ) incoming
        on existing.Store_id = incoming.Store_id
       and existing.Dept_id = incoming.Dept_id
       and existing.Date_id = incoming.Date_id
       and existing.Vrsn_end_date = cast('9999-12-31 23:59:59' as timestamp)
    where (
        existing.Store_Weekly_sales != incoming.Store_Weekly_sales
        or existing.Fuel_Price != incoming.Fuel_Price
        or existing.Store_Temperature != incoming.Store_Temperature
        or existing.Unemployment != incoming.Unemployment
        or existing.CPI != incoming.CPI
        or existing.MarkDown1 != incoming.MarkDown1
        or existing.MarkDown2 != incoming.MarkDown2
        or existing.MarkDown3 != incoming.MarkDown3
        or existing.MarkDown4 != incoming.MarkDown4
        or existing.MarkDown5 != incoming.MarkDown5
    )
),
all_records as (
    select * from new_records
    union all
    select * from changed_records
)

select * from all_records
{% else %}
select * from new_records
{% endif %}