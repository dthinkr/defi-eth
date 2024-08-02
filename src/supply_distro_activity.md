---
theme: dashboard
title: Ethereum Supply Last Active Dashboard
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

# Ethereum Supply Last Active

```js
const rawData = await FileAttachment("data/processed_eth_supply_last_active.csv").csv({typed: true});

const data = rawData.map(d => ({
  unified_timestamp: new Date(d.unified_timestamp),
  'Supply Last Active 7y-10y': parseFloat(d['Supply Last Active 7y-10y']),
  'Supply Last Active 5y-7y': parseFloat(d['Supply Last Active 5y-7y']),
  'Supply Last Active >10y': parseFloat(d['Supply Last Active >10y']),
  'Circulating Supply': parseFloat(d['Circulating Supply'])
}));

const latestData = data[data.length - 1];

function formatNumber(num) {
  return num.toLocaleString('en-US', {maximumFractionDigits: 0});
}

```

<div class="grid grid-cols-4 gap-4">
  <div class="card">
    <h3>Supply Last Active 7y-10y</h3>
    <div class="eth-amount">
      <span class="big">${formatNumber(latestData['Supply Last Active 7y-10y'])}</span>
      <span class="eth-unit">ETH</span>
    </div>
    <p>(${(latestData['Supply Last Active 7y-10y'] / latestData['Circulating Supply']).toFixed(2)}%)</p>
  </div>
  <div class="card">
    <h3>Supply Last Active 5y-7y</h3>
    <div class="eth-amount">
      <span class="big">${formatNumber(latestData['Supply Last Active 5y-7y'])}</span>
      <span class="eth-unit">ETH</span>
    </div>
    <p>(${(latestData['Supply Last Active 5y-7y'] / latestData['Circulating Supply']).toFixed(2)}%)</p>
  </div>
  <div class="card">
    <h3>Supply Last Active >10y</h3>
    <div class="eth-amount">
      <span class="big">${formatNumber(latestData['Supply Last Active >10y'])}</span>
      <span class="eth-unit">ETH</span>
    </div>
    <p>(${(latestData['Supply Last Active >10y'] / latestData['Circulating Supply']).toFixed(2)}%)</p>
  </div>
  <div class="card">
    <h3>Circulating Supply</h3>
    <div class="eth-amount">
      <span class="big">${formatNumber(latestData['Circulating Supply'])}</span>
      <span class="eth-unit">ETH</span>
    </div>
  </div>
</div>

## ETH Supply Last Active Over Time

```js
function supplyLastActiveChart(data, {width} = {}) {
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
      tickFormat: d3.timeFormat("%b %Y")
    },
    marks: [
      Plot.line(data, {
        x: "unified_timestamp",
        y: "Circulating Supply",
        stroke: "#66605C",
        strokeWidth: 2
      }),
      Plot.line(data, {
        x: "unified_timestamp",
        y: "Supply Last Active 7y-10y",
        stroke: "#990F3D",
        strokeWidth: 2
      }),
      Plot.line(data, {
        x: "unified_timestamp",
        y: "Supply Last Active 5y-7y",
        stroke: "#0D7680",
        strokeWidth: 2
      }),
      Plot.line(data, {
        x: "unified_timestamp",
        y: "Supply Last Active >10y",
        stroke: "#FF9E00",
        strokeWidth: 2
      }),
      Plot.ruleY([0])
    ],
    color: {
      domain: ["Circulating Supply", "Supply Last Active 7y-10y", "Supply Last Active 5y-7y", "Supply Last Active >10y"],
      range: ["#66605C", "#990F3D", "#0D7680", "#FF9E00"],
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
  ${resize((width) => supplyLastActiveChart(data, {width}))}
</div>

*Data updated from GlassNode, as of ${latestData.unified_timestamp.toLocaleDateString()}*




