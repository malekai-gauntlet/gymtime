### The below is what I used in my react app to create the voice workout logging + table component. The cells are editable. This md is strictly for reference for building similar functionality in SwiftUI.


import { useState, useEffect } from 'react'
import { useAuth } from '../auth/AuthContext'
import { supabase } from '../../lib/supabaseClient'
import { OpenAI } from 'openai'
import { toast } from 'react-hot-toast'
import { workoutEventEmitter, WORKOUT_ADDED_EVENT } from '../../lib/workoutEntryTool'

// Editable cell for table
function EditableCell({ value, onChange, type = "text" }) {
  const [isEditing, setIsEditing] = useState(false)
  const [editValue, setEditValue] = useState(value)

  const handleClick = () => {
    setIsEditing(true)
  }

  const handleBlur = () => {
    setIsEditing(false)
    if (editValue !== value) {
      onChange(editValue)
    }
  }

  const handleKeyDown = (e) => {
    if (e.key === 'Enter') {
      setIsEditing(false)
      if (editValue !== value) {
        onChange(editValue)
      }
    }
    if (e.key === 'Escape') {
      setIsEditing(false)
      setEditValue(value)
    }
  }

  if (isEditing) {
    return (
      <input
        type={type}
        className="w-full bg-white/10 text-white border-0 focus:ring-1 focus:ring-[#e12c4c] rounded focus:outline-none"
        style={{ minWidth: '100%', height: '24px', lineHeight: '24px', padding: '0 4px' }}
        value={editValue}
        onChange={(e) => setEditValue(e.target.value)}
        onBlur={handleBlur}
        onKeyDown={handleKeyDown}
        autoFocus
      />
    )
  }

  return (
    <div 
      className="cursor-pointer group relative"
      onClick={handleClick}
      style={{ height: '24px', lineHeight: '24px', padding: '0 4px' }}
    >
      {value}
      <div className="absolute inset-0 border border-[#e12c4c]/0 group-hover:border-[#e12c4c]/20 rounded pointer-events-none transition-colors" />
    </div>
  )
}

