<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { signInWithEmailAndPassword } from 'firebase/auth'
import { doc, getDoc } from 'firebase/firestore'
import { auth, db } from '../firebase'

const router = useRouter()
const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

async function handleSubmit() {
  error.value = ''
  loading.value = true
  try {
    const cred = await signInWithEmailAndPassword(auth, email.value.trim(), password.value)
    const adminDoc = await getDoc(doc(db, 'admins', cred.user.uid))
    if (!adminDoc.exists()) {
      error.value = 'This account does not have admin access.'
      await auth.signOut()
      return
    }
    router.push('/users')
  } catch (err) {
    error.value = 'Could not sign in. Check your email and password.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="login-page">
    <div class="login-card">
      <p class="login-logo">kisela</p>
      <p class="login-subtitle">Admin dashboard</p>

      <form @submit.prevent="handleSubmit">
        <div class="field">
          <label>Email</label>
          <input v-model="email" type="email" required autocomplete="username" />
        </div>
        <div class="field">
          <label>Password</label>
          <input v-model="password" type="password" required autocomplete="current-password" />
        </div>
        <p v-if="error" class="error-text">{{ error }}</p>
        <button class="btn btn-primary" type="submit" style="width: 100%" :disabled="loading">
          {{ loading ? 'Signing in…' : 'Sign in' }}
        </button>
      </form>

      <p style="text-align: center; margin-top: 20px; margin-bottom: 0; display: flex; gap: 16px; justify-content: center">
        <router-link to="/privacy" class="text-muted" style="font-size: 13px">
          Privacy Policy
        </router-link>
        <router-link to="/child-safety" class="text-muted" style="font-size: 13px">
          Child Safety
        </router-link>
      </p>
    </div>
  </div>
</template>
