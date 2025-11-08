import create from 'zustand'

export const useApiKeyStore = create((set) => ({
  apiKey: null,
  setApiKey: (key) => set({ apiKey: key }),
}))
