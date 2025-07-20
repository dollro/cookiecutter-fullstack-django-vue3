
// Add this at the beginning of your app entry.
import 'vite/modulepreload-polyfill';
import {createAppInEl} from "./utils/create_app_utils";
import Main from "./Main.vue"
// import ManualControls from "./components/ManualControls.vue"
// import Hello from "./components/Hello.vue"
// import HelloI18n from "./components/HelloI18n.vue"
import LoginRestAuth from './components/LoginRestAuth.vue';


createAppInEl(Main, "#vue-main");
//createAppInEl(ManualControls, "#vue-manualcontrols");
//createAppInEl(Hello, "#vue-hello");
createAppInEl(LoginRestAuth, "#vue-login-rest_auth");


// const appmain = createApp(MainApp)
// appmain.use(createPinia())
// appmain.mount('#vue-main-app')

// const appmain = createApp(HelloWorld)
// appmain.use(createPinia())
// appmain.mount('#vue-main-app')


//const app_wakeupeventlist = createApp(WakeUpEventList)
//app_wakeupeventlist.mount('"#vue-wakeupeventlist"')

// const app_manualcontrols = createApp(ManualControls)
// app_manualcontrols.mount('#vue-manualcontrols')
