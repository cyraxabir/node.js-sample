const express = require("express");

const app = express();
const PORT = process.env.PORT || 8080;

// Health / root endpoint
app.get("/", (_req, res) => {
  res.json({
    message: "Hello from DevOps Intern Task!",
    status: "running",
  });
});

// Health-check endpoint (useful for container orchestration)
app.get("/health", (_req, res) => {
  res.status(200).json({ status: "healthy" });
});

const server = app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server is running on port ${PORT}`);
});

// Graceful shutdown
const shutdown = (signal) => {
  console.log(`\n${signal} received – shutting down gracefully`);
  server.close(() => process.exit(0));
};

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));

module.exports = app; // exported for testing
