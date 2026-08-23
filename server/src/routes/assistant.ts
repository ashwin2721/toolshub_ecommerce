import { Router } from 'express';

const router = Router();

// POST /assistant/chat
router.post('/assistant/chat', async (req, res) => {
  const { message } = req.body;
  
  if (!message || typeof message !== 'string' || message.trim().length === 0) {
    return res.status(400).json({ error: 'Message content is required' });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey === 'YOUR_GEMINI_API_KEY' || apiKey.trim() === '') {
    return res.status(400).json({ 
      error: 'Gemini API key is not configured on the server. Please add it to your server/.env file.' 
    });
  }

  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                {
                  text: `You are a professional contractor assistant. Suggest a detailed shopping list of tools and materials for the following project: '${message}'. Be specific and mention tool brands like Bosch, Makita, DeWalt, Taparia, Stanley, 3M. Keep your response formatting clean and structured in Markdown.`
                }
              ]
            }
          ]
        })
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      return res.status(response.status || 500).json({ 
        error: `Gemini API error: ${errorText}` 
      });
    }

    const data: any = await response.json();
    const reply = data.candidates?.[0]?.content?.parts?.[0]?.text || '';
    
    res.json({ reply });
  } catch (error: any) {
    console.error('Error contacting Gemini API:', error);
    res.status(500).json({ error: error.message || 'Failed to connect to Gemini API' });
  }
});

export default router;
