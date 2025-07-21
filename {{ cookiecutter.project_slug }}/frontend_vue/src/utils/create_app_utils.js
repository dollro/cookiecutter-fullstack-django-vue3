import {createApp} from "vue";
import axios from 'axios'
import { createPinia } from 'pinia'
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate'
// import Cookies from 'js-cookie';

axios.defaults.xsrfHeaderName = "X-CSRFToken"
axios.defaults.xsrfCookieName = 'csrftoken'
axios.defaults.withCredentials = false
axios.defaults.baseURL = "/api/v1/";

//import VueAxios from 'vue-axios'
//import BootstrapVueNext from 'bootstrap-vue-next'

import i18n from '../i18n'
// import filters from './filters'




export const createAppInEl = (options, selector) => {
    const app = createApp(options);
    app.use(i18n);
    
    // Create and configure Pinia
    const pinia = createPinia();
    pinia.use(piniaPluginPersistedstate);
    app.use(pinia);
    
    //app.use(VueAxios, axios);
    //app.use(BootstrapVueNext);
    // app.config.globalProperties.$filters = filters;
    app.mount(selector);
    return app;
}
