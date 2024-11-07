<!-- App.vue -->
<template>
    <div id="app">
      <header class="banner">
        <h1>Snowflake Ticker Data</h1>
      </header>
      <main>
        <LineChart />
      </main>
    </div>
  </template>
  
  <script>
  import LineChart from './components/LineChart.vue';
  
  export default {
    name: 'App',
    components: {
      LineChart,
    },
  };
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
  