-- Create a table to track when swimmers were last fetched
-- This helps with scheduling and avoiding duplicate fetches

CREATE TABLE IF NOT EXISTS swimmers_tracking (
    swimmer_id INTEGER PRIMARY KEY,
    last_fetched_at TIMESTAMP WITH TIME ZONE,
    events_count INTEGER DEFAULT 0,
    times_count INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending', -- pending, processing, completed, error
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_swimmers_tracking_last_fetched 
ON swimmers_tracking(last_fetched_at);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_swimmers_tracking_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_swimmers_tracking_timestamp ON swimmers_tracking;
CREATE TRIGGER update_swimmers_tracking_timestamp
BEFORE UPDATE ON swimmers_tracking
FOR EACH ROW
EXECUTE FUNCTION update_swimmers_tracking_updated_at();

-- Grant permissions (adjust as needed)
GRANT SELECT, INSERT, UPDATE ON swimmers_tracking TO authenticated;
GRANT SELECT, INSERT, UPDATE ON swimmers_tracking TO service_role;
