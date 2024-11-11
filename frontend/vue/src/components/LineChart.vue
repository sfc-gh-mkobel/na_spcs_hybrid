<template>
  <div>
    <div>
      <h1>Mocked Data</h1>
      <pre>{{ apiData }}</pre>
      <canvas id="myChart"></canvas>
    </div>
  </div>
</template>

<script>
import Chart from 'chart.js/auto';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';

export default {
  data() {
    return { 
      apiData: null,
      chartData: {
        labels: [],
        datasets: []
      } 
    };
  },
  mounted() {
    this.get_data();
  },
  methods: {
    get_data() {

      const baseUrl = process.env.VUE_APP_API_URL;


      const mock = new MockAdapter(axios);
      //const baseUrl = 'https://mock-api.example.com'; // Replace with your actual base URL or a placeholder
      // Define the mock response for the GET request
      mock.onGet(`${baseUrl}/ticks`).reply(200, {
        data: [
          { ticker: 'AAPL', date: '2024-11-01', last_price: 11 },
          { ticker: 'AAPL', date: '2024-11-02', last_price: 10 },
          { ticker: 'AAPL', date: '2024-11-03', last_price: 12 }
        ]
      });

      // Make the GET request
      // axios.get(baseUrl + "/ticks", 
      //           {params: {start_range: this.begin, end_range: this.end, topn: this.topn}})
      axios.get(`${baseUrl}/ticks`,{params: {start_range: this.begin, end_range: this.end, topn: this.topn}})
        .then(response => {
          this.apiData = response.data.data;
          this.updateChartData();
          this.renderChart();
        })
        .catch(error => {
          console.error("Error reading ticks", error);
        });
    },
    updateChartData() {
      this.chartData.labels = this.apiData.map(item => item.date);
      this.chartData.datasets = [{
        label: 'Last Price',
        backgroundColor: '#f87979',
        data: this.apiData.map(item => item.last_price)
      }];
    },
    renderChart() {
      new Chart(document.getElementById('myChart'), {
        type: 'line',
        data: this.chartData,
        options: {
          responsive: true,
          maintainAspectRatio: false
        }
      });
    }
  }
};
</script>

<style> #myChart { max-width: 400px; /* Adjust the max-width to make the chart smaller */ 
                   height: 200px; /* Adjust the height as needed */ } 
                   div { display: flex; flex-direction: column; align-items: center; /* Center align the content */ }
</style>
