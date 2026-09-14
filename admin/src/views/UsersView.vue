<script setup>
import { onMounted, onUnmounted, ref } from 'vue'
import { collection, deleteField, doc, onSnapshot, orderBy, query, setDoc } from 'firebase/firestore'
import { httpsCallable } from 'firebase/functions'
import { db, functions } from '../firebase'

const users = ref([])
const loading = ref(true)
let unsubscribe = null

const showModal = ref(false)
const modalMode = ref('create') // 'create' | 'edit'
const saving = ref(false)
const formError = ref('')
const deletingUid = ref(null)

const form = ref(emptyForm())

function emptyForm() {
  return { uid: '', email: '', password: '', name: '', age: '', gender: 'Woman', bio: '', photoUrl: '' }
}

onMounted(() => {
  const q = query(collection(db, 'users'), orderBy('createdAt', 'desc'))
  unsubscribe = onSnapshot(q, (snap) => {
    users.value = snap.docs.map((d) => ({ id: d.id, ...d.data() }))
    loading.value = false
  })
})

onUnmounted(() => {
  if (unsubscribe) unsubscribe()
})

function openCreate() {
  modalMode.value = 'create'
  form.value = emptyForm()
  formError.value = ''
  showModal.value = true
}

function openEdit(user) {
  modalMode.value = 'edit'
  form.value = {
    uid: user.id,
    email: '',
    password: '',
    name: user.name || '',
    age: user.age || '',
    gender: user.gender || 'Woman',
    bio: user.bio || '',
    photoUrl: user.photoUrl || '',
  }
  formError.value = ''
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

async function handleSubmit() {
  formError.value = ''
  saving.value = true
  try {
    if (modalMode.value === 'create') {
      const adminCreateUser = httpsCallable(functions, 'adminCreateUser')
      await adminCreateUser({
        email: form.value.email.trim(),
        password: form.value.password,
        name: form.value.name.trim(),
        age: Number(form.value.age),
        gender: form.value.gender,
        bio: form.value.bio.trim(),
      })
    } else {
      await setDoc(
        doc(db, 'users', form.value.uid),
        {
          name: form.value.name.trim(),
          age: Number(form.value.age),
          gender: form.value.gender,
          bio: form.value.bio.trim(),
          photoUrl: form.value.photoUrl.trim() || deleteField(),
        },
        { merge: true },
      )
    }
    showModal.value = false
  } catch (err) {
    formError.value = err.message || 'Something went wrong.'
  } finally {
    saving.value = false
  }
}

async function handleDelete(user) {
  if (!confirm(`Delete ${user.name || 'this user'}? This permanently removes their account.`)) {
    return
  }
  deletingUid.value = user.id
  try {
    const adminDeleteUser = httpsCallable(functions, 'adminDeleteUser')
    await adminDeleteUser({ uid: user.id })
  } catch (err) {
    alert(err.message || 'Could not delete user.')
  } finally {
    deletingUid.value = null
  }
}

function initials(name) {
  if (!name) return '?'
  return name.trim().charAt(0).toUpperCase()
}
</script>

<template>
  <div>
    <div class="page-header">
      <div>
        <h1 class="page-title">Users</h1>
        <p class="page-subtitle">{{ users.length }} people on Kisela</p>
      </div>
      <button class="btn btn-primary" @click="openCreate">+ Add user</button>
    </div>

    <div class="card" style="padding: 0">
      <div v-if="loading" class="spinner" />
      <div v-else-if="users.length === 0" class="empty-state">No users yet.</div>
      <table v-else>
        <thead>
          <tr>
            <th></th>
            <th>Name</th>
            <th>Age</th>
            <th>Gender</th>
            <th>Bio</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="user in users" :key="user.id">
            <td>
              <img v-if="user.photoUrl" :src="user.photoUrl" class="avatar" />
              <span v-else class="avatar">{{ initials(user.name) }}</span>
            </td>
            <td>{{ user.name || '—' }}</td>
            <td>{{ user.age || '—' }}</td>
            <td>{{ user.gender || '—' }}</td>
            <td style="max-width: 260px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap">
              {{ user.bio || '—' }}
            </td>
            <td>
              <div class="row-actions">
                <button class="btn btn-secondary btn-sm" @click="openEdit(user)">Edit</button>
                <button
                  class="btn btn-danger btn-sm"
                  :disabled="deletingUid === user.id"
                  @click="handleDelete(user)"
                >
                  {{ deletingUid === user.id ? 'Deleting…' : 'Delete' }}
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="showModal" class="modal-backdrop" @click.self="closeModal">
      <div class="modal">
        <h2>{{ modalMode === 'create' ? 'Add user' : 'Edit user' }}</h2>
        <form @submit.prevent="handleSubmit">
          <template v-if="modalMode === 'create'">
            <div class="field">
              <label>Email</label>
              <input v-model="form.email" type="email" required />
            </div>
            <div class="field">
              <label>Password</label>
              <input v-model="form.password" type="password" required minlength="6" />
            </div>
          </template>

          <div class="field">
            <label>First name</label>
            <input v-model="form.name" type="text" required />
          </div>
          <div class="field">
            <label>Age</label>
            <input v-model="form.age" type="number" min="18" max="100" required />
          </div>
          <div class="field">
            <label>Gender</label>
            <select v-model="form.gender">
              <option>Woman</option>
              <option>Man</option>
              <option>Other</option>
            </select>
          </div>
          <div class="field">
            <label>Bio</label>
            <textarea v-model="form.bio" rows="3" maxlength="150"></textarea>
          </div>
          <div class="field" v-if="modalMode === 'edit'">
            <label>Photo URL</label>
            <input v-model="form.photoUrl" type="text" placeholder="https://…" />
          </div>

          <p v-if="formError" class="error-text">{{ formError }}</p>

          <div class="modal-actions">
            <button type="button" class="btn btn-secondary" @click="closeModal">Cancel</button>
            <button type="submit" class="btn btn-primary" :disabled="saving">
              {{ saving ? 'Saving…' : 'Save' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>
