const mailjet = require("node-mailjet");

const client = mailjet.apiConnect(
  "22a0bc71b4589e0eee7501bc18b783cd",
  "2178197b69175dadf0c6d8a1229a20e4"
);

module.exports = client;
