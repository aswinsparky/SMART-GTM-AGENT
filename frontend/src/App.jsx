import React from 'react'
import { Routes, Route, Link } from 'react-router-dom'
import HomePage from './pages/HomePage'
import Dashboard from './pages/Dashboard'
import Settings from './pages/Settings'

export default function App(){
  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-gray-100">
      <nav className="p-4 bg-white dark:bg-gray-800 shadow">
        <div className="max-w-5xl mx-auto flex gap-4">
          <Link to="/" className="font-bold">Smart GTM Agent</Link>
          <Link to="/dashboard" className="text-sm">Dashboard</Link>
          <Link to="/settings" className="text-sm ml-auto">Settings</Link>
        </div>
      </nav>
      <main className="max-w-5xl mx-auto p-6">
        <Routes>
          <Route path="/" element={<HomePage/>} />
          <Route path="/dashboard" element={<Dashboard/>} />
          <Route path="/settings" element={<Settings/>} />
        </Routes>
      </main>
    </div>
  )
}
