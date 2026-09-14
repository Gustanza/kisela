import { ref } from 'vue'
import { onAuthStateChanged, signOut as firebaseSignOut } from 'firebase/auth'
import { doc, getDoc } from 'firebase/firestore'
import { auth, db } from './firebase'

export const currentUser = ref(null)
export const isAdmin = ref(false)
export const authReady = ref(false)

onAuthStateChanged(auth, async (user) => {
  currentUser.value = user
  if (user) {
    try {
      const adminDoc = await getDoc(doc(db, 'admins', user.uid))
      isAdmin.value = adminDoc.exists()
    } catch (err) {
      isAdmin.value = false
    }
  } else {
    isAdmin.value = false
  }
  authReady.value = true
})

export function signOut() {
  return firebaseSignOut(auth)
}
