<template>
<div class="flex items-center justify-center min-h-screen">
    <div class="bg-white rounded-lg shadow-lg p-8 max-w-md w-full">
        <h2 class="text-2xl font-bold text-center text-gray-800 mb-6">Create an Account</h2>
        <form id="registrationForm" novalidate>
            <div class="mb-4">
                <label for="username" class="block text-gray-700 font-semibold mb-2">Username</label>
                <input type="text" id="username" class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400" placeholder="Enter your username" required>
                <p class="text-red-500 text-sm mt-2 hidden" id="usernameError">Username is required.</p>
            </div>
            <div class="mb-4">
                <label for="email" class="block text-gray-700 font-semibold mb-2">Email</label>
                <input type="email" id="email" class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400" placeholder="Enter your email" required>
                <p class="text-red-500 text-sm mt-2 hidden" id="emailError">Please enter a valid email.</p>
            </div>
            <div class="mb-4">
                <label for="password" class="block text-gray-700 font-semibold mb-2">Password</label>
                <input type="password" id="password" class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400" placeholder="Enter your password" required>
                <p class="text-red-500 text-sm mt-2 hidden" id="passwordError">Password is required.</p>
            </div>
            <div class="mb-4">
                <label for="confirm-password" class="block text-gray-700 font-semibold mb-2">Confirm Password</label>
                <input type="password" id="confirm-password" class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400" placeholder="Confirm your password" required>
                <p class="text-red-500 text-sm mt-2 hidden" id="confirmPasswordError">Passwords do not match.</p>
            </div>
            <button type="submit" class="w-full bg-blue-500 text-white py-2 rounded-lg font-semibold hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-opacity-50">Register</button>
        </form>
        <p class="text-center text-gray-600 mt-4">Already have an account? <a href="#" class="text-blue-500 font-semibold">Sign In</a></p>
    </div>
  </div>
</template>


<script>
import api from '../rest/rest';

export default {
  name: "LoginRestAuth",
  components: {},
  data () {
    },

  mounted() {


  },

  computed: {

  },

  methods: {


  },
};

</script>