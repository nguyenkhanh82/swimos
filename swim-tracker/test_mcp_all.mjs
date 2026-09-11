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
    const tools = await client.listTools();
    console.log(JSON.stringify(tools.tools.map(t => t.name), null, 2));
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}

run();
