---
theme: dashboard
title: Ethereum Distribution Dashboard
toc: false
---
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600&display=swap" rel="stylesheet">

<style>
body {
  font-family: Georgia, serif;
  background-color: #FFF1E5;
  color: #33302E;
  line-height: 1.6;
}
h1, h2, h3 {
  font-family: 'Outfit', sans-serif;
  font-weight: 600;
  color: #000000;
  margin-top: 1em;
  margin-bottom: 0.5em;
}
h1 {
  font-size: 2.5em;
  border-bottom: 4px solid #990F3D;
  padding-bottom: 0.2em;
}
h2 {
  font-size: 1.8em;
  border-bottom: 2px solid #990F3D;
  padding-bottom: 0.2em;
}
.card {
  background-color: white;
  border: 1px solid #CCC1B7;
  border-radius: 0;
  padding: 20px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  transition: box-shadow 0.3s ease-in-out;
}
.card:hover {
  box-shadow: 0 5px 15px rgba(0,0,0,0.2);
}
.big {
  font-family: 'Outfit', sans-serif;
  font-size: 2em;
  font-weight: 600;
  color: #990F3D;
}
.eth-amount {
  font-family: 'Outfit', sans-serif;
  display: flex;
  align-items: baseline;
}
.eth-unit {
  font-family: 'Outfit', sans-serif;
  font-size: 1em;
  margin-left: 0.3em;
}
.percentage {
  font-family: 'Outfit', sans-serif;
}
.footer {
  margin-top: 2em;
  padding-top: 1em;
  border-top: 1px solid #CCC1B7;
  font-style: italic;
  color: #66605C;
}
</style>

# Ethereum Distribution

```js
const rawData = await FileAttachment("data/eth_distribution.csv").csv({typed: true});

const data = rawData.map(d => {
  const circulatingSupply = +d['ETH: Circulating Supply'];
  const exchangeBalances = (+d['Exchange Balances %'] / 100) * circulatingSupply;
  const smartContracts = (+d['Smart Contracts %'] / 100) * circulatingSupply;
  const beaconChainStaking = (+d['Beacon Chain Staking %'] / 100) * circulatingSupply;
  const other = circulatingSupply - (exchangeBalances + smartContracts + beaconChainStaking);
  
  return {
    unified_timestamp: new Date(d.unified_timestamp),
    'ETH: Price': +d['ETH: Price'],
    'ETH: Circulating Supply': circulatingSupply,
    'Exchange Balances': exchangeBalances,
    'Smart Contracts': smartContracts,
    'Beacon Chain Staking': beaconChainStaking,
    'Other': other
  };
}).filter(d => !isNaN(d['ETH: Price']) && !isNaN(d['ETH: Circulating Supply']));

const latestData = data[data.length - 1];

function formatNumber(num) {
  return num.toLocaleString('en-US', {maximumFractionDigits: 0});
}

function formatPercentage(num) {
  return (num * 100).toFixed(2) + '%';
}
```

<div class="grid grid-cols-4 gap-4">
  <div class="card">
    <h3>Exchange Balances</h3>
    <div class="eth-amount">
      <span class="big">${formatNumber(latestData['Exchange Balances'])}</span>
      <span class="eth-unit">ETH</span>
    </div>
    <p>(${formatPercentage(latestData['Exchange Balances'] / latestData['ETH: Circulating Supply'])})</p>
  </div>
  <div class="card">
    <h3>Smart Contracts</h3>
    <div class="eth-amount">
      <span class="big">${formatNumber(latestData['Smart Contracts'])}</span>
      <span class="eth-unit">ETH</span>
    </div>
    <p>(${formatPercentage(latestData['Smart Contracts'] / latestData['ETH: Circulating Supply'])})</p>
  </div>
  <div class="card">
    <h3>Beacon Chain Staking</h3>
    <div class="eth-amount">
      <span class="big">${formatNumber(latestData['Beacon Chain Staking'])}</span>
      <span class="eth-unit">ETH</span>
    </div>
    <p>(${formatPercentage(latestData['Beacon Chain Staking'] / latestData['ETH: Circulating Supply'])})</p>
  </div>
  <div class="card">
    <h3>Other</h3>
    <div class="eth-amount">
      <span class="big">${formatNumber(latestData['Other'])}</span>
      <span class="eth-unit">ETH</span>
    </div>
    <p>(${formatPercentage(latestData['Other'] / latestData['ETH: Circulating Supply'])})</p>
  </div>
