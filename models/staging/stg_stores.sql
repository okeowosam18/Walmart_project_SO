{{ config(
    materialized='view',
    schema='staging'
) }}

with source_data as (
    select
        Store,
        Type as Store_Type,
        Size as Store_Size
    from {{ source('raw_walmart', 'stores') }}
)

select
    Store,
    Store_Type,
    Store_Size,
    current_timestamp() as loaded_at
from source_data
where Store is not null