const express = require("express");
const router = express.Router();
const aiController = require("../controllers/ai");

router.post("/start", aiController.start);
router.post("/stop", aiController.stop);

module.exports = router;