</div>

## ETH Distribution Over Time

```js
function stackedAreaChart(data, {width} = {}) {
  // Group data by week
  const weeklyData = d3.group(data, d => d3.timeWeek.floor(d.unified_timestamp));
  
  // Aggregate data for each week
  const aggregatedData = Array.from(weeklyData, ([week, values]) => {
    const lastDayData = values[values.length - 1]; // Use the last day of each week
    return {
      week: week,
      'Exchange Balances': lastDayData['Exchange Balances'],
      'Smart Contracts': lastDayData['Smart Contracts'],
      'Beacon Chain Staking': lastDayData['Beacon Chain Staking'],
      'Other': lastDayData['Other']
    };
  });

  const stackedData = aggregatedData.flatMap(d => [
    {date: d.week, value: d['Exchange Balances'], category: 'Exchange Balances'},
    {date: d.week, value: d['Smart Contracts'], category: 'Smart Contracts'},
    {date: d.week, value: d['Beacon Chain Staking'], category: 'Beacon Chain Staking'},
    {date: d.week, value: d['Other'], category: 'Other'}
  ]);

  return Plot.plot({
    width,
    height: 500,
    marginLeft: 70,
    y: {
      grid: true,
      label: "↑ ETH",
      transform: d => d / 1e6,
      tickFormat: d => d + "M"
    },
    x: {
      type: "time",
      label: "Date →",
      tickFormat: d3.timeFormat("%b %Y") // Format x-axis labels as "Mon YYYY"
    },
    marks: [
      Plot.areaY(stackedData, {
        x: "date",
        y: "value",
        fill: "category",
        title: d => `${d.category}: ${formatNumber(d.value)} ETH`
      }),
      Plot.ruleY([0])
    ],
    color: {
      domain: ["Exchange Balances", "Smart Contracts", "Beacon Chain Staking", "Other"],
      range: ["#990F3D", "#0D7680", "#FF9E00", "#4D4845"],
      legend: true
    },
    style: {
      backgroundColor: "white",
      color: "#33302E",
      fontFamily: "'Outfit', sans-serif",
      fontSize: 13
    },
    legend: {
      color: {
        label: "Category",
        columns: "180px"
      }
    }
  });
}
```

<div class="card">
  ${resize((width) => stackedAreaChart(data, {width}))}
</div>

## ETH Circulating Supply Over Time

```js
function circulatingSupplyChart(data, {width} = {}) {
  return Plot.plot({
    width,
    height: 300,
    marginLeft: 70,
    y: {
      grid: true,
      label: "↑ ETH",
      transform: d => d / 1e6,
      tickFormat: d => d + "M"
    },
    x: {
      type: "time",
      label: "Date →"
    },
    marks: [
      Plot.line(data, {
        x: "unified_timestamp",
        y: "ETH: Circulating Supply",
        stroke: "#990F3D",
        strokeWidth: 2
      }),
      Plot.ruleY([0])
    ],
    style: {
      backgroundColor: "white",
      color: "#1A1A1A",
      fontFamily: "'Outfit', sans-serif",
      fontSize: 13
    }
  });
}
```

<div class="card">
  ${resize((width) => circulatingSupplyChart(data, {width}))}
</div>

<div class="grid grid-cols-2 gap-4 mt-4">
  <div class="card">
    <h3>Current ETH Price</h3>
    <span class="big">$${latestData['ETH: Price'].toFixed(2)}</span>
  </div>
  <div class="card">
    <h3>Total Circulating Supply</h3>
    <div class="eth-amount">
      <span class="big">${formatNumber(latestData['ETH: Circulating Supply'])}</span>
      <span class="eth-unit">ETH</span>
    </div>
  </div>
</div>

*Data updated from GlassNode, as of ${latestData.unified_timestamp.toLocaleDateString()}*

```

```
