<template> 
</template> 

<style lang="sass">
</style>
<style>
@keyframes fadeIn {
    from { opacity: 0; transform: translateY(20px); }
    to { opacity: 1; transform: translateY(0); }
}

html { scroll-behavior: smooth; }
.elegant-title {
    font-family: 'Playfair Display', Georgia, serif;
    line-height: 1.2;
}

</style>

<script>
import { useAuthStore } from './stores/auth';
import './assets/css/tailwind.css';
import './assets/scss/main.scss';

//import SimpleLightbox from "simplelightbox";
//import HelloWorld from "./components/HelloWorld.vue";

export default {
    name: "Main",
    components: { },
    data() {
        return {
          staticRoot: import.meta.env.VITE_APP_STATIC_ROOT
        }
    }

}


</script>


