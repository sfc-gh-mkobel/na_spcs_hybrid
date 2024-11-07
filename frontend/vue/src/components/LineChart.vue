<!-- LineChart.vue -->
<template>
    <div>
      <label for="ticker-select">Select Ticker:</label>
      <select v-model="selectedTicker">
        <option v-for="ticker in tickers" :key="ticker" :value="ticker">{{ ticker }}</option>
      </select>
      <canvas ref="lineChart"></canvas>
    </div>
  </template>
  
  <script>
  import { Line } from 'chart.js';
  import axios from 'axios';
  
  export default {
    name: 'LineChart',
    data() {
      return {
        chart: null,            // Reference to the chart instance
        selectedTicker: 'AAPL', // Default ticker
        tickers: ['AAPL', 'MSFT', 'IBM', 'AMZN', 'FDS', 'META'], // List of ticker options
      };
    },
    methods: {
      async fetchData() {
        try {
          // Fetch data from backend, passing the selected ticker as a query parameter
          const baseUrl = process.env.VUE_APP_API_URL
          const response = await axios.get(baseUrl + "/ticks2",{params: {ticker: this.selectedTicker}});
          
          //const response = await axios.get(baseURL + "/ticks"`/api/price-data?ticker=${this.selectedTicker}`);
          const data = response.data;
  
          // Assuming data has `date` and `price` fields
          const labels = data.map((entry) => entry.date);
          const prices = data.map((entry) => entry.last_price);
  
          this.renderChart(labels, prices);
        } catch (error) {
          console.error('Error fetching data:', error);
        }
      },
      renderChart(labels, prices) {
        // Destroy previous chart instance if it exists
        if (this.chart) this.chart.destroy();
  
        // Create a new line chart with colorful and stylized options
        const ctx = this.$refs.lineChart.getContext('2d');
        
        // Create a gradient background for the line
        const gradient = ctx.createLinearGradient(0, 0, 0, 400);
        gradient.addColorStop(0, 'rgba(255, 99, 132, 0.2)');
        gradient.addColorStop(1, 'rgba(54, 162, 235, 0.2)');
  
        this.chart = new Line(ctx, {
          type: 'line',
          data: {
            labels: labels, // X-axis labels (dates)
            datasets: [
              {
                label: `Price (${this.selectedTicker})`,
                data: prices, // Y-axis data (prices)
                borderColor: 'rgba(75, 192, 192, 1)',
                backgroundColor: gradient, // Gradient fill under the line
                borderWidth: 2,
                fill: true, // Fill the area under the line
                pointBackgroundColor: 'rgba(255, 159, 64, 1)',
                pointBorderColor: 'rgba(255, 99, 132, 1)',
                pointRadius: 5,
                pointHoverRadius: 7,
              },
            ],
          },
          options: {
            responsive: true,
            scales: {
              x: {
                title: {
                  display: true,
                  text: 'Date',
                  color: '#333',
                  font: {
                    family: 'Arial',
                    size: 14,
                  },
                },
              },
              y: {
                title: {
                  display: true,
                  text: 'Price',
                  color: '#333',
                  font: {
                    family: 'Arial',
                    size: 14,
                  },
                },
              },
            },
            plugins: {
              legend: {
                display: true,
                labels: {
                  color: '#003366', // Dark blue text for the legend
                },
              },
            },
          },
        });
      },
    },
    watch: {
      // Watch for changes to the selected ticker and fetch new data when it changes
      selectedTicker() {
        this.fetchData();
      },
    },
    mounted() {
      // Fetch data for the default ticker when the component mounts
      this.fetchData();
    },
  };
  </script>
  
  <style scoped>
  canvas {
    max-width: 100%;
    margin-top: 20px;
  }
  
  /* Style the dropdown */
  label {
    font-weight: bold;
    margin-right: 10px;
  }
  
  select {
    padding: 5px;
    font-size: 16px;
    border-radius: 4px;
    border: 1px solid #ddd;
  }
  </style>
  