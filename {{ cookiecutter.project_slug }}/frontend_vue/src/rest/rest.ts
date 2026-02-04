import axios from "axios";

// axios settings
axios.defaults.baseURL = import.meta.env.VITE_APP_API_ROOT
//axios.defaults.baseURL = process.env.VITE_APP_API_ROOT;
//axios.defaults.xsrfHeaderName = "X-CSRFToken";
//axios.defaults.xsrfCookieName = 'csrftoken';

//axios.defaults.headers['Content-Type'] = 'application/json';


const api = axios.create({});

/**
 * Helper function to trigger a file download from a blob response
 * @param {Blob} blob - The file blob to download
 * @param {string} filename - The filename to save as
 */
function triggerBlobDownload(blob, filename) {
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
}

/**
 * Extract filename from Content-Disposition header or use fallback
 * @param {Object} response - Axios response object
 * @param {string} fallbackName - Fallback filename if header not present
 * @returns {string} The extracted or fallback filename
 */
function getFilenameFromResponse(response, fallbackName) {
    const contentDisposition = response.headers['content-disposition'];
    if (contentDisposition) {
        // Try to extract filename from header
        const filenameMatch = contentDisposition.match(/filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/);
        if (filenameMatch && filenameMatch[1]) {
            return filenameMatch[1].replace(/['"]/g, '');
        }
    }
    return fallbackName;
}


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

    /**
     * Generic authenticated file download by URL path
     * @param {string} urlPath - The API URL path to download from
     * @param {string} fallbackFilename - Fallback filename if not provided in response headers
     */
    async downloadFileByPath(urlPath, fallbackFilename = 'download') {
        // Ensure the path starts with /
        const normalizedPath = urlPath.startsWith('/') ? urlPath : `/${urlPath}`;
        const response = await api.get(normalizedPath, {
            responseType: 'blob'
        });
        const filename = getFilenameFromResponse(response, fallbackFilename);
        triggerBlobDownload(response.data, filename);
    },

    /* Include additional API calls here */
}
