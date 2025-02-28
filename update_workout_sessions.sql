CREATE OR REPLACE VIEW workout_sessions AS
WITH grouped_workouts AS (
    SELECT 
        workouts.user_id,
        date_trunc('day'::text, (workouts.date)::timestamp with time zone) AS session_date,
        count(*) AS exercise_count,
        json_agg(json_build_object(
            'id', workouts.id, 
            'exercise', workouts.exercise, 
            'weight', workouts.weight, 
            'sets', workouts.sets, 
            'reps', workouts.reps, 
            'created_at', workouts.created_at, 
            'date', workouts.date
        ) ORDER BY workouts.date DESC) AS exercises
    FROM workouts
    GROUP BY workouts.user_id, (date_trunc('day'::text, (workouts.date)::timestamp with time zone))
)
SELECT 
    -- Deterministic ID generation based on user_id and session_date
    (md5(gw.user_id || gw.session_date::text))::uuid AS id,
    gw.user_id,
    p.username,
    p.full_name,
    gw.session_date AS date,
    'Gym'::text AS location,
    gw.exercise_count,
    gw.exercises,
    ((gw.exercises -> 0) ->> 'exercise'::text) AS primary_exercise
FROM 
    grouped_workouts gw
    JOIN profiles p ON (gw.user_id = p.id); 