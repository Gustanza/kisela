<script setup>
import { onMounted, onUnmounted, ref } from 'vue'
import { collection, onSnapshot, orderBy, query } from 'firebase/firestore'
import { httpsCallable } from 'firebase/functions'
import { db, functions } from '../firebase'

const title = ref('')
const body = ref('')
const mode = ref('now') // 'now' | 'schedule'
const scheduleAt = ref('')
const sending = ref(false)
const formError = ref('')
const successMessage = ref('')

const history = ref([])
const loadingHistory = ref(true)
const cancellingId = ref(null)
let unsubscribe = null

onMounted(() => {
  const q = query(collection(db, 'scheduledNotifications'), orderBy('createdAt', 'desc'))
  unsubscribe = onSnapshot(q, (snap) => {
    history.value = snap.docs.map((d) => ({ id: d.id, ...d.data() }))
    loadingHistory.value = false
  })
})

onUnmounted(() => {
  if (unsubscribe) unsubscribe()
})

function minDateTimeLocal() {
  const now = new Date(Date.now() + 5 * 60 * 1000)
  now.setSeconds(0, 0)
  const pad = (n) => String(n).padStart(2, '0')
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}T${pad(now.getHours())}:${pad(now.getMinutes())}`
}

async function handleSubmit() {
  formError.value = ''
  successMessage.value = ''

  if (!title.value.trim() || !body.value.trim()) {
    formError.value = 'Title and message are required.'
    return
  }
  if (mode.value === 'schedule' && !scheduleAt.value) {
    formError.value = 'Pick a date and time to schedule for.'
    return
  }

  sending.value = true
  try {
    if (mode.value === 'now') {
      const sendBroadcastNotification = httpsCallable(functions, 'sendBroadcastNotification')
      await sendBroadcastNotification({ title: title.value.trim(), body: body.value.trim() })
      successMessage.value = 'Notification sent to every Kisela user.'
    } else {
      const sendAtMillis = new Date(scheduleAt.value).getTime()
      if (sendAtMillis <= Date.now()) {
        formError.value = 'Scheduled time must be in the future.'
        sending.value = false
        return
      }
      const scheduleBroadcastNotification = httpsCallable(functions, 'scheduleBroadcastNotification')
      await scheduleBroadcastNotification({
        title: title.value.trim(),
        body: body.value.trim(),
        sendAtMillis,
      })
      successMessage.value = 'Notification scheduled.'
    }
    title.value = ''
    body.value = ''
    scheduleAt.value = ''
  } catch (err) {
    formError.value = err.message || 'Something went wrong.'
  } finally {
    sending.value = false
  }
}

async function handleCancel(item) {
  if (!confirm('Cancel this scheduled notification?')) return
  cancellingId.value = item.id
  try {
    const cancelScheduledNotification = httpsCallable(functions, 'cancelScheduledNotification')
    await cancelScheduledNotification({ id: item.id })
  } catch (err) {
    alert(err.message || 'Could not cancel.')
  } finally {
    cancellingId.value = null
  }
}

function formatDate(ts) {
  if (!ts) return '—'
  const date = ts.toDate ? ts.toDate() : new Date(ts)
  return date.toLocaleString()
}
</script>

<template>
  <div>
    <div class="page-header">
      <div>
        <h1 class="page-title">Notifications</h1>
        <p class="page-subtitle">Broadcast a push notification to your whole userbase</p>
      </div>
    </div>

    <div class="card" style="max-width: 560px; margin-bottom: 28px">
      <form @submit.prevent="handleSubmit">
        <div class="field">
          <label>Title</label>
          <input v-model="title" type="text" maxlength="65" placeholder="We miss you! 💕" />
        </div>
        <div class="field">
          <label>Message</label>
          <textarea
            v-model="body"
            rows="3"
            maxlength="180"
            placeholder="New people just joined Kisela — come take a look!"
          ></textarea>
        </div>

        <div class="field">
          <label>When</label>
          <div class="radio-group">
            <label class="radio-option">
              <input type="radio" value="now" v-model="mode" />
              Send now
            </label>
            <label class="radio-option">
              <input type="radio" value="schedule" v-model="mode" />
              Schedule for later
            </label>
          </div>
        </div>

        <div class="field" v-if="mode === 'schedule'">
          <label>Send at</label>
          <input v-model="scheduleAt" type="datetime-local" :min="minDateTimeLocal()" />
        </div>

        <p v-if="formError" class="error-text">{{ formError }}</p>
        <p v-if="successMessage" class="success-banner">{{ successMessage }}</p>

        <button class="btn btn-primary" type="submit" :disabled="sending" style="width: 100%">
          {{
            sending
              ? 'Working…'
              : mode === 'now'
                ? 'Send to everyone now'
                : 'Schedule notification'
          }}
        </button>
      </form>
    </div>

    <h2 style="font-size: 16px; margin-bottom: 12px">History</h2>
    <div class="card" style="padding: 0">
      <div v-if="loadingHistory" class="spinner" />
      <div v-else-if="history.length === 0" class="empty-state">No notifications yet.</div>
      <table v-else>
        <thead>
          <tr>
            <th>Title</th>
            <th>Message</th>
            <th>Send at</th>
            <th>Status</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in history" :key="item.id">
            <td>{{ item.title }}</td>
            <td style="max-width: 260px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap">
              {{ item.body }}
            </td>
            <td>{{ formatDate(item.sendAt) }}</td>
            <td><span class="badge" :class="`badge-${item.status}`">{{ item.status }}</span></td>
            <td>
              <button
                v-if="item.status === 'pending'"
                class="btn btn-danger btn-sm"
                :disabled="cancellingId === item.id"
                @click="handleCancel(item)"
              >
                {{ cancellingId === item.id ? 'Cancelling…' : 'Cancel' }}
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
