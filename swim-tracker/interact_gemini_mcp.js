const { execSync } = require('child_process');

// Wait for mcp to authenticate and then query
try {
  console.log('Running gemini auth...')
  const out1 = execSync('gemini mcp auth supabase', { encoding: 'utf-8'} );
  console.log(out1);
  
  console.log('Running gemini db command...')
  const out2 = execSync(`gemini "Use the supabase mcp tool to run this exact query on the database: ALTER TABLE public.practices ADD COLUMN IF NOT EXISTS goal_id UUID REFERENCES public.training_goals(id) ON DELETE CASCADE; ALTER TABLE public.training_sets ADD COLUMN IF NOT EXISTS goal_id UUID REFERENCES public.training_goals(id) ON DELETE CASCADE; CREATE INDEX IF NOT EXISTS idx_practices_goal_id ON public.practices(goal_id); CREATE INDEX IF NOT EXISTS idx_training_sets_goal_id ON public.training_sets(goal_id);" --yolo --prompt`, { encoding: 'utf-8' });
  console.log(out2);

} catch(e) {
  console.error("Failed:", e.message);
  if (e.stdout) console.error("Out:", e.stdout);
  if (e.stderr) console.error("Err:", e.stderr);
}
