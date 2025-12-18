-- snapshots/walmart_fact_snapshot.sql
-- SCD2 implementation using dbt snapshot
-- unique_key = (store_id, dept_id) - tracks versions for each store-department combination
-- strategy = check - detects changes in any of the measure columns
-- When data changes for a store_id + dept_id:
--   1. Existing active record gets dbt_valid_to set to current_timestamp
--   2. New record inserted with dbt_valid_from = current_timestamp, dbt_valid_to = NULL

{% snapshot walmart_fact_snapshot %}

{{
    config(
        target_database='walmart_db',
        target_schema='snapshots',
        unique_key="store_id || '-' || dept_id",
        strategy='check',
        check_cols=[
            'date_id',
            'weekly_sales',
            'fuel_price',
            'store_temperature',
            'unemployment',
            'cpi',
            'markdown1',
            'markdown2',
            'markdown3',
            'markdown4',
            'markdown5'
        ],
        invalidate_hard_deletes=True
    )
}}

with fact_source as (
    select
        d.store as store_id,
        d.dept as dept_id,
        {{ dbt_utils.generate_surrogate_key(['f.store_date']) }} as date_id,
        d.weekly_sales,
        f.fuel_price,
        f.store_temperature,
        f.unemployment,
        f.cpi,
        f.markdown1,
        f.markdown2,
        f.markdown3,
        f.markdown4,
        f.markdown5
    from {{ source('raw_walmart', 'department') }} d
    inner join {{ source('raw_walmart', 'fact') }} f
        on d.store = f.store
        and d.date = f.date
    where d.date is not null
)

select * from fact_source

{% endsnapshot %}