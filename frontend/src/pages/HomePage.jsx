import React, { useState } from 'react'
import GTMForm from '../components/GTMForm'
import PlanCard from '../components/PlanCard'

export default function HomePage(){
  const [latestPlan, setLatestPlan] = useState(null)
  return (
    <div>
      <h1 className="text-2xl font-bold mb-4">Generate GTM Plan</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <GTMForm onResult={(r)=> setLatestPlan(r)} />
        <div>
          <h2 className="font-semibold mb-2">Generated Plan</h2>
          {latestPlan ? (
            <PlanCard plan={latestPlan} />
          ) : (
            <div className="text-sm text-gray-500">No plan generated yet.</div>
          )}
        </div>
      </div>
    </div>
  )
}
