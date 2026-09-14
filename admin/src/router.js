import { createRouter, createWebHistory } from 'vue-router'
import LoginView from './views/LoginView.vue'
import UsersView from './views/UsersView.vue'
import NotificationsView from './views/NotificationsView.vue'
import PrivacyPolicyView from './views/PrivacyPolicyView.vue'
import ChildSafetyView from './views/ChildSafetyView.vue'
import { authReady, currentUser, isAdmin } from './useAuth'

const routes = [
  { path: '/', redirect: '/users' },
  { path: '/login', name: 'login', component: LoginView },
  { path: '/privacy', name: 'privacy', component: PrivacyPolicyView },
  { path: '/child-safety', name: 'child-safety', component: ChildSafetyView },
  { path: '/users', name: 'users', component: UsersView, meta: { requiresAdmin: true } },
  {
    path: '/notifications',
    name: 'notifications',
    component: NotificationsView,
    meta: { requiresAdmin: true },
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

function waitForAuthReady() {
  if (authReady.value) return Promise.resolve()
  return new Promise((resolve) => {
    const unwatch = setInterval(() => {
      if (authReady.value) {
        clearInterval(unwatch)
        resolve()
      }
    }, 30)
  })
}

router.beforeEach(async (to) => {
  await waitForAuthReady()

  if (to.meta.requiresAdmin && (!currentUser.value || !isAdmin.value)) {
    return { name: 'login' }
  }
  if (to.name === 'login' && currentUser.value && isAdmin.value) {
    return { name: 'users' }
  }
  return true
})

export default router
