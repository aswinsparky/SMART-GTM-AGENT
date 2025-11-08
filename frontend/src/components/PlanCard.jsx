import React, { useRef } from 'react'
import html2canvas from 'html2canvas'
import jsPDF from 'jspdf'

export default function PlanCard({ plan }){
  const cardRef = useRef()
  console.log('Rendering PlanCard with plan:', plan);

  const downloadPdf = async () =>{
    const el = cardRef.current
    if(!el) return
    const canvas = await html2canvas(el)
    const img = canvas.toDataURL('image/png')
    const pdf = new jsPDF({orientation:'portrait', unit:'px', format:[canvas.width, canvas.height]})
    pdf.addImage(img, 'PNG', 0, 0, canvas.width, canvas.height)
    pdf.save('gtm-plan.pdf')
  }

  // Handle both old and new data formats
  const isLegacyFormat = typeof plan.target_segment === 'string';

  return (
    <div ref={cardRef} className="bg-white dark:bg-gray-800 p-6 rounded shadow space-y-6">
      {/* Target Segment Section */}
      <section>
        <h3 className="text-lg font-semibold mb-3">Target Segment Analysis</h3>
        {isLegacyFormat ? (
          <div className="pl-4">
            <div className="text-sm">{plan.target_segment}</div>
          </div>
        ) : (
          <div className="grid gap-4 pl-4">
            <div>
              <div className="font-medium text-gray-700 dark:text-gray-300">Primary Audience</div>
              <div className="text-sm">{plan.target_segment?.primary_audience}</div>
            </div>
            <div>
              <div className="font-medium text-gray-700 dark:text-gray-300">Demographics</div>
              <div className="text-sm">{plan.target_segment?.demographics}</div>
            </div>
            <div>
              <div className="font-medium text-gray-700 dark:text-gray-300">Psychographics</div>
              <div className="text-sm">{plan.target_segment?.psychographics}</div>
            </div>
            <div>
              <div className="font-medium text-gray-700 dark:text-gray-300">Pain Points</div>
              <div className="text-sm">{plan.target_segment?.pain_points}</div>
            </div>
          </div>
        )}</section>

      {/* Marketing Channels Section */}
      <section>
        <h3 className="text-lg font-semibold mb-3">Marketing Channels</h3>
        {isLegacyFormat ? (
          <div className="pl-4">
            <ul className="list-disc ml-6">
              {(plan.marketing_channels || []).map((channel, idx) => (
                <li key={idx}>{channel}</li>
              ))}
            </ul>
          </div>
        ) : (
          <div className="space-y-4">
            {(plan.marketing_channels || []).map((channel, idx) => (
              <div key={idx} className="bg-gray-50 dark:bg-gray-700 p-3 rounded">
                <div className="font-medium text-gray-700 dark:text-gray-300">{channel.channel}</div>
                <div className="text-sm mt-2 space-y-2">
                  <div><span className="text-gray-600 dark:text-gray-400">Strategy:</span> {channel.strategy}</div>
                  <div><span className="text-gray-600 dark:text-gray-400">Budget:</span> {channel.budget_allocation}</div>
                  <div><span className="text-gray-600 dark:text-gray-400">Impact:</span> {channel.expected_impact}</div>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* Pricing Strategy Section */}
      <section>
        <h3 className="text-lg font-semibold mb-3">Pricing Strategy</h3>
        {isLegacyFormat ? (
          <div className="pl-4">
            <div className="text-sm">{plan.pricing_strategy}</div>
          </div>
        ) : (
          <div className="grid gap-4 pl-4">
            <div>
              <div className="font-medium text-gray-700 dark:text-gray-300">Model</div>
              <div className="text-sm">{plan.pricing_strategy?.model}</div>
            </div>
            <div>
              <div className="font-medium text-gray-700 dark:text-gray-300">Rationale</div>
              <div className="text-sm">{plan.pricing_strategy?.rationale}</div>
            </div>
            <div>
              <div className="font-medium text-gray-700 dark:text-gray-300">Competitive Positioning</div>
              <div className="text-sm">{plan.pricing_strategy?.competitive_positioning}</div>
            </div>
            <div>
              <div className="font-medium text-gray-700 dark:text-gray-300">Target Margins</div>
              <div className="text-sm">{plan.pricing_strategy?.target_margins}</div>
            </div>
          </div>
        )}
      </section>

      {/* Competitor Insights Section */}
      <section>
        <h3 className="text-lg font-semibold mb-3">Competitor Analysis</h3>
        {isLegacyFormat ? (
          <div className="pl-4">
            <div className="text-sm">{plan.competitor_insights}</div>
          </div>
        ) : (
          <div className="grid gap-4 pl-4">
            <div>
              <div className="font-medium text-gray-700 dark:text-gray-300">Main Competitors</div>
              <ul className="list-disc ml-6 text-sm">
                {(plan.competitor_insights?.main_competitors || []).map((comp, idx) => (
                  <li key={idx}>{comp}</li>
                ))}
              </ul>
            </div>
            <div>
              <div className="font-medium text-gray-700 dark:text-gray-300">Our Advantages</div>
              <ul className="list-disc ml-6 text-sm">
                {(plan.competitor_insights?.competitive_advantages || []).map((adv, idx) => (
                  <li key={idx}>{adv}</li>
                ))}
              </ul>
            </div>
            <div>
              <div className="font-medium text-gray-700 dark:text-gray-300">Market Gaps</div>
              <div className="text-sm">{plan.competitor_insights?.market_gaps}</div>
            </div>
            <div>
              <div className="font-medium text-gray-700 dark:text-gray-300">Defense Strategy</div>
              <div className="text-sm">{plan.competitor_insights?.defense_strategy}</div>
            </div>
          </div>
        )}
      </section>

      {/* ROI Prediction Section */}
      <section>
        <h3 className="text-lg font-semibold mb-3">ROI Analysis</h3>
        {isLegacyFormat ? (
          <div className="pl-4">
            <div className="text-sm">{plan.predicted_roi}</div>
          </div>
        ) : (
          <div className="grid gap-4 pl-4">
            <div>
              <div className="font-medium text-gray-700 dark:text-gray-300">Expected Return</div>
              <div className="text-sm">{plan.predicted_roi?.expected_return}</div>
            </div>
            <div>
              <div className="font-medium text-gray-700 dark:text-gray-300">Timeline</div>
              <div className="text-sm">{plan.predicted_roi?.timeline}</div>
            </div>
            <div>
              <div className="font-medium text-gray-700 dark:text-gray-300">Key Metrics</div>
              <ul className="list-disc ml-6 text-sm">
                {(plan.predicted_roi?.key_metrics || []).map((metric, idx) => (
                  <li key={idx}>{metric}</li>
                ))}
              </ul>
            </div>
            <div>
              <div className="font-medium text-gray-700 dark:text-gray-300">Risk Factors</div>
              <ul className="list-disc ml-6 text-sm">
                {(plan.predicted_roi?.risk_factors || []).map((risk, idx) => (
                  <li key={idx}>{risk}</li>
                ))}
              </ul>
            </div>
          </div>
        )}
      </section>

      <div className="pt-4 border-t">
        <button onClick={downloadPdf} className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 transition-colors">
          Download as PDF
        </button>
      </div>
    </div>
  )
}
