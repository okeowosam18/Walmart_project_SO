-- models/marts/dim/walmart_store_dim.sql
-- Store-Department dimension table with SCD1 (upsert logic)
-- unique_key = (store_id, dept_id) as composite key
-- On change: updates store_type, store_size, and update_date via MERGE

{{ config(
    materialized='incremental',
    unique_key=['store_id', 'dept_id'],
    merge_update_columns=['store_type', 'store_size', 'update_date'],
    schema='analytics'
) }}

with store_dept_combinations as (
    -- Get all unique store-department combinations from departments
    select distinct
        d.store as store_id,
        d.dept as dept_id
    from {{ ref('stg_departments') }} d
),

enriched as (
    -- Join with store attributes
    select
        sdc.store_id,
        sdc.dept_id,
        s.store_type,
        s.store_size,
        current_timestamp() as insert_date,
        current_timestamp() as update_date
    from store_dept_combinations sdc
    left join {{ ref('stg_stores') }} s
        on sdc.store_id = s.store
)

select * from enriched