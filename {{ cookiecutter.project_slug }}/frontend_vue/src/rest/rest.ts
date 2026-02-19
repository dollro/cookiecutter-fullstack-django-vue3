import axios, { type AxiosResponse } from "axios";

// API base URL for application endpoints (DRF)
axios.defaults.baseURL = import.meta.env.VITE_APP_API_ROOT;

const api = axios.create({});

// Auth API instance for allauth headless endpoints
// Base URL must point to the Django server root, not /api/v1/
const authApiBaseURL = import.meta.env.VITE_APP_AUTH_ROOT ||
    import.meta.env.VITE_APP_API_ROOT.replace('/api/v1', '');
const authApi = axios.create({
    baseURL: authApiBaseURL,
});

function triggerBlobDownload(blob: Blob, filename: string): void {
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
}

function getFilenameFromResponse(response: AxiosResponse, fallbackName: string): string {
    const contentDisposition = response.headers['content-disposition'];
    if (contentDisposition) {
        const filenameMatch = contentDisposition.match(/filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/);
        if (filenameMatch && filenameMatch[1]) {
            return filenameMatch[1].replace(/['"]/g, '');
        }
    }
    return fallbackName;
}


export default {

    setAuthHeader(token: string): void {
        api.defaults.headers.common['X-Session-Token'] = token;
        authApi.defaults.headers.common['X-Session-Token'] = token;
    },

    unsetAuthHeader(): void {
        delete api.defaults.headers.common['X-Session-Token'];
        delete authApi.defaults.headers.common['X-Session-Token'];
    },

    // --- Auth endpoints (allauth headless) ---

    signup(formdata: { email: string; password: string }): Promise<AxiosResponse> {
        return authApi.post("/_allauth/app/v1/auth/signup", formdata);
    },

    getSession(): Promise<AxiosResponse> {
        return authApi.get("/_allauth/app/v1/auth/session");
    },

    login(formdata: { email: string; password: string }): Promise<AxiosResponse> {
        return authApi.post("/_allauth/app/v1/auth/login", formdata);
    },

    logout(): Promise<AxiosResponse> {
        return authApi.delete("/_allauth/app/v1/auth/session");
    },

    // --- Application endpoints (DRF) ---

    stopWakeup(): Promise<AxiosResponse> {
        return api.post("/actions/stopwakeup/");
    },

    getEvents(): Promise<AxiosResponse> {
        return api.get('/events/');
    },

    async downloadFileByPath(urlPath: string, fallbackFilename = 'download'): Promise<void> {
        const normalizedPath = urlPath.startsWith('/') ? urlPath : `/${urlPath}`;
        const response = await api.get(normalizedPath, {
            responseType: 'blob'
        });
        const filename = getFilenameFromResponse(response, fallbackFilename);
        triggerBlobDownload(response.data, filename);
    },

    /* Include additional API calls here */
}
