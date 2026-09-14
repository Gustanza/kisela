import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'
import { getFunctions } from 'firebase/functions'

const firebaseConfig = {
  apiKey: 'AIzaSyAt8Rc4NnsMDrfOBRoPQA38_N67ME1oBZQ',
  authDomain: 'kisela-a5cd9.firebaseapp.com',
  projectId: 'kisela-a5cd9',
  storageBucket: 'kisela-a5cd9.firebasestorage.app',
  messagingSenderId: '718105574922',
  appId: '1:718105574922:web:cea810a89b535cb10029f3',
}

export const app = initializeApp(firebaseConfig)
export const auth = getAuth(app)
export const db = getFirestore(app)
export const functions = getFunctions(app)
