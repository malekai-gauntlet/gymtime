# Snippet of code of my other AI agent that is a injury prevention coach


// Initialize LangChain Chat Model
const chatModel = new ChatOpenAI({
  modelName: "gpt-4",
  temperature: 0.7,
  streaming: true,
  openAIApiKey: import.meta.env.VITE_OPENAI_API_KEY,
});

// Add this before the initializeAgent function
let addThinkingStepCallback = null;

// Modify the initializeAgent function
const initializeAgent = async () => {
  const executor = await initializeAgentExecutorWithOptions(
    [muscleBalanceAnalysis, dateTimeTool, workoutEntryTool, classBookingTool, knowledgeBaseTool, workoutHistoryTool],
    chatModel,
    {
      agentType: "openai-functions",
      memory: new BufferMemory({
        returnMessages: true,
        memoryKey: "chat_history",
        outputKey: "output",
      }),
      agentArgs: {
        prefix: `You are an intelligent gym assistant named Jim that helps gym members in a variety of ways. 
        You have access to the following tools:
        A knowledge base tool that can search the gym's knowledge base for facility-specific information.
        A workout analysis tool that can detect muscle imbalances and provide injury-prevention recommendations.
        A date/time tool that can provide current date and time information.
        A class booking tool that can help members view available classes and book classes.
        A workout entry tool that can log workouts when members tell you about their training sessions.
        A workout history tool that can show past workouts and provide exercise statistics.


        Use the knowledge base tool whenever members ask about gym policies or rules, or need information about specific services or amenities or anything else related to the gym.
        Use the workout analysis tool whenever members ask about their workout balance or progress, or checking for potential overtraining.
        Use the datetime tool when members ask about time or date, or are asking a question that requires knowledge of the date. (e.g. "What classes are available today? Or tomororow? Or next week?")
        Use the class booking tool when members ask about classes, or want to book a class. Use the class booking tool with action "list_classes" to show available classes, and "book_class" with the exact class name to book a specific class.
        Use the workout entry tool when members tell you about a workout they just completed, or want to log their training session.
        Use the workoutHistory tool when members ask about their past workouts, exercise statistics, or workout summaries. Use "show_history" for specific dates (YYYY-MM-DD format), "exercise_stats" for specific exercise analysis, and "summary" for overall workout patterns. When reporting workout summaries, clearly distinguish between number of unique workout days and total exercises performed.
        
        Always be friendly, clear, and concise. Address members by their first name when appropriate.`
      },
      callbacks: [{


# Snippet of the workout analysis tool


import { supabase } from './supabaseClient';
import { DynamicStructuredTool } from 'langchain/tools';
import { z } from "zod";

const workoutAnalysisSchema = z.object({
  userId: z.string().describe("The user's ID to analyze workout history for"),
  daysToAnalyze: z.number().optional().default(30).describe("Number of days of history to analyze")
});

/**
 * Tool for analyzing muscle balance from workout history
 */
export const muscleBalanceAnalysis = new DynamicStructuredTool({
  name: "muscleBalanceAnalysis",
  description: "Analyzes workout history to check muscle balance and identify potential issues. Requires the user's UUID, not their email.",
  schema: z.object({
    userId: z.string().uuid().describe("The UUID of the user whose workouts to analyze (not their email)"),
    daysToAnalyze: z.number().describe("Number of days of workout history to analyze")
  }),
  func: async ({ userId, daysToAnalyze }) => {
    console.log('Workout Analysis Tool called with:', { userId, daysToAnalyze });
    try {
      // Fetch workout data for the specified time period
      const { data: workoutData, error } = await supabase
        .from('workout_history')
        .select('*')
        .eq('user_id', userId)
        .gte('date', new Date(Date.now() - daysToAnalyze * 24 * 60 * 60 * 1000).toISOString());

      if (error) throw error;

      // Initialize analysis object
      const analysis = {
        muscleGroups: {},
        pushPullRatio: 0,
        warnings: [],
        recommendations: []
      };

      // Calculate muscle group frequencies
      workoutData.forEach(workout => {
        workout.muscle_groups?.forEach(muscle => {
          if (!analysis.muscleGroups[muscle]) {
            analysis.muscleGroups[muscle] = {
              count: 0,
              lastWorkout: null
            };
          }
          analysis.muscleGroups[muscle].count++;
          if (!analysis.muscleGroups[muscle].lastWorkout || 
              new Date(workout.date) > new Date(analysis.muscleGroups[muscle].lastWorkout)) {
            analysis.muscleGroups[muscle].lastWorkout = workout.date;
          }
        });
      });

      // Calculate push/pull ratio
      const pushCount = (analysis.muscleGroups['chest']?.count || 0) + 
                       (analysis.muscleGroups['triceps']?.count || 0) + 
                       (analysis.muscleGroups['shoulders']?.count || 0);
      const pullCount = (analysis.muscleGroups['back']?.count || 0) + 
                       (analysis.muscleGroups['biceps']?.count || 0);
      
      analysis.pushPullRatio = pullCount / (pushCount || 1);

      // Generate warnings for imbalances
      if (analysis.pushPullRatio > 2) {
        analysis.warnings.push("Significant imbalance detected: Pull exercises greatly exceed push exercises");
      }
      if (analysis.pushPullRatio < 0.5) {
        analysis.warnings.push("Significant imbalance detected: Push exercises greatly exceed pull exercises");
      }

      // Add frequency-based muscle group disparity warnings
      // These pairs represent antagonist (opposing) muscle groups that should be trained with similar frequency
      // to maintain muscular balance and prevent postural issues or injury
      const muscleGroupPairs = [
        ['chest', 'back'],          // Push/pull balance for upper body
        ['biceps', 'triceps'],      // Arm balance to prevent elbow issues
        ['quadriceps', 'hamstrings'],// Leg balance to prevent knee issues
        ['shoulders', 'back']        // Upper body vertical push/pull balance
      ];

      // Compare each muscle group pair for significant imbalances
      muscleGroupPairs.forEach(([muscle1, muscle2]) => {
        const count1 = analysis.muscleGroups[muscle1]?.count || 0;
        const count2 = analysis.muscleGroups[muscle2]?.count || 0;
        // Only check if both muscles have been trained at least once
        if (count1 > 0 && count2 > 0) {
          // Calculate the ratio between the more frequently trained muscle to the less frequently trained
          // A ratio > 3 indicates one muscle is being trained more than 3x as often as its antagonist
          const ratio = Math.max(count1, count2) / Math.min(count1, count2);
          if (ratio > 3) {  // Research-based threshold for significant imbalance
            const higherMuscle = count1 > count2 ? muscle1 : muscle2;
            const lowerMuscle = count1 > count2 ? muscle2 : muscle1;
            const higherCount = Math.max(count1, count2);
            const lowerCount = Math.min(count1, count2);
            analysis.warnings.push(`Significant muscle group imbalance: ${higherMuscle} (${higherCount} workouts) vs ${lowerMuscle} (${lowerCount} workouts)`);
            analysis.recommendations.push(`Consider increasing ${lowerMuscle} training frequency to balance with ${higherMuscle}`);
          }
        }
      });

      // Add time-based warnings for muscle group training frequency
      // Different muscle groups have different optimal training frequencies
      const muscleGroupFrequencies = {
        'legs': 7,      // Large muscle group - warning after 7 days
        'back': 7,      // Large muscle group
        'chest': 7,     // Large muscle group
        'biceps': 5,    // Small muscle group - warning after 5 days
        'triceps': 5,   // Small muscle group
        'shoulders': 7, // Medium/large muscle group
        'core': 4,      // Core can be trained more frequently
        'abs': 4        // Core/stabilizer muscles
      };

      // Check each muscle group's last workout date
      Object.entries(muscleGroupFrequencies).forEach(([muscle, maxDays]) => {
        const lastWorkout = analysis.muscleGroups[muscle]?.lastWorkout;
        if (lastWorkout) {
          const daysSinceLastWorkout = Math.floor((Date.now() - new Date(lastWorkout)) / (1000 * 60 * 60 * 24));
          if (daysSinceLastWorkout > maxDays) {
            analysis.warnings.push(`${muscle} hasn't been trained in ${daysSinceLastWorkout} days (recommended: every ${maxDays} days)`);
            analysis.recommendations.push(`Consider training ${muscle} in your next workout session`);
          }
        }
      });

      // Volume-based comparisons between related muscle groups
      // These comparisons help ensure balanced development and reduce injury risk
      const volumeRelationships = [
        {
          groups: ['chest', 'back'],
          name: 'Push/Pull Volume',
          idealRatio: 1,  // 1:1 ratio ideal for chest:back
          tolerance: 0.3  // Allow 30% deviation
        },
        {
          groups: [['chest', 'shoulders', 'triceps'], ['back', 'biceps', 'legs']],
          name: 'Upper/Lower Volume',
          idealRatio: 1,  // 1:1 ratio for upper:lower
          tolerance: 0.5  // Allow 50% deviation due to different training needs
        },
        {
          groups: ['biceps', 'triceps'],
          name: 'Arm Balance',
          idealRatio: 1,  // 1:1 ratio ideal for biceps:triceps
          tolerance: 0.2  // Allow 20% deviation
        }
      ];

      // Calculate and check volume relationships
      volumeRelationships.forEach(relationship => {
        if (Array.isArray(relationship.groups[0])) {
          // Handle muscle group combinations (e.g., upper/lower body)
          const group1Total = relationship.groups[0]
            .reduce((sum, muscle) => sum + (analysis.muscleGroups[muscle]?.count || 0), 0);
          const group2Total = relationship.groups[1]
            .reduce((sum, muscle) => sum + (analysis.muscleGroups[muscle]?.count || 0), 0);
          
          if (group1Total > 0 && group2Total > 0) {
            const ratio = group1Total / group2Total;
            const lowerBound = relationship.idealRatio * (1 - relationship.tolerance);
            const upperBound = relationship.idealRatio * (1 + relationship.tolerance);
            
            if (ratio < lowerBound || ratio > upperBound) {
              const group1Names = relationship.groups[0].join('/');
              const group2Names = relationship.groups[1].join('/');
              analysis.warnings.push(
                `${relationship.name} imbalance detected: ${group1Names} (${group1Total} sessions) vs ${group2Names} (${group2Total} sessions)`
              );
              if (ratio < lowerBound) {
                analysis.recommendations.push(
                  `Consider increasing ${group1Names} volume to maintain balanced development`
                );
              } else {
                analysis.recommendations.push(
                  `Consider increasing ${group2Names} volume to maintain balanced development`
                );
              }
            }
          }
        } else {
          // Handle simple muscle pairs
          const count1 = analysis.muscleGroups[relationship.groups[0]]?.count || 0;
          const count2 = analysis.muscleGroups[relationship.groups[1]]?.count || 0;
          
          if (count1 > 0 && count2 > 0) {
            const ratio = count1 / count2;
            const lowerBound = relationship.idealRatio * (1 - relationship.tolerance);
            const upperBound = relationship.idealRatio * (1 + relationship.tolerance);
            
            if (ratio < lowerBound || ratio > upperBound) {
              analysis.warnings.push(
                `${relationship.name} imbalance detected: ${relationship.groups[0]} (${count1} sessions) vs ${relationship.groups[1]} (${count2} sessions)`
              );
              if (ratio < lowerBound) {
                analysis.recommendations.push(
                  `Consider increasing ${relationship.groups[0]} volume to maintain balanced development`
                );
              } else {
                analysis.recommendations.push(
                  `Consider increasing ${relationship.groups[1]} volume to maintain balanced development`
                );
              }
            }
          }
        }
      });

      // Check for neglected muscle groups
      const muscleGroups = ['legs', 'chest', 'back', 'shoulders', 'biceps', 'triceps', 'core'];
      muscleGroups.forEach(muscle => {
        if (!analysis.muscleGroups[muscle] || analysis.muscleGroups[muscle].count === 0) {
          analysis.warnings.push(`${muscle} appears to be neglected in your training`);
        }
      });

      // Generate recommendations based on analysis
      if (analysis.warnings.length > 0) {
        if (analysis.pushPullRatio > 2) {
          analysis.recommendations.push("Consider incorporating more push exercises (chest, shoulders, triceps) to balance your training");
        }
        if (analysis.pushPullRatio < 0.5) {
          analysis.recommendations.push("Consider incorporating more pull exercises (back, biceps) to balance your training");
        }
        
        // Add recommendations for neglected muscle groups
        muscleGroups.forEach(muscle => {
          if (!analysis.muscleGroups[muscle] || analysis.muscleGroups[muscle].count === 0) {
            analysis.recommendations.push(`Add ${muscle} exercises to your routine for balanced development`);
          }
        });
      }

      const result = JSON.stringify(analysis);
      console.log('Analysis result:', result);
      return result;
    } catch (error) {
      console.error('Error in workout analysis:', error);
      throw error;
    }
  }
}); 