<template>
  <div>
    <label for="ticker-select">Select Ticker:</label>
    <select v-model="selectedTicker">
      <option v-for="ticker in tickers" :key="ticker" :value="ticker">{{ ticker }}</option>
    </select>
  </div>
  <div>
      <header class="banner">
          <h1>Snowflake Stock Data</h1>
      </header>
    <!-- The v-if is used to conditionally render a block -->
    <Line id="my-chart-id" v-if="loaded" :options="chartOptions" :data="chartData" :width="600" />
  </div>
</template>

<script>
import { Line } from 'vue-chartjs'

import {
Chart as ChartJS,
CategoryScale,
LinearScale,
PointElement,
LineElement,
Title,
Tooltip,
Legend
} from 'chart.js'

ChartJS.register(
CategoryScale,
LinearScale,
PointElement,
LineElement,
Title,
Tooltip,
Legend
)
import axios from 'axios'
export default {
  name: 'LineChart',
  components: { Line },
  data: () => ({
    // Prevents chart to mount before the API data arrives
    loaded: false,
    selectedTicker: 'AMZN', // Default ticker
    tickers: ['AAPL', 'MSFT', 'IBM', 'AMZN', 'FDS', 'META'], // List of ticker options
    chartData: {
      labels: [],
      datasets: [
        {
          label: 'My Label',
          data: [],
          backgroundColor: '#f87979'
        }
      ]
    },
    chartOptions: {
      responsive: true
    }
  }),
   async mounted() {
    
    const apiUrl = process.env.VUE_APP_API_URL
  
  // Make an HTTP request to fetch the data from the API endpoint
  await axios.get(apiUrl + "/ticks2",{params: {ticker: this.selectedTicker}})
  
    .then((r) => {

      const labels = r.map(item => new Date(item.DATE).toLocaleDateString());
      const avgPrices = r.map(item => item.AVG_PRICE);
      const movingAvg = r.map(item => item.M_AVG);
      const ticker = r.map(item => item.TICKER);
      this.chartData = {labels: labels, datasets: [
        {data:avgPrices,
          label: ticker[0],
          borderColor: 'rgb(75, 192, 192)', 
          tension: 0.5, 
          pointBorderColor: 'rgb(255,0,0)', 
          pointBackgroundColor: 'rgb(255,0,0)', 
          pointRadius: 10, 
          spanGaps: true, 
          pointHoverRadius: 20, 
          pointStyle: 'rectRot'
        },
        {data:movingAvg,
          label: ticker[0],
          borderColor: 'rgb(75, 192, 192)', 
          tension: 0.5, 
          pointBorderColor: 'rgb(0,255,0)', 
          pointBackgroundColor: 'rgb(255,0,0)', 
          pointRadius: 10, 
          spanGaps: true, 
          pointHoverRadius: 20, 
          pointStyle: 'rectRot'
        }
      ]}})
        this.loaded = true
    
      }
  }

</script>
<style scoped>
/* Banner styling */
.banner {
  background-color: #add8e6; /* Light blue */
  padding: 20px;
  text-align: center;
  color: #003366; /* Dark blue text for contrast */
  font-size: 24px;
  font-weight: bold;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

main {
  margin: 20px;
}
</style>