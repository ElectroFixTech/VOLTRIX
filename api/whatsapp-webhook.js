module.exports = (req, res) => {
  if (req.method === "GET") {
    const mode = req.query["hub.mode"];
    const token = req.query["hub.verify_token"];
    const challenge = req.query["hub.challenge"];

    if (
      mode === "subscribe" &&
      token &&
      token === process.env.WHATSAPP_VERIFY_TOKEN
    ) {
      return res.status(200).send(challenge);
    }

    return res.status(403).send("Forbidden");
  }

  if (req.method === "POST") {
    // Acknowledge Meta's webhook delivery. Message processing can be added next.
    return res.status(200).send("EVENT_RECEIVED");
  }

  res.setHeader("Allow", "GET, POST");
  return res.status(405).send("Method Not Allowed");
};
