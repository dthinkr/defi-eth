import polars as pl
import sys
from datetime import datetime, timedelta

# File path
file_path = "src/data/eth-supply-last-active.csv"

# Read the CSV file
df = pl.read_csv(file_path, separator=',', has_header=False)

# Rename columns
df = df.rename({
    'column_1': 'timestamp',
    'column_2': 'ETH: Supply Last Active 7y-10y',
    'column_3': 'timestamp_2',
    'column_4': 'ETH: Supply Last Active 5y-7y',
    'column_5': 'timestamp_3',
    'column_6': 'ETH: Supply Last Active >10y',
    'column_7': 'timestamp_4',
    'column_8': 'ETH: Circulating Supply'
})

# Remove the first row (header)
df = df.slice(1)

# Process timestamps
timestamp_cols = [col for col in df.columns if 'timestamp' in col.lower()]
for col in timestamp_cols:
    df = df.with_columns(pl.col(col).str.to_datetime(format='%Y-%m-%dT%H:%M:%S%.fZ', strict=False))

df = df.with_columns(pl.coalesce(*[pl.col(col) for col in timestamp_cols]).alias('unified_timestamp'))
df = df.drop(timestamp_cols).sort('unified_timestamp')

# Function to get the start of the week
def get_week_start(date):
    return (date - timedelta(days=date.weekday())).date()

# Select relevant columns, convert to float, handle NaN
df = df.select([
    pl.col('unified_timestamp').dt.date().map_elements(get_week_start).alias('unified_timestamp'),
    pl.col('ETH: Supply Last Active 7y-10y').cast(pl.Float64).fill_nan(None).alias('Supply Last Active 7y-10y'),
    pl.col('ETH: Supply Last Active 5y-7y').cast(pl.Float64).fill_nan(None).alias('Supply Last Active 5y-7y'),
    pl.col('ETH: Supply Last Active >10y').cast(pl.Float64).fill_nan(None).alias('Supply Last Active >10y'),
    pl.col('ETH: Circulating Supply').cast(pl.Float64).fill_nan(None).alias('Circulating Supply')
])

# Aggregate to weekly and fill missing values
df = df.groupby('unified_timestamp').agg([
    pl.col('Supply Last Active 7y-10y').mean(),
    pl.col('Supply Last Active 5y-7y').mean(),
    pl.col('Supply Last Active >10y').mean(),
    pl.col('Circulating Supply').mean()
]).sort('unified_timestamp')

# Forward fill missing values
df = df.select([
    pl.col('unified_timestamp'),
    pl.col('Supply Last Active 7y-10y').forward_fill(),
    pl.col('Supply Last Active 5y-7y').forward_fill(),
    pl.col('Supply Last Active >10y').forward_fill(),
    pl.col('Circulating Supply').forward_fill()
])

# Backward fill any remaining missing values
df = df.select([
    pl.col('unified_timestamp'),
    pl.col('Supply Last Active 7y-10y').backward_fill(),
    pl.col('Supply Last Active 5y-7y').backward_fill(),
    pl.col('Supply Last Active >10y').backward_fill(),
    pl.col('Circulating Supply').backward_fill()
])

# Round all numeric values to 2 decimal places
numeric_cols = ['Supply Last Active 7y-10y', 'Supply Last Active 5y-7y', 'Supply Last Active >10y', 'Circulating Supply']
for col in numeric_cols:
    df = df.with_columns(pl.col(col).round(2))

# Convert unified_timestamp back to string format
df = df.with_columns(pl.col('unified_timestamp').dt.strftime('%Y-%m-%d'))

# Write to CSV
df.write_csv(sys.stdout, separator=',')

print(df)