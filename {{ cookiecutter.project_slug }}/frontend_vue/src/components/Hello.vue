<template>
  <div class="text-center">
      <p>
        This cookiecutter im the techniques discussed in the
        series of articles "Vue + Django: The Best of Both Frontends."
      </p>
      <p>
        {{ $t('hello') }}
      </p>
      <button class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded
               md:py-3 md:px-6 
               lg:py-4 lg:px-8">
  Click me
</button>
  </div>
</template>

<script>
  export default {
    name: 'Hello',
    data () {
      return {
        staticRoot: import.meta.env.VITE_APP_STATIC_ROOT
      }
    }
  }
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="scss">
  h1 {
    margin: 40px 0 0;
    font-style: italic;
  }
  h3 {
    margin: 40px 0 0;
  }
  ul.articles {
    list-style-type: none;
    padding: 0;
    li {
      display: inline-block;
      margin: 0 10px;
    }
  }
  .opt {
    font-weight: bold;
  }
  p {
    margin-top: 1.5em;
    margin-bottom: .5em;
  }
  a {
    color: #42b983;
  }
  .logo {
    height: 150px;
    margin-top: 25px;
  }
  .plus {
    font-size: 44px;
    padding-left: 10px;
    padding-right: 20px;
  }
</style>
