import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { SSEClientTransport } from '@modelcontextprotocol/sdk/client/sse.js';
import { EventSource } from 'eventsource';

global.EventSource = EventSource;

async function run() {
  const url = 'https://mcp.supabase.com/mcp?project_ref=haljddborueaplgigsia';
  
  const transport = new SSEClientTransport(new URL(url), {
    requestInit: {
      headers: {
        'Authorization': `Bearer ${process.env.SUPABASE_ACCESS_TOKEN}`
      }
    }
  });

  const client = new Client({ name: 'test-client', version: '1.0.0' }, { capabilities: {} });

  try {
    await client.connect(transport);
    console.log('Connected!');
    
    // List tools
    const tools = await client.listTools();
    console.log('Available tools:', JSON.stringify(tools, null, 2));

    const result = await client.callTool({
      name: 'execute_query',
      arguments: {
        query: `
ALTER TABLE public.practices ADD COLUMN IF NOT EXISTS goal_id UUID REFERENCES public.training_goals(id) ON DELETE CASCADE;
ALTER TABLE public.training_sets ADD COLUMN IF NOT EXISTS goal_id UUID REFERENCES public.training_goals(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_practices_goal_id ON public.practices(goal_id);
CREATE INDEX IF NOT EXISTS idx_training_sets_goal_id ON public.training_sets(goal_id);
`
      }
    });

    console.log('Tools Called:', JSON.stringify(result, null, 2));

  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}

run();
