-- models/marts/fact/walmart_fact_table.sql
-- Fact table with SCD2 versioning
-- Reads from walmart_fact_snapshot and transforms dbt snapshot columns to business-friendly names
-- vrsn_start_date = when this version became active
-- vrsn_end_date = when this version was superseded (9999-12-31 if current)
-- is_current = flag indicating the active version

{{ config(
    materialized='view',
    schema='analytics'
) }}

with snapshot_data as (
    select
        store_id,
        dept_id,
        date_id,
        weekly_sales,
        fuel_price,
        store_temperature,
        unemployment,
        cpi,
        markdown1,
        markdown2,
        markdown3,
        markdown4,
        markdown5,
        -- SCD2 columns from dbt snapshot
        dbt_scd_id,
        dbt_valid_from,
        dbt_valid_to,
        dbt_updated_at
    from {{ ref('walmart_fact_snapshot') }}
)

select
    -- Business keys
    store_id,
    dept_id,
    date_id,
    
    -- Measures
    weekly_sales,
    fuel_price,
    store_temperature,
    unemployment,
    cpi,
    markdown1,
    markdown2,
    markdown3,
    markdown4,
    markdown5,
    
    -- SCD2 versioning columns with business-friendly names
    dbt_valid_from as vrsn_start_date,
    coalesce(dbt_valid_to, cast('9999-12-31 23:59:59' as timestamp_ntz)) as vrsn_end_date,
    case 
        when dbt_valid_to is null then true 
        else false 
    end as is_current,
    
    -- Audit columns
    dbt_scd_id as row_version_id,
    dbt_updated_at as dbt_last_updated
    
from snapshot_data