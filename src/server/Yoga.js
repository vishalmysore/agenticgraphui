const express = require("express");
const router = express.Router();
const axios = require("axios");
const logger = require("./utils/Logger");

// Get yoga API base URL from environment variable
// Defaults to localhost:7860 for development
// For Docker, set YOGA_API_BASE environment variable (e.g., http://yoga-service:7860)
const YOGA_API_BASE = process.env.YOGA_API_BASE || "http://localhost:7860";
logger.info(`Yoga API Base URL configured as: ${YOGA_API_BASE}`);

// Proxy endpoint to call yoga API
router.get("/graph/:query", async (req, res) => {
  try {
    const { query } = req.params;
    const yogaUrl = `${YOGA_API_BASE}/api/yoga/graph/${encodeURIComponent(query)}`;

    logger.info(`Calling yoga API: ${yogaUrl}`);

    const response = await axios.get(yogaUrl, {
      timeout: 30000, // 30 second timeout
    });

    logger.info(`Yoga API response: ${JSON.stringify(response.data)}`);
    res.json(response.data);
  } catch (error) {
    logger.error(`Error calling yoga API: ${error.message}`);
    res.status(500).json({
      error: "Failed to generate query",
      message: error.message,
    });
  }
});

module.exports = router;

