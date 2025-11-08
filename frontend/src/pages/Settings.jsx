import React, { useState, useEffect } from 'react'
import axios from 'axios'
import { useApiKeyStore } from '../stores/apiKeyStore'

export default function Settings(){
  const [key, setKey] = useState('')
  const [message, setMessage] = useState(null)
  const setApiKey = useApiKeyStore(state => state.setApiKey)

  useEffect(()=>{
    // check backend if key present
    axios.get('http://localhost:8000/api-key').then(res=>{
      if(res.data?.present){ setMessage('API key present on server (masked).') }
    }).catch(()=>{})
  },[])

  const saveToBackend = async () =>{
    try{
      await axios.post('http://localhost:8000/api-key', { api_key: key })
      setMessage('Saved to backend .env (local dev).')
      setApiKey(key)
    }catch(e){ setMessage('Failed to save key: ' + (e.message||e)) }
  }

  const saveToClient = ()=>{
    setApiKey(key)
    setMessage('Saved in browser store for this session.')
  }

  return (
    <div>
      <h1 className="text-2xl font-bold mb-4">Settings</h1>
      <div className="bg-white dark:bg-gray-800 p-4 rounded shadow">
        <div className="mb-2">OpenAI API Key</div>
        <input value={key} onChange={(e)=> setKey(e.target.value)} className="w-full p-2 border rounded" placeholder="sk-..." />
        <div className="flex gap-2 mt-2">
          <button onClick={saveToClient} className="px-3 py-1 bg-blue-600 text-white rounded">Save to browser (Zustand)</button>
          <button onClick={saveToBackend} className="px-3 py-1 bg-gray-600 text-white rounded">Save to backend .env</button>
        </div>
        {message && <div className="mt-2 text-sm">{message}</div>}
        <hr className="my-4" />
        <ThemeToggle />
      </div>
    </div>
  )
}

function ThemeToggle(){
  const [dark, setDark] = useState(() => document.documentElement.classList.contains('dark'))
  useEffect(()=>{
    if(dark) document.documentElement.classList.add('dark')
    else document.documentElement.classList.remove('dark')
  },[dark])
  return (
    <div className="flex items-center gap-3">
      <div>Theme</div>
      <button onClick={()=> setDark(!dark)} className="px-3 py-1 bg-indigo-600 text-white rounded">Toggle {dark? 'Dark' : 'Light'}</button>
    </div>
  )
}
