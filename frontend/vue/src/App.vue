<template>
    <v-app>
      <v-app-bar
        app
        color="primary"
        dark
      >
      <v-row>
        <v-col cols="1">
        </v-col>
        <v-col cols="10"  class="text-center">   
        </v-col>
        <v-col cols="1"></v-col>
      </v-row>
  
    </v-app-bar>
  
      <v-main>
        <TopClerks/>
      </v-main>
    </v-app>
  </template>
  
  <script>
  import TopClerks from './components/line.vue';
  
  export default {
    name: 'App',
  
    components: {
      TopClerks,
    },
  
    data: () => ({
      //
    }),
  };
  </script>
  