// Main voice workout logging + table component
export function WorkoutLog() {
  const { user } = useAuth()
  const [workoutData, setWorkoutData] = useState([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState(null)

  // Speech recognition states
  const [recognition, setRecognition] = useState(null)
  const [isListening, setIsListening] = useState(false)
  const [currentTranscript, setCurrentTranscript] = useState('')
  const [isProcessing, setIsProcessing] = useState(false)

  // Fetch existing workouts
  useEffect(() => {
    const fetchWorkoutHistory = async () => {
      try {
        const { data, error } = await supabase
          .from('workout_history')
          .select('*')
          .order('date', { ascending: false })
        if (error) throw error

        // Transform data for the table
        if (data) {
          const transformedData = data.map(workout => ({
            id: workout.id,
            date: new Date(workout.date).toLocaleDateString(),
            exercise: workout.exercise,
            weight: workout.weight || '',
            sets: workout.sets?.toString() || '',
            reps: workout.reps?.toString() || '',
            bodyweight: workout.bodyweight?.toString() || '',
            notes: workout.notes || ''
          }))
          setWorkoutData(transformedData)
        }
      } catch (err) {
        console.error('Error fetching workout history:', err)
        setError(err.message)
      } finally {
        setIsLoading(false)
      }
    }

    fetchWorkoutHistory()

    // Listen for new workouts added by other AI flows
    const handleWorkoutAdded = (event) => {
      const newWorkout = event.detail
      setWorkoutData(prev => [newWorkout, ...prev])
      toast.success(`Successfully logged ${newWorkout.exercise || 'workout'}!`)
    }

    workoutEventEmitter.addEventListener(WORKOUT_ADDED_EVENT, handleWorkoutAdded)
    return () => {
      workoutEventEmitter.removeEventListener(WORKOUT_ADDED_EVENT, handleWorkoutAdded)
    }
  }, [])

  // Set up speech recognition
  useEffect(() => {
    if ('webkitSpeechRecognition' in window) {
      const recog = new window.webkitSpeechRecognition()
      recog.continuous = true
      recog.interimResults = false

      recog.onstart = () => {
        setIsListening(true)
        setCurrentTranscript('')
      }

      recog.onresult = (event) => {
        const transcript = Array.from(event.results)
          .map(result => result[0].transcript)
          .join(' ')
        setCurrentTranscript(transcript)
      }

      recog.onend = () => {
        setIsListening(false)
      }

      setRecognition(recog)
    } else {
      console.error('Speech recognition not supported in this browser')
    }
  }, [])

  // Convert transcript into structured workout data
  const parseTranscript = async (transcript) => {
    setIsProcessing(true)
    try {
      const openai = new OpenAI({
        apiKey: import.meta.env.VITE_OPENAI_API_KEY,
        dangerouslyAllowBrowser: true
      })

      // Ask GPT to parse the workout details into JSON
      const completion = await openai.chat.completions.create({
        model: "gpt-4",
        messages: [{
          role: "system",
          content: "You are a fitness tracking assistant. Parse the following workout description and return JSON with fields: exercise, weight, sets, reps, bodyweight, notes. Use null for any missing fields. Return ONLY the JSON object."
        }, {
          role: "user",
          content: transcript
        }],
        temperature: 0.7,
      })

      // Clean up the response
      const raw = completion.choices[0].message.content.trim()
      const parsedData = JSON.parse(raw)

      // Quick cleanup helpers
      const capitalizeWords = (str) =>
        str?.split(' ')
          .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
          .join(' ')

      const wordToNumber = (str) => {
        const numberWords = {
          'zero': '0','one': '1','two': '2','three': '3','four': '4',
          'five': '5','six': '6','seven': '7','eight': '8','nine': '9','ten': '10'
        }
        return str?.toLowerCase().split(' ').map(word => numberWords[word] || word).join(' ')
      }

      const cleaned = {
        exercise: capitalizeWords(parsedData.exercise || ''),
        weight: wordToNumber(parsedData.weight?.toString() || ''),
        sets: wordToNumber(parsedData.sets?.toString() || ''),
        reps: wordToNumber(parsedData.reps?.toString() || ''),
        bodyweight: wordToNumber(parsedData.bodyweight?.toString() || ''),
        notes: parsedData.notes || ''
      }

      // Insert into Supabase
      const newEntry = await createWorkoutEntry(cleaned)

      // Add new entry to table in local state
      const localEntry = {
        id: newEntry.id || workoutData.length + 1,
        date: new Date().toLocaleDateString(),
        ...newEntry
      }
      setWorkoutData(prev => [...prev, localEntry])

      toast.success(`Successfully logged ${cleaned.exercise || 'workout'}!`, { duration: 5000 })
    } catch (err) {
      console.error('Error parsing transcript:', err)
      toast.error('Failed to log workout. Please try again.')
    } finally {
      setIsProcessing(false)
    }
  }

  // Create a new workout in Supabase
  const createWorkoutEntry = async (data) => {
    const workoutEntry = {
      user_id: user.id,
      date: new Date().toISOString(),
      exercise: data.exercise || '',
      weight: data.weight || '',
      sets: data.sets ? parseInt(data.sets) : null,
      reps: data.reps ? parseInt(data.reps) : null,
      bodyweight: data.bodyweight ? parseFloat(data.bodyweight) : null,
      notes: data.notes || ''
    }

    try {
      const { data: inserted, error } = await supabase
        .from('workout_history')
        .insert([workoutEntry])
        .select()
        .single()

      if (error) throw error

      return {
        id: inserted.id,
        date: new Date(inserted.date).toLocaleDateString(),
        exercise: inserted.exercise,
        weight: inserted.weight || '',
        sets: inserted.sets?.toString() || '',
        reps: inserted.reps?.toString() || '',
        bodyweight: inserted.bodyweight?.toString() || '',
        notes: inserted.notes || ''
      }
    } catch (err) {
      console.error('Error creating workout:', err)
      toast.error('Failed to save workout')
      return workoutEntry
    }
  }

  // Start/stop mic, then parse transcript
  const handleMicrophoneClick = async () => {
    if (!recognition) return

    if (isListening) {
      recognition.stop()
      if (currentTranscript) {
        const finalTranscript = currentTranscript
        setCurrentTranscript('')
        await parseTranscript(finalTranscript)
      }
    } else {
      recognition.start()
    }
  }

  // Update table cells
  const handleCellChange = async (id, field, newValue) => {
    setWorkoutData(workoutData.map(w => w.id === id ? { ...w, [field]: newValue } : w))
    try {
      const updateData = {
        [field]: (field === 'sets' || field === 'reps')
          ? parseInt(newValue) || null
          : field === 'bodyweight'
            ? parseFloat(newValue) || null
            : newValue
      }
      const { error } = await supabase
        .from('workout_history')
        .update(updateData)
        .eq('id', id)

      if (error) throw error
      toast.success('Workout updated successfully')
    } catch (err) {
      console.error('Error updating workout:', err)
      toast.error('Failed to update workout')
    }
  }

  // Delete a workout row
  const handleDeleteWorkout = async (id) => {
    if (!window.confirm('Are you sure you want to delete this workout entry?')) return
    try {
      const { error } = await supabase
        .from('workout_history')
        .delete()
        .eq('id', id)
      if (error) throw error
      setWorkoutData(prev => prev.filter(w => w.id !== id))
      toast.success('Workout deleted successfully')
    } catch (err) {
      console.error('Error deleting workout:', err)
      toast.error('Failed to delete workout')
    }
  }

  return (
    <div className="bg-white/5 rounded-xl p-6 backdrop-blur-sm">
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-xl font-semibold text-white/90">AI Workout Tracking</h3>
        <div className="flex items-center gap-4">
          {currentTranscript && (
            <div className="flex items-center gap-2 bg-white/5 px-4 py-2 rounded-lg border border-[#e12c4c]/20">
              <p className="text-sm text-gray-300">{currentTranscript}</p>
            </div>
          )}
          {isProcessing && (
            <div className="flex items-center gap-2 bg-white/5 px-4 py-2 rounded-lg border border-[#e12c4c]/20">
              <svg className="animate-spin h-4 w-4 text-[#e12c4c]" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10"
                        stroke="currentColor" strokeWidth="4" fill="none" />
                <path className="opacity-75" fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2
                         5.291A7.962 7.962 0 014 12H0c0 3.042 1.135
                         5.824 3 7.938l3-2.647z"/>
              </svg>
              <span className="text-sm text-gray-300">Processing workout...</span>
            </div>
          )}
          <button
            onClick={handleMicrophoneClick}
            disabled={isProcessing}
            className={`p-2.5 rounded-full transition-colors text-gray-400 hover:text-white group relative
              ${isListening ? 'bg-[#e12c4c]/20 text-[#e12c4c]' : 'bg-white/5 hover:bg-white/10'}
              ${isProcessing ? 'opacity-50 cursor-not-allowed' : ''}`}
            title={isListening ? "Stop recording" : "Record workout"}
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                    d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7
                       7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3
                       0 116 0v6a3 3 0 01-3 3z" />
            </svg>
            <div className={`absolute inset-0 border rounded-full pointer-events-none transition-colors
              ${isListening ? 'border-[#e12c4c] animate-pulse' : 'border-[#e12c4c]/0 group-hover:border-[#e12c4c]/20'}`} />
          </button>
        </div>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-8">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white/20"></div>
        </div>
      ) : (
        <table className="min-w-full divide-y divide-gray-800 border border-gray-800 rounded-lg overflow-x-auto">
          <thead>
            <tr className="bg-white/5">
              <th className="w-32 px-3 py-3.5 text-left text-xs font-semibold text-gray-300 uppercase border-r border-gray-800">
                Date
              </th>
              <th className="w-48 px-3 py-3.5 text-left text-xs font-semibold text-gray-300 uppercase border-r border-gray-800">
                Exercise
              </th>
              <th className="w-24 px-3 py-3.5 text-left text-xs font-semibold text-gray-300 uppercase border-r border-gray-800">
                Weight
              </th>
              <th className="w-20 px-3 py-3.5 text-center text-xs font-semibold text-gray-300 uppercase border-r border-gray-800">
                Sets
              </th>
              <th className="w-20 px-3 py-3.5 text-center text-xs font-semibold text-gray-300 uppercase border-r border-gray-800">
                Reps
              </th>
              <th className="px-3 py-3.5 text-left text-xs font-semibold text-gray-300 uppercase">
                Notes
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-800">
            {workoutData.map(workout => (
              <tr key={workout.id} className="hover:bg-white/5">
                <td className="w-32 px-3 py-4 text-sm text-gray-300 border-r border-gray-800">
                  <EditableCell
                    value={workout.date}
                    onChange={(val) => handleCellChange(workout.id, 'date', val)}
                  />
                </td>
                <td className="w-48 px-3 py-4 text-sm text-gray-300 border-r border-gray-800">
                  <EditableCell
                    value={workout.exercise}
                    onChange={(val) => handleCellChange(workout.id, 'exercise', val)}
                  />
                </td>
                <td className="w-24 px-3 py-4 text-sm text-gray-300 border-r border-gray-800">
                  <EditableCell
                    value={workout.weight}
                    onChange={(val) => handleCellChange(workout.id, 'weight', val)}
                  />
                </td>
                <td className="w-20 px-3 py-4 text-sm text-gray-300 text-center border-r border-gray-800">
                  <EditableCell
                    value={workout.sets}
                    onChange={(val) => handleCellChange(workout.id, 'sets', val)}
                    type="number"
                  />
                </td>
                <td className="w-20 px-3 py-4 text-sm text-gray-300 text-center border-r border-gray-800">
                  <EditableCell
                    value={workout.reps}
                    onChange={(val) => handleCellChange(workout.id, 'reps', val)}
                    type="number"
                  />
                </td>
                <td className="px-3 py-4 text-sm text-gray-300 relative">
                  <div className="flex items-center group">
                    <EditableCell
                      value={workout.notes}
                      onChange={(val) => handleCellChange(workout.id, 'notes', val)}
                    />
                    <button
                      onClick={() => handleDeleteWorkout(workout.id)}
                      className="p-2 rounded-full hover:bg-white/10 text-gray-400 hover:text-[#e12c4c] transition-colors
                                 opacity-0 group-hover:opacity-100 absolute right-2"
                      title="Delete workout"
                    >
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                              d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2
                                 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1
                                 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                      </svg>
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  )
}