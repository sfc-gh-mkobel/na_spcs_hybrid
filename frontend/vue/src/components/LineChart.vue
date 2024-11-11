<template>
  <div>
    <div>
      <pre>{{ apiData }}</pre>
      <!-- <pre>{{ this.chartData.labels }}</pre>
      <pre>{{ this.chartData.datasets }}</pre> -->
      <canvas id="myChart"></canvas>
    </div>
  </div>
</template>

<script>
import Chart from 'chart.js/auto';
import axios from 'axios';
//import MockAdapter from 'axios-mock-adapter';

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


//       const mock = new MockAdapter(axios);
//       //const baseUrl = 'https://mock-api.example.com'; // Replace with your actual base URL or a placeholder
//       // Define the mock response for the GET request
//       mock.onGet(`${baseUrl}/ticks`).reply(200, 
//       [
//   {"DATE": "Mon, 02 May 2022 00:00:00 GMT","LAST_PRICE": 2427.8854770893095,"TICKER": "AMZN"},{
//     "DATE": "Tue, 03 May 2022 00:00:00 GMT",
//     "LAST_PRICE": 2486.773330354257,
//     "TICKER": "AMZN"},{
//     "DATE": "Wed, 04 May 2022 00:00:00 GMT",
//     "LAST_PRICE": 2442.73218304295,
//     "TICKER": "AMZN"},{
//     "DATE": "Thu, 05 May 2022 00:00:00 GMT",
//     "LAST_PRICE": 2350.783606726394,
//     "TICKER": "AMZN"},{
//     "DATE": "Fri, 06 May 2022 00:00:00 GMT",
//     "LAST_PRICE": 2304.473794746725,
//     "TICKER": "AMZN"},{
//     "DATE": "Mon, 09 May 2022 00:00:00 GMT",
//     "LAST_PRICE": 2213.341265756603,
//     "TICKER": "AMZN"
//   },
//   {
//     "DATE": "Tue, 10 May 2022 00:00:00 GMT",
//     "LAST_PRICE": 2187.8610261653553,
//     "TICKER": "AMZN"
//   },
//   {
//     "DATE": "Wed, 11 May 2022 00:00:00 GMT",
//     "LAST_PRICE": 2137.051100900347,
//     "TICKER": "AMZN"
//   },
//   {
//     "DATE": "Fri, 13 May 2022 00:00:00 GMT",
//     "LAST_PRICE": 2223.812173890667,
//     "TICKER": "AMZN"
//   },
//   {
//     "DATE": "Mon, 16 May 2022 00:00:00 GMT",
//     "LAST_PRICE": 2233.6621653414063,
//     "TICKER": "AMZN"
//   }
// ]
//       );
      

      // Make the GET request
      // axios.get(baseUrl + "/ticks", 
      //           {params: {start_range: this.begin, end_range: this.end, topn: this.topn}})
      axios.get(`${baseUrl}/ticks`,{params: {start_range: this.begin, end_range: this.end, topn: this.topn}})
        .then(response => {
          this.apiData = response.data;
          this.updateChartData();
          this.renderChart();
        })
        .catch(error => {
          console.error("Error reading ticks", error);
        });
    },
    updateChartData() {
      this.chartData.labels = this.apiData.map(item => item.DATE);
      this.chartData.datasets = [{
        label: 'Last Price',
        backgroundColor: '#f87979',
        data: this.apiData.map(item => item.LAST_PRICE)
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

<style> #myChart { max-width: 1000%; /* Adjust the max-width to make the chart smaller */ 
                   max-height: 80%; /* Adjust the height as needed */ } 
                   div { display: flex; flex-direction: column; align-items: center; /* Center align the content */ }
</style>
