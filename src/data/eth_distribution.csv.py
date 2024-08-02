import polars as pl
import sys

# Read the CSV file
file_path = "src/data/ethereum-supply-macro-distribution.csv"
df = pl.read_csv(file_path)

# Process timestamps
timestamp_cols = [col for col in df.columns if 'timestamp' in col.lower()]
for col in timestamp_cols:
    df = df.with_columns(pl.col(col).str.to_datetime(format='%Y-%m-%dT%H:%M:%S%.fZ', strict=False))

df = df.with_columns(pl.coalesce(*[pl.col(col) for col in timestamp_cols]).alias('unified_timestamp'))
df = df.drop(timestamp_cols).sort('unified_timestamp').filter(pl.col('unified_timestamp').is_not_null())

# Select and process relevant columns
df = df.select([
    'unified_timestamp',
    'ETH: Price',
    'ETH: Circulating Supply',
    'Beacon Chain Staking',
    'Smart Contracts',
    'Exchange Balances'
]).fill_null(strategy='forward')

# Convert string columns to float where appropriate
df = df.with_columns([
    pl.col('Beacon Chain Staking').cast(pl.Float64),
])

# Calculate percentages
df = df.with_columns([
    (pl.col('Exchange Balances') * 100).alias('Exchange Balances %'),
    ((pl.col('Smart Contracts') - pl.col('Exchange Balances')) * 100).alias('Smart Contracts %'),
    ((pl.col('Beacon Chain Staking') - pl.col('Smart Contracts')) * 100).alias('Beacon Chain Staking %')
])

# Select final columns
df = df.select([
    'unified_timestamp',
    'ETH: Price',
    'ETH: Circulating Supply',
    'Beacon Chain Staking %',
    'Smart Contracts %',
    'Exchange Balances %'
])

# Output CSV to stdout
df.write_csv(sys.stdout)