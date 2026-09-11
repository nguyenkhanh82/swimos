-- Create a database function that can be called to trigger the Edge Function
-- This allows you to call it from SQL, triggers, or cron jobs
-- Note: This requires the pg_net extension to be enabled

-- Enable pg_net extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Create function to trigger fetch-swimmer-times Edge Function
CREATE OR REPLACE FUNCTION trigger_fetch_swimmer_times(swimmer_id_param INTEGER)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSONB;
    response_status INTEGER;
    edge_function_url TEXT;
    service_role_key TEXT;
BEGIN
    -- Get settings (set via ALTER DATABASE or environment)
    edge_function_url := current_setting('app.settings.edge_function_url', true);
    service_role_key := current_setting('app.settings.service_role_key', true);
    
    -- Fallback to environment variables if settings not set
    IF edge_function_url IS NULL THEN
        edge_function_url := 'https://' || current_setting('app.settings.project_ref', true) || '.supabase.co/functions/v1';
    END IF;
    
    IF service_role_key IS NULL THEN
        RAISE EXCEPTION 'Service role key not configured. Set app.settings.service_role_key';
    END IF;
    
    -- Call the Supabase Edge Function via HTTP
    SELECT status, content::jsonb INTO response_status, result
    FROM http((
        'POST',
        edge_function_url || '/fetch-swimmer-times',
        ARRAY[
            http_header('Content-Type', 'application/json'),
            http_header('Authorization', 'Bearer ' || service_role_key)
        ],
        'application/json',
        json_build_object('swimmer_id', swimmer_id_param)::text
    )::http_request);
    
    -- Update tracking table
    INSERT INTO swimmers_tracking (swimmer_id, last_fetched_at, status, events_count, times_count)
    VALUES (
        swimmer_id_param,
        CURRENT_TIMESTAMP,
        CASE WHEN response_status = 200 THEN 'completed' ELSE 'error' END,
        COALESCE((result->>'events_found')::INTEGER, 0),
        COALESCE((result->>'times_found')::INTEGER, 0)
    )
    ON CONFLICT (swimmer_id) 
    DO UPDATE SET
        last_fetched_at = CURRENT_TIMESTAMP,
        status = CASE WHEN response_status = 200 THEN 'completed' ELSE 'error' END,
        events_count = COALESCE((result->>'events_found')::INTEGER, 0),
        times_count = COALESCE((result->>'times_found')::INTEGER, 0),
        error_message = CASE WHEN response_status != 200 THEN result->>'error' ELSE NULL END;
    
    RETURN result;
END;
$$;

-- Create function to trigger fetch-club-teams Edge Function
CREATE OR REPLACE FUNCTION trigger_fetch_club_teams(url_param TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSONB;
    response_status INTEGER;
    edge_function_url TEXT;
    service_role_key TEXT;
BEGIN
    -- Get settings
    edge_function_url := current_setting('app.settings.edge_function_url', true);
    service_role_key := current_setting('app.settings.service_role_key', true);
    
    IF edge_function_url IS NULL THEN
        edge_function_url := 'https://' || current_setting('app.settings.project_ref', true) || '.supabase.co/functions/v1';
    END IF;
    
    IF service_role_key IS NULL THEN
        RAISE EXCEPTION 'Service role key not configured';
    END IF;
    
    -- Call the Edge Function
    SELECT status, content::jsonb INTO response_status, result
    FROM http((
        'POST',
        edge_function_url || '/fetch-club-teams',
        ARRAY[
            http_header('Content-Type', 'application/json'),
            http_header('Authorization', 'Bearer ' || service_role_key)
        ],
        'application/json',
        json_build_object('url', url_param)::text
    )::http_request);
    
    RETURN result;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION trigger_fetch_swimmer_times(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION trigger_fetch_swimmer_times(INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION trigger_fetch_club_teams(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION trigger_fetch_club_teams(TEXT) TO service_role;

-- Example usage:
-- SELECT trigger_fetch_swimmer_times(3397927);
-- SELECT trigger_fetch_club_teams('https://www.swimcloud.com/country/usa/club/lsc/PN/teams/?ageGroup=UNOV&eventCourse=Y&gender=F&seasonId=29');
