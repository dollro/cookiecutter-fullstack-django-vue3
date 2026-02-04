import axios, { type AxiosResponse } from "axios";

// axios settings
axios.defaults.baseURL = import.meta.env.VITE_APP_API_ROOT


const api = axios.create({});

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
        // Try to extract filename from header
        const filenameMatch = contentDisposition.match(/filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/);
        if (filenameMatch && filenameMatch[1]) {
            return filenameMatch[1].replace(/['"]/g, '');
        }
    }
    return fallbackName;
}


export default {

    setAuthHeader(token: string): void {
        api.defaults.headers.common['Authorization'] = 'Token ' + token
    },

    unsetAuthHeader(): void {
        api.defaults.headers.common['Authorization'] = ''
    },

    createUser(formdata: Record<string, string>): Promise<AxiosResponse> {
        return api.post("/registration/", formdata)
    },

    getUserData(): Promise<AxiosResponse> {
        return api.get("/user/")
    },

    login(formdata: Record<string, string>): Promise<AxiosResponse> {
        return api.post("/login/", formdata)

    },

    logout(): Promise<AxiosResponse> {
        return api.post("/logout/")
    },

    stopWakeup(): Promise<AxiosResponse> {
        return api.post("/actions/stopwakeup/")
    },


    getEvents(): Promise<AxiosResponse> {
        return api.get('/events/')
    },

    async downloadFileByPath(urlPath: string, fallbackFilename = 'download'): Promise<void> {
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
