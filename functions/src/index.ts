import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { App, ExpressReceiver } from '@slack/bolt';
import * as cors from 'cors';

// Initialize Firebase Admin
admin.initializeApp();

// Initialize CORS
const corsHandler = cors({ origin: true });

// Slack Bot Configuration
const expressReceiver = new ExpressReceiver({
  signingSecret: functions.config().slack?.signing_secret || process.env.SLACK_SIGNING_SECRET || '',
  processBeforeResponse: true,
});

const app = new App({
  token: functions.config().slack?.bot_token || process.env.SLACK_BOT_TOKEN || '',
  receiver: expressReceiver,
  processBeforeResponse: true,
});

// ============= SLACK BOT HANDLERS =============

// Handle slash command /kernel
app.command('/kernel', async ({ command, ack, respond }) => {
  await ack();
  
  const responseText = `🚀 *thex143kernelx43compatibleOS Status*\n` +
    `\n📊 *System Information:*\n` +
    `• Platform: ${command.text || 'RedSeaPortal Cloud'}\n` +
    `• Status: ✅ Online\n` +
    `• Version: 1.0.0\n` +
    `• Firebase: Connected\n` +
    `\n🔧 *Available Commands:*\n` +
    `• \`/kernel status\` - Check system status\n` +
    `• \`/kernel deploy\` - Deploy updates\n` +
    `• \`/kernel logs\` - View system logs\n` +
    `• \`/kernel help\` - Show this help message`;

  await respond({
    response_type: 'ephemeral',
    text: responseText,
  });
});

// Handle app mentions
app.event('app_mention', async ({ event, client }) => {
  try {
    const result = await client.chat.postMessage({
      channel: event.channel,
      text: `Hello <@${event.user}>! I'm thex143kernelx43compatibleOS bot. How can I help you today?`,
      thread_ts: event.ts,
    });
    console.log('Message sent:', result);
  } catch (error) {
    console.error('Error posting message:', error);
  }
});

// Handle messages
app.message('hello', async ({ message, say }) => {
  if ('user' in message) {
    await say(`Hey there <@${message.user}>! Welcome to thex143kernelx43compatibleOS 🚀`);
  }
});

// Handle home tab
app.event('app_home_opened', async ({ event, client }) => {
  try {
    await client.views.publish({
      user_id: event.user,
      view: {
        type: 'home',
        blocks: [
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: '*Welcome to thex143kernelx43compatibleOS! 🚀*',
            },
          },
          {
            type: 'divider',
          },
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: '📊 *System Status*\n' +
                '• Firebase: ✅ Connected\n' +
                '• Database: ✅ Online\n' +
                '• Functions: ✅ Deployed\n' +
                '• Hosting: ✅ Active',
            },
          },
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: '🔧 *Quick Actions*',
            },
          },
          {
            type: 'actions',
            elements: [
              {
                type: 'button',
                text: {
                  type: 'plain_text',
                  text: '📊 View Dashboard',
                },
                url: 'https://redseaportal.com',
                action_id: 'view_dashboard',
              },
              {
                type: 'button',
                text: {
                  type: 'plain_text',
                  text: '📝 View Logs',
                },
                action_id: 'view_logs',
              },
              {
                type: 'button',
                text: {
                  type: 'plain_text',
                  text: '🚀 Deploy Update',
                },
                action_id: 'deploy_update',
                style: 'primary',
              },
            ],
          },
        ],
      },
    });
  } catch (error) {
    console.error('Error publishing home tab:', error);
  }
});

// ============= HTTP FUNCTIONS =============

// Slack Bot endpoint
export const slackBot = functions.https.onRequest(expressReceiver.app);

// API Status endpoint
export const api = functions.https.onRequest((req, res) => {
  corsHandler(req, res, () => {
    if (req.path === '/status') {
      res.json({
        status: 'online',
        service: 'thex143kernelx43compatibleOS',
        platform: 'RedSeaPortal',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        endpoints: {
          slack: '/slack',
          api: '/api',
          webhook: '/webhook',
        },
      });
    } else if (req.path === '/health') {
      res.json({ status: 'healthy' });
    } else {
      res.status(404).json({ error: 'Endpoint not found' });
    }
  });
});

// Webhook endpoint for external integrations
export const webhook = functions.https.onRequest((req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    try {
      const { event, data } = req.body;
      
      // Log webhook event
      await admin.firestore().collection('webhooks').add({
        event,
        data,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        source: req.headers['x-forwarded-for'] || req.ip,
      });

      res.json({ 
        success: true, 
        message: 'Webhook received',
        event,
      });
    } catch (error) {
      console.error('Webhook error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });
});

// OAuth redirect for Slack installation
export const oauth = functions.https.onRequest((req, res) => {
  corsHandler(req, res, () => {
    const clientId = functions.config().slack?.client_id || process.env.SLACK_CLIENT_ID;
    const scopes = 'commands,chat:write,app_mentions:read,im:history,channels:history,groups:history';
    
    if (req.path === '/slack/oauth') {
      const redirectUri = `https://slack.com/oauth/v2/authorize?client_id=${clientId}&scope=${scopes}&redirect_uri=https://us-central1-redseaportal.cloudfunctions.net/oauth/callback`;
      res.redirect(redirectUri);
    } else if (req.path === '/oauth/callback') {
      // Handle OAuth callback
      res.send(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>thex143kernelx43compatibleOS - Slack Connected</title>
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
              display: flex;
              align-items: center;
              justify-content: center;
              min-height: 100vh;
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              margin: 0;
            }
            .container {
              background: white;
              padding: 3rem;
              border-radius: 10px;
              box-shadow: 0 20px 40px rgba(0,0,0,0.1);
              text-align: center;
              max-width: 400px;
            }
            h1 { color: #4A154B; }
            .success { color: #00C851; font-size: 3rem; }
            .btn {
              display: inline-block;
              margin-top: 2rem;
              padding: 12px 24px;
              background: #4A154B;
              color: white;
              text-decoration: none;
              border-radius: 5px;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="success">✓</div>
            <h1>Successfully Connected!</h1>
            <p>thex143kernelx43compatibleOS has been added to your Slack workspace.</p>
            <a href="https://redseaportal.com" class="btn">Go to Dashboard</a>
          </div>
        </body>
        </html>
      `);
    } else {
      res.status(404).send('Not found');
    }
  });
});