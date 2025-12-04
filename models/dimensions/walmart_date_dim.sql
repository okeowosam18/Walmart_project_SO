{{ config(
    materialized='incremental',
    unique_key='Date_id',
    merge_update_columns=['IsHoliday', 'Update_date'],
    schema='analytics'
) }}

with date_records as (
    select distinct
        Store_Date,
        IsHoliday
    from {{ ref('stg_departments') }}
    
    {% if is_incremental() %}
    where Store_Date > (select max(Store_Date) from {{ this }})
    {% endif %}
),

add_surrogate_key as (
    select
        {{ dbt_utils.generate_surrogate_key(['Store_Date']) }} as Date_id,
        Store_Date,
        IsHoliday,
        current_timestamp() as Insert_date,
        current_timestamp() as Update_date
    from date_records
)

select * from add_surrogate_key