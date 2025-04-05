const app = require('./app');
const port = 3030;

app.listen(port, '0.0.0.0', () => {
  console.log(`Server running on http://localhost:${port}`);
});