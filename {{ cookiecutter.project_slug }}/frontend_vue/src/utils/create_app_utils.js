import {createApp} from "vue";
import axios from 'axios'
// import { createPinia } from 'pinia'
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
    //app.use(createPinia());
    //app.use(VueAxios, axios);
    //app.use(BootstrapVueNext);
    // app.config.globalProperties.$filters = filters;
    app.mount(selector);
    return app;
}
