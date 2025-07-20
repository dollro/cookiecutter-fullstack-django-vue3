//import api from "../rest/rest";

export const MUTATION_SET_TOKEN = 'MUT_SET_TOKEN'
export const ACTION_SET_TOKEN = 'ACT_SET_TOKEN'
import {defineStore} from 'pinia'


export const useAuthStore = defineStore('auth', {
	state: () => ({
		token: '',
		isAuthenticated: false
	}),
	actions: {
		initializeStore() {
			if ( localStorage.getItem('token')) {
				this.token = localStorage.getItem('token')
				this.isAuthenticated = true
			} else {
				this.token = ''
				this.isAuthenticated = false
			}
		},

	},
})


// export default {
// 	namespaced: false,
// 	state: {
// 			token: '',
// 			isAuthenticated: false
// 	},
// 	persistentPaths: ["token", "isAuthenticated", ],
// 	mutations: {
// 		// initializeStore(state) {
// 		// 	if ( localStorage.getItem('token')) {
// 		// 		state.token = localStorage.getItem('token')
// 		// 		state.isAuthenticated = true
// 		// 	} else {
// 		// 		state.token = ''
// 		// 		state.isAuthenticated = false
// 		// 	}
// 		// },
// 		[MUTATION_SET_TOKEN](state, token) {
// 			state.token = token
// 			state.isAuthenticated = true
// 		},
// 		unsetToken(state) {
// 			state.token = ''
// 			state.isAuthenticated = false
// 		}
// 	},
// 	actions: {

// 	},
// 	modules: {

// 	}
// }
