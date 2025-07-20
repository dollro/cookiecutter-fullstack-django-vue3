import axios from "axios";

// axios settings
axios.defaults.baseURL = import.meta.env.VITE_APP_API_ROOT
//axios.defaults.baseURL = process.env.VITE_APP_API_ROOT;
//axios.defaults.xsrfHeaderName = "X-CSRFToken";
//axios.defaults.xsrfCookieName = 'csrftoken';

//axios.defaults.headers['Content-Type'] = 'application/json';


const api = axios.create({});


export default {

    setAuthHeader(token) {
        api.defaults.headers.common['Authorization'] = 'Token ' + token
    },

    unsetAuthHeader() {
        api.defaults.headers.common['Authorization'] = ''
    },

    createUser(formdata) {
        return api.post("/registration/", formdata)
    },

    getUserData() {
        return api.get("/user/")
    },

    login(formdata) {
        return api.post("/login/", formdata)

    },

    logout() {
        return api.post("/logout/")
    },

    stopWakeup() {
        return api.post("/actions/stopwakeup/")
    },


    getEvents() {
        return api.get('/events/')
    },

    /* Include additional API calls here */
}
