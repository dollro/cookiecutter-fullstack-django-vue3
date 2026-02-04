
// Add this at the beginning of your app entry.
import 'vite/modulepreload-polyfill';
import {createAppInEl} from "./utils/create_app_utils";
import Main from "./Main.vue"
import Hello from "./components/Hello.vue"
import LoginRestAuth from './components/LoginRestAuth.vue';


createAppInEl(Main, "#vue-main");
createAppInEl(Hello, "#vue-hello");
createAppInEl(LoginRestAuth, "#vue-login-rest_auth");
