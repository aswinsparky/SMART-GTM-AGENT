import React, { useEffect, useState } from 'react'
import axios from 'axios'
import { LineChart, Line, XAxis, YAxis, Tooltip, CartesianGrid, ResponsiveContainer } from 'recharts'

export default function Dashboard(){
  const [history, setHistory] = useState([])
  const [loading, setLoading] = useState(false)

  useEffect(()=>{
    fetchHistory()
  },[])

  const fetchHistory = async ()=>{
    setLoading(true)
    try{
      const res = await axios.get('http://localhost:8000/history')
      setHistory(res.data.map(item => ({...item, created_at: new Date(item.created_at).toLocaleString()})))
    }catch(e){ console.error(e) }
    setLoading(false)
  }

  const chartData = history.map(h => ({ name: h.created_at, roi: h.predicted_roi || 0 }))

  return (
    <div>
      <h1 className="text-2xl font-bold mb-4">Dashboard</h1>
      <div className="bg-white dark:bg-gray-800 p-4 rounded shadow">
        <h2 className="font-semibold mb-2">ROI Over Time</h2>
        {loading ? <div>Loading...</div> : (
          <div style={{width:'100%', height:300}}>
            <ResponsiveContainer>
              <LineChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Line type="monotone" dataKey="roi" stroke="#8884d8" />
              </LineChart>
            </ResponsiveContainer>
          </div>
        )}
      </div>
      <div className="mt-4">
        <h2 className="font-semibold mb-2">History</h2>
        <div className="space-y-2">
          {history.map(h => (
            <div key={h.id} className="p-3 bg-white dark:bg-gray-800 rounded shadow">
              <div className="flex justify-between"><div>{h.product_name}</div><div>{h.created_at}</div></div>
              <div className="text-sm">ROI: {h.predicted_roi || 'N/A'}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
