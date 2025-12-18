-- models/marts/dim/walmart_date_dim.sql
-- Date dimension table with SCD1 (upsert logic)
-- On change: updates is_holiday and update_date columns via MERGE
-- unique_key ensures MERGE behavior in Snowflake

{{ config(
    materialized='incremental',
    unique_key='date_id',
    merge_update_columns=['is_holiday', 'update_date'],
    schema='analytics'
) }}

with source_dates as (
    select distinct
        store_date,
        isholiday as is_holiday
    from {{ ref('stg_departments') }}
    where store_date is not null
),

transformed as (
    select
        {{ dbt_utils.generate_surrogate_key(['store_date']) }} as date_id,
        store_date,
        is_holiday,
        extract(year from store_date) as year,
        extract(month from store_date) as month,
        extract(day from store_date) as day,
        extract(dayofweek from store_date) as day_of_week,
        extract(week from store_date) as week_of_year,
        extract(quarter from store_date) as quarter,
        current_timestamp() as insert_date,
        current_timestamp() as update_date
    from source_dates
)

select * from transformed