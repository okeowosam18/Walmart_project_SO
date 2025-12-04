-- models/dimensions/walmart_store_dim.sql
-- Store dimension table with SCD1 (upsert logic)

{{ config(
    materialized='incremental',
    unique_key=['Store_id', 'Dept_id'],
    merge_update_columns=['Store_type', 'Store_size', 'Update_date'],
    schema='analytics'
) }}

with store_dept_combinations as (
    select distinct
        d.Store as Store_id,
        d.Dept as Dept_id
    from {{ ref('stg_departments') }} d
    
    {% if is_incremental() %}
    where not exists (
        select 1 
        from {{ this }} existing
        where existing.Store_id = d.Store 
        and existing.Dept_id = d.Dept
    )
    {% endif %}
),

add_store_details as (
    select
        sdc.Store_id,
        sdc.Dept_id,
        s.Store_Type,
        s.Store_Size,
        current_timestamp() as Insert_date,
        current_timestamp() as Update_date
    from store_dept_combinations sdc
    left join {{ ref('stg_stores') }} s
        on sdc.Store_id = s.Store
)

select * from add_store_details