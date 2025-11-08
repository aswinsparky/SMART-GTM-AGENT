import React, { useState } from 'react'
import axios from 'axios'

export default function GTMForm({ onResult }){
  const [form, setForm] = useState({product_name:'', target_audience:'', budget:'', region:'', competitors:''})
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const handleChange = (e) => setForm({...form, [e.target.name]: e.target.value})

  const submit = async () => {
    setError(null)
    setLoading(true)
    
    try {
      // Field validation
      const emptyFields = Object.entries(form)
        .filter(([_, value]) => !value.trim())
        .map(([key]) => {
          switch(key) {
            case 'product_name': return 'Product Name';
            case 'target_audience': return 'Target Audience';
            case 'budget': return 'Marketing Budget';
            case 'region': return 'Region';
            case 'competitors': return 'Competitors';
            default: return key;
          }
        });
      
      if (emptyFields.length > 0) {
        throw new Error(`Please fill in the following fields: ${emptyFields.join(', ')}`);
      }

      // Make API request with timeout
      const res = await axios.post(
        `${import.meta.env.VITE_API_URL}/generate-plan`, 
        form,
        { 
          timeout: 30000, // 30 second timeout
          headers: { 'Content-Type': 'application/json' }
        }
      );

      console.log('Server response:', res.data);
      if (res.data?.success && res.data?.data?.strategy) {
        console.log('Strategy data:', res.data.data.strategy);
        onResult(res.data.data.strategy);
      } else {
        console.error('Invalid response format:', res.data);
        throw new Error('Invalid response format from server');
      }
    } catch (err) {
      console.error('Generation error:', err);
      
      if (err.code === 'ECONNABORTED') {
        setError('Request timed out. Please try again.');
      } else if (err.response?.status === 401) {
        setError('OpenAI API key not set. Please set it in the Settings page.');
      } else if (err.response?.status === 504) {
        setError('Server timeout. Please try again.');
      } else {
        setError(
          err?.response?.data?.detail ||
          err?.message ||
          'Failed to generate plan. Please try again.'
        );
      }
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-lg max-w-2xl mx-auto">
      <h2 className="text-2xl font-bold mb-6 text-gray-800 dark:text-white">Generate GTM Plan</h2>
      
      {error && (
        <div className="mb-6 p-4 bg-red-100 border border-red-400 text-red-700 rounded-lg">
          <p className="font-medium">Error</p>
          <p className="text-sm">{error}</p>
        </div>
      )}
      
      <form onSubmit={(e) => { e.preventDefault(); submit(); }} className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Product Name
          </label>
          <input 
            name="product_name" 
            placeholder="Enter your product name" 
            value={form.product_name} 
            onChange={handleChange} 
            disabled={loading}
            className="w-full p-3 border rounded-lg focus:border-blue-500 focus:ring-1 focus:ring-blue-500 disabled:bg-gray-100 dark:bg-gray-700 dark:border-gray-600 dark:text-white" 
          />
        </div>
        
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Target Audience
          </label>
          <input 
            name="target_audience" 
            placeholder="Describe your target audience" 
            value={form.target_audience} 
            onChange={handleChange} 
            disabled={loading}
            className="w-full p-3 border rounded-lg focus:border-blue-500 focus:ring-1 focus:ring-blue-500 disabled:bg-gray-100 dark:bg-gray-700 dark:border-gray-600 dark:text-white" 
          />
        </div>
        
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Marketing Budget
          </label>
          <input 
            name="budget" 
            placeholder="Enter your marketing budget" 
            value={form.budget} 
            onChange={handleChange} 
            disabled={loading}
            className="w-full p-3 border rounded-lg focus:border-blue-500 focus:ring-1 focus:ring-blue-500 disabled:bg-gray-100 dark:bg-gray-700 dark:border-gray-600 dark:text-white" 
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Region
          </label>
          <input 
            name="region" 
            placeholder="Enter target region/market" 
            value={form.region} 
            onChange={handleChange} 
            disabled={loading}
            className="w-full p-3 border rounded-lg focus:border-blue-500 focus:ring-1 focus:ring-blue-500 disabled:bg-gray-100 dark:bg-gray-700 dark:border-gray-600 dark:text-white" 
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Competitors
          </label>
          <input 
            name="competitors" 
            placeholder="List main competitors" 
            value={form.competitors} 
            onChange={handleChange} 
            disabled={loading}
            className="w-full p-3 border rounded-lg focus:border-blue-500 focus:ring-1 focus:ring-blue-500 disabled:bg-gray-100 dark:bg-gray-700 dark:border-gray-600 dark:text-white" 
          />
        </div>

        <button
          type="submit"
          disabled={loading}
          className={`w-full p-3 rounded-lg text-white font-medium transition-colors
            ${loading 
              ? 'bg-blue-400 cursor-not-allowed'
              : 'bg-blue-600 hover:bg-blue-700 active:bg-blue-800'
            }`}
        >
          {loading ? (
            <span className="flex items-center justify-center">
              <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Generating Plan...
            </span>
          ) : 'Generate GTM Plan'}
        </button>
      </form>
    </div>
  );
}
