<template>
      <button class="btn btn-primary" @click="stopwakeup()">Stop WakeUp!</button>
</template>

<script>
import api from '../rest/rest';

export default {
  name: "ManualControls",
  components: {},
  // data() {

  // },

  mounted() {


  },

  computed: {

  },

  methods: {
    stopwakeup() {
            //console.log('Token: ' + this.$store.state.token)
            api.stopWakeup()
                .then(function (response) {
                    console.log(response.data)
                    return console.log("Wakeup stopped.");
                })

        }


  },
};
</script>
