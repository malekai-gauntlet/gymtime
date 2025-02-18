import { useAuth } from '../auth/AuthContext'
import { OpenAI } from 'openai'
import { toast } from 'react-hot-toast'
import { useNavigate } from 'react-router-dom'
import { workoutEventEmitter, WORKOUT_ADDED_EVENT } from '../../lib/workoutEntryTool'

// Initialize OpenAI client
const openai = new OpenAI({
  apiKey: import.meta.env.VITE_OPENAI_API_KEY,
  dangerouslyAllowBrowser: true
})



const EditableCell = ({ value, onChange, type = "text" }) => {
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
        style={{ 
          minWidth: '100%', 
          maxWidth: '100%', 
          boxSizing: 'border-box',
          height: '24px',
          lineHeight: '24px',
          padding: '0 4px'
        }}
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
      style={{ 
        height: '24px',
        lineHeight: '24px',
        padding: '0 4px'
      }}
    >
      {value}
      <div className="absolute inset-0 border border-[#e12c4c]/0 group-hover:border-[#e12c4c]/20 rounded pointer-events-none transition-colors" />
    </div>
  )
}


  
  // Initialize speech recognition
  useEffect(() => {
    if ('webkitSpeechRecognition' in window) {
      const recognition = new window.webkitSpeechRecognition()
      recognition.continuous = true
      recognition.interimResults = false
      
      recognition.onstart = () => {
        setIsListening(true)
      }

      recognition.onresult = (event) => {
        const transcript = Array.from(event.results)
          .map(result => result[0].transcript)
          .join(' ')
        setMessage(prev => prev + (prev ? ' ' : '') + transcript)
      }

      recognition.onend = () => {
        setIsListening(false)
      }

      setRecognition(recognition)
    } else {
      console.error('Speech recognition not supported in this browser')
    }
  }, [])

  const handleMicrophoneClick = () => {
    if (!recognition) return

    if (isListening) {
      recognition.stop()
    } else {
      recognition.start()
    }
  }

  const generateSubjectLine = async (message) => {
    try {
      const completion = await openai.chat.completions.create({
        model: "gpt-4",
        messages: [{
          role: "system",
          content: "You are a helpful assistant that generates concise subject lines. Create a brief (2-5 words) subject line that captures the main topic of the message. Return only the subject line text, nothing else."
        }, {
          role: "user",
          content: message
        }],
        temperature: 0.7,
      });

      return completion.choices[0].message.content.trim();
    } catch (error) {
      console.error('Error generating subject line:', error);
      return 'Support Request'; // Fallback subject line
    }
  };


      // Check authentication status
      const { data: { session } } = await supabase.auth.getSession()
      console.log('Current Session:', {
        accessToken: session?.access_token ? 'Present' : 'Missing',
        userId: session?.user?.id,
        userEmail: session?.user?.email,
      })
      
      // First verify if the user exists in the users table
      console.log('Checking if user exists in users table...')
      const { data: userExists, error: userCheckError } = await supabase
        .from('users')
        .select('id')
        .eq('id', user?.id)
        .single()

      console.log('User check result:', { userExists, userCheckError })
      
      if (userCheckError) {
        console.error('Error checking user:', userCheckError)
        throw new Error('Failed to verify user existence')
      }

      console.log('User from Context:', {
        id: user?.id,
        email: user?.email,
        metadata: user?.user_metadata,
        role: user?.role,
        aud: user?.aud
      })

      if (!user?.id) {
        console.error('No user ID available!')
        throw new Error('User ID is required')
      }

  

        
        {/* Toggle Switch */}
        <div className="flex items-center gap-3">
          <button
            onClick={() => setIsAIMode(!isAIMode)}
            className="flex items-center gap-2 px-3 py-1 rounded-full bg-white/5 hover:bg-white/10 transition-colors"
          >
            <span className="text-sm text-gray-400">AI Mode</span>
            <div className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors duration-300 ${
              isAIMode ? "bg-indigo-500" : "bg-gray-600"
            }`}>
              <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform duration-300 ${
                isAIMode ? "translate-x-4" : "translate-x-1"
              }`} />
            </div>
          </button>
          <button
            onClick={handleMicrophoneClick}
            className={`p-2 rounded-full transition-colors text-gray-400 hover:text-white group relative ${
              isListening ? 'bg-indigo-500/20 text-indigo-400' : 'bg-white/5 hover:bg-white/10'
            }`}
            title={isListening ? "Stop recording" : "Record message"}
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
            </svg>
            <div className={`absolute inset-0 border rounded-full pointer-events-none transition-colors ${
              isListening ? 'border-indigo-500 animate-pulse' : 'border-indigo-500/0 group-hover:border-indigo-500/20'
            }`} />
          </button>
        </div>
      </div>

      <div className="space-y-4">
        {/* AI Messages Area */}
        {isAIMode && aiMessages.length > 0 && (
          <div className="space-y-4 mb-4">
            {aiMessages.map((msg, index) => (
              <div key={index} className="space-y-4">
                {/* User Message */}
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-full bg-white/5 flex items-center justify-center flex-shrink-0">
                    <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                  </div>
                  <div className="flex-1 bg-white/5 rounded-lg px-4 py-3">
                    <p className="text-sm text-gray-300">{msg.question}</p>
                  </div>
                </div>
                {/* AI Response */}
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-full bg-indigo-500/20 flex items-center justify-center flex-shrink-0">
                    <svg className="w-5 h-5 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                    </svg>
                  </div>
                  <div className="flex-1 bg-indigo-500/10 rounded-lg px-4 py-3">
                    <p className="text-sm text-gray-300">{msg.answer}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Input Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="relative">
            <textarea
              rows={4}
              className={`w-full rounded-lg px-4 py-3 text-white placeholder-gray-400 ${
                isAIMode 
                  ? "border border-indigo-500/20 bg-white/5 focus:border-indigo-500 focus:ring-indigo-500"
                  : "border border-gray-600 bg-white/5 focus:border-gray-500 focus:ring-gray-500"
              }`}
              placeholder={isAIMode ? "Ask anything about the gym..." : "How can we help you today?"}
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              required
            />
            {isListening && (
              <div className="absolute right-3 top-3 flex items-center gap-2 px-2 py-1 rounded bg-indigo-500/20 border border-indigo-500/20">
                <div className="w-2 h-2 rounded-full bg-indigo-400 animate-pulse" />
                <span className="text-sm text-indigo-400">Recording...</span>
              </div>
            )}
          </div>
          <div className="flex justify-end">
            <button
              type="submit"
              disabled={isSubmitting}
              className={`flex items-center gap-2 py-2 px-6 border border-transparent rounded-full shadow-sm text-sm font-semibold text-white transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${
                isAIMode
                  ? "bg-indigo-500 hover:bg-indigo-600 focus:ring-indigo-500"
                  : "bg-gray-600 hover:bg-gray-700 focus:ring-gray-500"
              } focus:outline-none focus:ring-2 focus:ring-offset-2`}
            >
              {isSubmitting ? (
                <>
                  <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                  <span>Processing...</span>
                </>
              ) : (
                <>
                  <span>{isAIMode ? "Ask AI" : "Send Message"}</span>
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
                  </svg>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

const WorkoutLog = () => {
  const { user } = useAuth()
  const [workoutData, setWorkoutData] = useState([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState(null)
  const [recommendations, setRecommendations] = useState([])
  const [isLoadingRecommendations, setIsLoadingRecommendations] = useState(true)
  const [recommendationsError, setRecommendationsError] = useState(null)
  
  // Analytics state
  const [analyticsData, setAnalyticsData] = useState(null)
  const [isLoadingAnalytics, setIsLoadingAnalytics] = useState(true)
  const [analyticsError, setAnalyticsError] = useState(null)
  
  // Calendar state
  const [currentDate, setCurrentDate] = useState(new Date())
  const [selectedDate, setSelectedDate] = useState(null)
  
  // Calendar helper functions
  const getWeekDays = (date) => {
    const curr = new Date(date)
    const firstDay = new Date(curr.setDate(curr.getDate() - curr.getDay()))
    const days = []
    
    for (let i = 0; i < 7; i++) {
      days.push(new Date(new Date(firstDay).setDate(firstDay.getDate() + i)))
    }
    return days
  }
  
  const hasWorkoutsOnDate = (date) => {
    if (!date) return false
    return workoutData.some(workout => 
      new Date(workout.date).toDateString() === date.toDateString()
    )
  }
  
  const getFilteredWorkouts = () => {
    if (!selectedDate) return workoutData
    return workoutData.filter(workout => 
      new Date(workout.date).toDateString() === selectedDate.toDateString()
    )
  }
  
  const handleDateClick = (date) => {
    setSelectedDate(date?.toDateString() === selectedDate?.toDateString() ? null : date)
  }
  
  const handlePrevWeek = () => {
    setCurrentDate(new Date(currentDate.setDate(currentDate.getDate() - 7)))
  }
  
  const handleNextWeek = () => {
    setCurrentDate(new Date(currentDate.setDate(currentDate.getDate() + 7)))
  }

  // Fetch workout history from Supabase
  const fetchWorkoutHistory = async () => {
    try {
      const { data, error } = await supabase
        .from('workout_history')
        .select('*')
        .order('date', { ascending: false })

      if (error) throw error

      if (data) {
        // Transform Supabase data to match current format
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
    } catch (error) {
      console.error('Error fetching workout history:', error)
      setError(error.message)
      // Keep the default workout data as fallback
    } finally {
      setIsLoading(false)
    }
  }

  // Fetch analytics data
  const fetchAnalytics = async () => {
    setIsLoadingAnalytics(true)
    try {
      const { data, error } = await supabase.rpc('analyze_muscle_balance', {
        p_user_id: user.id,
        p_days: 30
      })
      
      if (error) throw error
      
      setAnalyticsData(data)
    } catch (error) {
      console.error('Error fetching analytics:', error)
      setAnalyticsError(error.message)
    } finally {
      setIsLoadingAnalytics(false)
    }
  }

  // Fetch recommendations from user profile
  const fetchRecommendations = async () => {
    try {
      setIsLoadingRecommendations(true);
      const { data, error } = await supabase
        .from('users')
        .select('injury_prevention_recommendations')
        .eq('id', user.id)
        .single();

      if (error) throw error;

      setRecommendations(data?.injury_prevention_recommendations || []);
    } catch (error) {
      console.error('Error fetching recommendations:', error);
      setRecommendationsError(error.message);
    } finally {
      setIsLoadingRecommendations(false);
    }
  };

  // Add recommendations fetch to useEffect
  useEffect(() => {
    fetchWorkoutHistory();
    fetchRecommendations();

    // Listen for new workouts added by Jim AI
    const handleWorkoutAdded = (event) => {
      const newWorkout = event.detail;
      setWorkoutData(prevData => [newWorkout, ...prevData]);
      // Refresh recommendations when new workout is added
      fetchRecommendations();
      toast.success(`Successfully logged ${newWorkout.exercise || 'workout'}!`);
    };

    // Subscribe to workout added events
    workoutEventEmitter.addEventListener(WORKOUT_ADDED_EVENT, handleWorkoutAdded);

    // Cleanup subscription
    return () => {
      workoutEventEmitter.removeEventListener(WORKOUT_ADDED_EVENT, handleWorkoutAdded);
    };
  }, []);

  // Initialize speech recognition and states
  const [recognition, setRecognition] = useState(null)
  const [isListening, setIsListening] = useState(false)
  const [currentTranscript, setCurrentTranscript] = useState('')
  const [isProcessing, setIsProcessing] = useState(false)

  // Add this function before parseTranscript
  const cleanWorkoutData = (data) => {
    // Helper function to capitalize first letter of each word
    const capitalizeWords = (str) => {
      return str?.split(' ')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
        .join(' ');
    };

    // Helper function to capitalize only first letter of a sentence
    const capitalizeSentence = (str) => {
      return str?.split('. ')
        .map(sentence => sentence.charAt(0).toUpperCase() + sentence.slice(1).toLowerCase())
        .join('. ');
    };

    // Helper function to convert word numbers to digits
    const wordToNumber = (str) => {
      const numberWords = {
        'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4',
        'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
        'ten': '10', 'eleven': '11', 'twelve': '12', 'thirteen': '13',
        'fourteen': '14', 'fifteen': '15', 'sixteen': '16', 'seventeen': '17',
        'eighteen': '18', 'nineteen': '19', 'twenty': '20'
      };
      
      return str?.toLowerCase().split(' ').map(word => 
        numberWords[word] || word
      ).join(' ');
    };

    return {
      exercise: capitalizeWords(data.exercise || ''),
      weight: data.weight ? wordToNumber(data.weight.toString()) : '',
      sets: data.sets ? wordToNumber(data.sets.toString()) : '',
      reps: data.reps ? wordToNumber(data.reps.toString()) : '',
      bodyweight: data.bodyweight ? wordToNumber(data.bodyweight.toString()) : '',
      notes: data.notes ? 
        (data.notes.trim().endsWith('.') ? 
          capitalizeSentence(data.notes) : 
          capitalizeSentence(data.notes) + '.'
        ) : ''
    };
  };

  const parseTranscript = async (transcript) => {
    setIsProcessing(true)
    try {
      console.log('Starting OpenAI request with transcript:', transcript)
      
      const completion = await openai.chat.completions.create({
        model: "gpt-4",
        messages: [{
          role: "system",
          content: "You are a fitness tracking assistant. Parse the following workout description and extract the information in a JSON format with the following fields: exercise, weight, sets, reps, bodyweight (if mentioned), notes (any additional comments). Return null for any fields not mentioned. Return only the JSON object without any markdown formatting."
        }, {
          role: "user",
          content: transcript
        }],
        temperature: 0.7,
      })

      const response = completion.choices[0].message
      console.log('Raw OpenAI Response:', response)

      const cleanContent = response.content.replace(/```json\n?|\n?```/g, '').trim()
      console.log('Cleaned content:', cleanContent)

      const parsedData = JSON.parse(cleanContent)
      console.log('Parsed workout data:', parsedData)

      // Clean and format the parsed data
      const cleanedData = cleanWorkoutData(parsedData)
      console.log('Cleaned workout data:', cleanedData)

      const workoutEntry = await createWorkoutEntry(cleanedData)
      console.log('Created workout entry:', workoutEntry)

      // Add new workout entry to the state
      const newWorkout = {
        id: workoutData.length + 1,
        date: new Date().toLocaleDateString(),
        ...workoutEntry
      }
      
      setWorkoutData(prevData => [...prevData, newWorkout])
      
      // Show success notification with longer duration
      toast.success(`Successfully logged ${newWorkout.exercise || 'workout'}!`, {
        duration: 5000
      })
      
      return cleanedData
      
    } catch (error) {
      console.error('Error parsing workout data:', error)
      toast.error('Failed to log workout. Please try again.', {
        duration: 5000
      })
      return {
        exercise: null,
        weight: null,
        sets: null,
        reps: null,
        bodyweight: null,
        notes: null
      }
    } finally {
      setIsProcessing(false)
    }
  }

  useEffect(() => {
    if ('webkitSpeechRecognition' in window) {
      const recognition = new window.webkitSpeechRecognition()
      recognition.continuous = true
      recognition.interimResults = false
      
      recognition.onstart = () => {
        setIsListening(true)
        setCurrentTranscript('')
      }

      recognition.onresult = (event) => {
        const transcript = Array.from(event.results)
          .map(result => result[0].transcript)
          .join(' ')
        setCurrentTranscript(transcript)
        console.log('Current transcript:', transcript)
      }

      recognition.onend = () => {
        console.log('Speech recognition ended')
        setIsListening(false)
      }

      setRecognition(recognition)
    } else {
      console.error('Speech recognition not supported in this browser')
    }
  }, []) // Remove currentTranscript dependency

  const handleMicrophoneClick = async () => {
    if (!recognition) return

    if (isListening) {
      recognition.stop()
      // Make OpenAI call after stopping if we have a transcript
      if (currentTranscript) {
        // Clear transcript immediately before processing starts
        const savedTranscript = currentTranscript
        setCurrentTranscript('')
        await parseTranscript(savedTranscript)
      }
    } else {
      recognition.start()
    }
  }

  const handleCellChange = async (id, field, newValue) => {
    // Optimistically update UI
    setWorkoutData(workoutData.map(workout => 
      workout.id === id 
        ? { ...workout, [field]: newValue }
        : workout
    ))

    try {
      // Prepare the update data
      const updateData = {
        [field]: field === 'sets' || field === 'reps' 
          ? parseInt(newValue) || null
          : field === 'bodyweight'
            ? parseFloat(newValue) || null
            : newValue
      }

      // Update in Supabase
      const { error } = await supabase
        .from('workout_history')
        .update(updateData)
        .eq('id', id)

      if (error) throw error

      toast.success('Workout updated successfully')
    } catch (error) {
      console.error('Error updating workout:', error)
      toast.error('Failed to update workout')
      
      // Revert the optimistic update on error
      fetchWorkoutHistory()
    }
  }

  // Update createWorkoutEntry function
  const createWorkoutEntry = async (parsedData) => {
    console.log('Creating workout entry from:', parsedData)
    
    // Create entry object for both local state and Supabase
    const workoutEntry = {
      user_id: user.id,  // Add user_id from auth context
      date: new Date().toISOString(),  // Store as ISO string for Supabase
      exercise: parsedData.exercise || '',
      weight: parsedData.weight ? `${parsedData.weight}` : '',
      sets: parsedData.sets ? parseInt(parsedData.sets) : null,  // Convert to number for Supabase
      reps: parsedData.reps ? parseInt(parsedData.reps) : null,  // Convert to number for Supabase
      bodyweight: parsedData.bodyweight ? parseFloat(parsedData.bodyweight) : null,  // Convert to number for Supabase
      notes: parsedData.notes || ''
    }

    try {
      // Insert into Supabase
      const { data, error } = await supabase
        .from('workout_history')
        .insert([workoutEntry])
        .select()
        .single()

      if (error) throw error

      // Return formatted data for local state
      return {
        id: data.id,
        date: new Date(data.date).toLocaleDateString(),
        exercise: data.exercise,
        weight: data.weight || '',
        sets: data.sets?.toString() || '',
        reps: data.reps?.toString() || '',
        bodyweight: data.bodyweight?.toString() || '',
        notes: data.notes || ''
      }
    } catch (error) {
      console.error('Error creating workout:', error)
      toast.error('Failed to save workout')
      // Return formatted data for local state as fallback
      return {
        id: workoutData.length + 1,
        date: new Date().toLocaleDateString(),
        ...workoutEntry,
        sets: workoutEntry.sets?.toString() || '',
        reps: workoutEntry.reps?.toString() || '',
        bodyweight: workoutEntry.bodyweight?.toString() || ''
      }
    }
  }

  const handleDeleteWorkout = async (id) => {
    // Ask for confirmation
    if (!window.confirm('Are you sure you want to delete this workout entry?')) {
      return
    }

    try {
      // Delete from Supabase
      const { error } = await supabase
        .from('workout_history')
        .delete()
        .eq('id', id)

      if (error) throw error

      // If successful, update local state
      setWorkoutData(prevData => prevData.filter(workout => workout.id !== id))
      toast.success('Workout deleted successfully')
    } catch (error) {
      console.error('Error deleting workout:', error)
      toast.error('Failed to delete workout')
    }
  }

  return (
    <>
      {/* AI Workout Tracking Box */}
      <div className="bg-white/5 rounded-xl p-6 backdrop-blur-sm">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-2">
            <h3 className="text-xl font-semibold text-white/90">AI Workout Tracking</h3>
            <div className="relative group">
              <button
                className="p-2 rounded-full bg-white/5 hover:bg-white/10 transition-colors text-gray-400 hover:text-white"
                title="How it works"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </button>
              <div className="absolute left-0 top-full mt-2 w-80 p-4 rounded-lg bg-gray-900/95 backdrop-blur-sm shadow-xl border border-gray-800 invisible group-hover:visible opacity-0 group-hover:opacity-100 transition-all duration-200 z-10">
                <h4 className="font-medium text-white mb-2">How to Log Your Workout</h4>
                <p className="text-sm text-gray-300 mb-3">
                  Simply click the microphone icon and speak your workout details naturally. The AI will automatically parse and log your workout in the table below.
                </p>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-4">
            {currentTranscript && (
              <div className="flex items-center gap-2 bg-white/5 px-4 py-2 rounded-lg border border-[#e12c4c]/20">
                <div className="w-2 h-2 rounded-full bg-[#e12c4c] animate-pulse" />
                <p className="text-sm text-gray-300">{currentTranscript}</p>
              </div>
            )}
            {isListening && !currentTranscript && (
              <span className="text-sm text-gray-400">
                Recording...
              </span>
            )}
            {isProcessing && (
              <div className="flex items-center gap-2 bg-white/5 px-4 py-2 rounded-lg border border-[#e12c4c]/20">
                <svg className="animate-spin h-4 w-4 text-[#e12c4c]" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                <span className="text-sm text-gray-300">Processing workout...</span>
              </div>
            )}
            <button
              onClick={handleMicrophoneClick}
              disabled={isProcessing}
              className={`p-2.5 rounded-full transition-colors text-gray-400 hover:text-white group relative ${
                isListening ? 'bg-[#e12c4c]/20 text-[#e12c4c]' : 'bg-white/5 hover:bg-white/10'
              } ${isProcessing ? 'opacity-50 cursor-not-allowed' : ''}`}
              title={isListening ? "Stop recording" : "Record workout"}
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
              </svg>
              <div className={`absolute inset-0 border rounded-full pointer-events-none transition-colors ${
                isListening ? 'border-[#e12c4c] animate-pulse' : 'border-[#e12c4c]/0 group-hover:border-[#e12c4c]/20'
              }`} />
            </button>
          </div>
        </div>
        
        {/* Calendar Filter */}
        <div className="mb-6 bg-white/5 rounded-lg p-4 border border-gray-800">
          <div className="flex items-center justify-between mb-4">
            <button
              onClick={handlePrevWeek}
              className="p-2 rounded-lg hover:bg-white/5 text-gray-400 hover:text-white transition-colors"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <h3 className="text-lg font-medium text-white">
              {(() => {
                const weekDays = getWeekDays(currentDate)
                const firstDay = weekDays[0]
                const lastDay = weekDays[6]
                const sameMonth = firstDay.getMonth() === lastDay.getMonth()
                const sameYear = firstDay.getFullYear() === lastDay.getFullYear()
                
                if (sameMonth && sameYear) {
                  return `${firstDay.toLocaleString('default', { month: 'long' })} ${firstDay.getDate()}-${lastDay.getDate()}, ${firstDay.getFullYear()}`
                } else if (sameYear) {
                  return `${firstDay.toLocaleString('default', { month: 'short' })} ${firstDay.getDate()} - ${lastDay.toLocaleString('default', { month: 'short' })} ${lastDay.getDate()}, ${firstDay.getFullYear()}`
                } else {
                  return `${firstDay.toLocaleString('default', { month: 'short' })} ${firstDay.getDate()}, ${firstDay.getFullYear()} - ${lastDay.toLocaleString('default', { month: 'short' })} ${lastDay.getDate()}, ${lastDay.getFullYear()}`
                }
              })()}
            </h3>
            <button
              onClick={handleNextWeek}
              className="p-2 rounded-lg hover:bg-white/5 text-gray-400 hover:text-white transition-colors"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </button>
          </div>
          
          <div className="grid grid-cols-7 gap-1">
            {/* Day headers */}
            {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(day => (
              <div key={day} className="text-center text-xs font-medium text-gray-400 py-1">
                {day}
              </div>
            ))}
            
            {/* Calendar days */}
            {getWeekDays(currentDate).map((date, index) => (
              <button
                key={index}
                onClick={() => date && handleDateClick(date)}
                disabled={!date}
                className={`
                  h-8 flex items-center justify-center rounded-lg text-sm font-medium
                  ${!date ? 'invisible' : 'hover:bg-white/10'}
                  ${date && hasWorkoutsOnDate(date) ? 'text-[#e12c4c]' : 'text-gray-400'}
                  ${date && selectedDate?.toDateString() === date.toDateString() ? 'bg-white/10 text-white' : ''}
                  transition-colors
                `}
              >
                {date?.getDate()}
              </button>
            ))}
          </div>
          
          {selectedDate && (
            <div className="mt-4 flex items-center justify-between">
              <span className="text-sm text-gray-400">
                Showing workouts for {selectedDate.toLocaleDateString()}
              </span>
              <button
                onClick={() => setSelectedDate(null)}
                className="text-sm text-[#e12c4c] hover:text-[#e12c4c]/80 transition-colors"
              >
                Clear filter
              </button>
            </div>
          )}
        </div>
        
        <div className="overflow-x-auto">
          {isLoading ? (
            <div className="flex items-center justify-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white/20"></div>
            </div>
          ) : (
            <table className="min-w-full divide-y divide-gray-800 border border-gray-800 rounded-lg">
              <thead>
                <tr className="bg-white/5">
                  <th scope="col" className="w-32 px-3 py-3.5 text-left text-xs font-semibold text-gray-300 uppercase tracking-wider border-r border-gray-800">
                    Date
                  </th>
                  <th scope="col" className="w-48 px-3 py-3.5 text-left text-xs font-semibold text-gray-300 uppercase tracking-wider border-r border-gray-800">
                    Exercise
                  </th>
                  <th scope="col" className="w-24 px-3 py-3.5 text-left text-xs font-semibold text-gray-300 uppercase tracking-wider border-r border-gray-800">
                    Weight
                  </th>
                  <th scope="col" className="w-20 px-3 py-3.5 text-center text-xs font-semibold text-gray-300 uppercase tracking-wider border-r border-gray-800">
                    Sets
                  </th>
                  <th scope="col" className="w-20 px-3 py-3.5 text-center text-xs font-semibold text-gray-300 uppercase tracking-wider border-r border-gray-800">
                    Reps
                  </th>
                  <th scope="col" className="w-full px-3 py-3.5 text-left text-xs font-semibold text-gray-300 uppercase tracking-wider">
                    Notes
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-800">
                {getFilteredWorkouts().map(workout => (
                  <tr key={workout.id} className="hover:bg-white/5">
                    <td className="w-32 px-3 py-4 whitespace-nowrap text-sm text-gray-300 border-r border-gray-800">
                      <EditableCell 
                        value={workout.date} 
                        onChange={(newValue) => handleCellChange(workout.id, 'date', newValue)} 
                      />
                    </td>
                    <td className="w-48 px-3 py-4 whitespace-nowrap text-sm text-gray-300 border-r border-gray-800">
                      <EditableCell 
                        value={workout.exercise} 
                        onChange={(newValue) => handleCellChange(workout.id, 'exercise', newValue)} 
                      />
                    </td>
                    <td className="w-24 px-3 py-4 whitespace-nowrap text-sm text-gray-300 border-r border-gray-800">
                      <EditableCell 
                        value={workout.weight} 
                        onChange={(newValue) => handleCellChange(workout.id, 'weight', newValue)} 
                      />
                    </td>
                    <td className="w-20 px-3 py-4 whitespace-nowrap text-sm text-gray-300 text-center border-r border-gray-800">
                      <EditableCell 
                        value={workout.sets} 
                        onChange={(newValue) => handleCellChange(workout.id, 'sets', newValue)} 
                        type="number"
                      />
                    </td>
                    <td className="w-20 px-3 py-4 whitespace-nowrap text-sm text-gray-300 text-center border-r border-gray-800">
                      <EditableCell 
                        value={workout.reps} 
                        onChange={(newValue) => handleCellChange(workout.id, 'reps', newValue)} 
                        type="number"
                      />
                    </td>
                    <td className="w-full px-3 py-4 text-sm text-gray-300 relative">
                      <div className="flex items-center">
                        <EditableCell 
                          value={workout.notes} 
                          onChange={(newValue) => handleCellChange(workout.id, 'notes', newValue)} 
                        />
                        <button
                          onClick={() => handleDeleteWorkout(workout.id)}
                          className="p-2 rounded-full hover:bg-white/10 text-gray-400 hover:text-[#e12c4c] transition-colors opacity-0 group-hover:opacity-100 absolute right-2"
                          title="Delete workout"
                        >
                          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
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
      </div>

      {/* Injury Prevention Corner */}
      {false && (  // Adding false condition to hide this section
        <div className="mt-8 bg-white/5 rounded-xl p-6 backdrop-blur-sm">
          <div className="flex items-center gap-2 mb-6">
            <h3 className="text-xl font-semibold text-white/90">Injury Prevention Corner</h3>
            <div className="relative group">
              <button
                className="p-2 rounded-full bg-white/5 hover:bg-white/10 transition-colors text-gray-400 hover:text-white"
                title="About Injury Prevention"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </button>
              <div className="absolute left-0 top-full mt-2 w-80 p-4 rounded-lg bg-gray-900/95 backdrop-blur-sm shadow-xl border border-gray-800 invisible group-hover:visible opacity-0 group-hover:opacity-100 transition-all duration-200 z-10">
                <h4 className="font-medium text-white mb-2">About Injury Prevention</h4>
                <p className="text-sm text-gray-300">
                  Get personalized recommendations to help prevent injuries based on your workout patterns and recovery status.
                </p>
              </div>
            </div>
          </div>

          <div className="bg-white/5 rounded-lg p-6 border border-gray-800">
            <h4 className="text-lg font-medium text-white mb-4">Recommendations</h4>
            {isLoadingRecommendations ? (
              <div className="flex items-center justify-center h-32">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white/20"></div>
              </div>
            ) : recommendationsError ? (
              <div className="text-center text-sm text-gray-400">
                Unable to load recommendations. Please try again later.
              </div>
            ) : recommendations?.length > 0 ? (
              <div className="space-y-4">
                {recommendations.map((rec, index) => (
                  <div 
                    key={index} 
                    className="p-4 bg-white/5 rounded-lg border border-gray-800/50 hover:border-gray-800 transition-colors"
                  >
                    <div className="flex items-start gap-3">
                      <div className="h-8 w-8 rounded-full bg-indigo-500/20 flex items-center justify-center flex-shrink-0 mt-1">
                        <svg className="w-5 h-5 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h14M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                        </svg>
                      </div>
                      <div className="flex-1">
                        <p className="text-sm text-gray-300">{rec.recommendation}</p>
                        <p className="text-xs text-gray-500 mt-1">
                          {new Date(rec.created_at).toLocaleDateString()} at {new Date(rec.created_at).toLocaleTimeString()}
                        </p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="flex items-center justify-center h-32 text-sm text-gray-400">
                Start logging your workouts to get personalized injury prevention recommendations
              </div>
            )}
          </div>
        </div>
      )}
    </>
  )
}

const MemberSidebar = ({ activeView, onViewChange }) => (
  <div className="w-64 flex-shrink-0 bg-white/5 border-r border-gray-800 overflow-y-auto h-screen">
    <div className="p-4">
      <h2 className="text-lg font-semibold text-white mb-6 px-3">Member Portal</h2>
      <nav className="space-y-1">
        <div>
          <p className="px-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">
            Support
          </p>
          <div className="mt-2">
            <button
              onClick={() => onViewChange('support')}
              className={`w-full flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors ${
                activeView === 'support' 
                  ? 'text-white bg-white/10' 
                  : 'text-gray-300 hover:text-white hover:bg-white/5'
              }`}
            >
              <svg className="mr-3 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
              </svg>
              Member Support
            </button>
          </div>
        </div>

        <div className="pt-4">
          <p className="px-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">
            Schedule
          </p>
          <div className="mt-2 space-y-1">
            <button
              onClick={() => onViewChange('upcoming')}
              className={`w-full flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors ${
                activeView === 'upcoming' 
                  ? 'text-white bg-white/10' 
                  : 'text-gray-300 hover:text-white hover:bg-white/5'
              }`}
            >
              <svg className="mr-3 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              Your Upcoming Events
            </button>
            <button
              onClick={() => onViewChange('classes')}
              className={`w-full flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors ${
                activeView === 'classes' 
                  ? 'text-white bg-white/10' 
                  : 'text-gray-300 hover:text-white hover:bg-white/5'
              }`}
            >
              <svg className="mr-3 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
              Available Classes
            </button>
            <button
              onClick={() => onViewChange('training')}
              className={`w-full flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors ${
                activeView === 'training' 
                  ? 'text-white bg-white/10' 
                  : 'text-gray-300 hover:text-white hover:bg-white/5'
              }`}
            >
              <svg className="mr-3 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
              </svg>
              Personal Training
            </button>
          </div>
        </div>

        <div className="pt-4">
          <p className="px-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">
            Activity
          </p>
          <div className="mt-2 space-y-1">
            <button
              onClick={() => onViewChange('visits')}
              className={`w-full flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors ${
                activeView === 'visits' 
                  ? 'text-white bg-white/10' 
                  : 'text-gray-300 hover:text-white hover:bg-white/5'
              }`}
            >
              <svg className="mr-3 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              Recent Visits
            </button>
            <button
              onClick={() => onViewChange('logs')}
              className={`w-full flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors ${
                activeView === 'logs' 
                  ? 'text-white bg-white/10' 
                  : 'text-gray-300 hover:text-white hover:bg-white/5'
              }`}
            >
              <svg className="mr-3 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
              AI Workout Tracking
            </button>
          </div>
        </div>
      </nav>
    </div>
  </div>
)

export default function MemberPortal() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [showAccountMenu, setShowAccountMenu] = useState(false)
  const [activeView, setActiveView] = useState('support')

  const handleSignOut = async () => {
    const { error } = await supabase.auth.signOut()
    if (!error) {
      navigate('/')
    }
  }

  const renderContent = () => {
    switch (activeView) {
      case 'support':
        return <SupportForm />
      case 'upcoming':
        return <UpcomingEvents />
      case 'classes':
        return <ClassBooking />
      case 'training':
        return <PTBooking />
      case 'visits':
        return <VisitHistory />
      case 'logs':
        return <WorkoutLog />
      default:
        return <SupportForm />
    }
  }

  return (
    <div className="bg-[#1a1b23] text-white h-screen flex">
      <MemberSidebar activeView={activeView} onViewChange={setActiveView} />
      
      <div className="flex-1 flex flex-col overflow-hidden">
        <div className="flex-shrink-0 border-b border-gray-800 p-8">
          <div className="flex items-center justify-between">
            <h1 className="text-3xl font-bold">Welcome back, {user?.user_metadata?.first_name || 'Member'}</h1>
            <div className="flex items-center gap-4">
              <span className="px-4 py-1 rounded-full bg-indigo-500/20 text-indigo-400 text-sm">
                Premium Member
              </span>
              <div className="relative">
                <button
                  onClick={() => setShowAccountMenu(!showAccountMenu)}
                  className="p-2 rounded-full hover:bg-white/5 transition-colors"
                >
                  <svg className="w-6 h-6 text-gray-300 hover:text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5.121 17.804A13.937 13.937 0 0112 16c2.5 0 4.847.655 6.879 1.804M15 10a3 3 0 11-6 0 3 3 0 016 0zm6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </button>
                {showAccountMenu && (
                  <div className="absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white/10 backdrop-blur-sm ring-1 ring-black ring-opacity-5 z-10">
                    <div className="py-1">
                      <div className="px-4 py-2 text-sm text-gray-300 border-b border-gray-700">
                        <p className="font-medium">{user?.user_metadata?.first_name} {user?.user_metadata?.last_name}</p>
                        <p className="text-gray-400 text-xs">{user?.email}</p>
                      </div>
                      <a href="#" className="block px-4 py-2 text-sm text-gray-300 hover:bg-white/5">
                        Account Settings
                      </a>
                      <button
                        onClick={handleSignOut}
                        className="w-full text-left px-4 py-2 text-sm text-gray-300 hover:bg-white/5"
                      >
                        Sign Out
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-8">
          {renderContent()}
        </div>
      </div>

      <AIAssistant />
    </div>
  )
} 