<script setup>
import { RouterLink, RouterView, useRoute } from 'vue-router'
import { currentUser, isAdmin, signOut } from './useAuth'

const route = useRoute()
</script>

<template>
  <div v-if="['login', 'privacy', 'child-safety'].includes(route.name)">
    <RouterView />
  </div>
  <div v-else class="app-shell">
    <aside class="sidebar">
      <p class="sidebar-logo">kisela</p>
      <p class="sidebar-subtitle">Admin dashboard</p>

      <RouterLink to="/users" class="nav-link" active-class="active">👥 Users</RouterLink>
      <RouterLink to="/notifications" class="nav-link" active-class="active">
        🔔 Notifications
      </RouterLink>

      <div class="sidebar-footer" v-if="currentUser && isAdmin">
        <p class="sidebar-user">{{ currentUser.email }}</p>
        <button class="btn btn-secondary btn-sm" style="width: 100%" @click="signOut">
          Sign out
        </button>
      </div>
    </aside>
    <main class="main-content">
      <RouterView />
    </main>
  </div>
</template>
