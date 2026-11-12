module.exports = (req, res) => {
  if (req.method === "GET") {
    const query = req.query || {};
    const params = new URL(req.url, "https://voltrix-coral.vercel.app").searchParams;

    const getValue = (key) => {
      const value = query[key] ?? params.get(key);
      return Array.isArray(value) ? value[0] : value;
    };

    const mode = getValue("hub.mode");
    const token = getValue("hub.verify_token");
    const challenge = getValue("hub.challenge");
    const expectedToken = process.env.WHATSAPP_VERIFY_TOKEN;

    if (!expectedToken) {
      console.error("WhatsApp webhook verification failed: WHATSAPP_VERIFY_TOKEN is not configured.");
      return res.status(500).send("Webhook verify token is not configured");
    }

    if (mode !== "subscribe" || !token || !challenge) {
      return res.status(400).send("Missing or invalid verification parameters");
    }

    if (String(token).trim() !== String(expectedToken).trim()) {
      console.error("WhatsApp webhook verification failed: verify token mismatch.");
      return res.status(403).send("Verify token mismatch");
    }

    return res.status(200).send(String(challenge));
  }

  if (req.method === "POST") {
    // Acknowledge Meta's webhook delivery. Message processing can be added next.
    return res.status(200).send("EVENT_RECEIVED");
  }

  res.setHeader("Allow", "GET, POST");
  return res.status(405).send("Method Not Allowed");
};
