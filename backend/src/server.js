const app = require('./app');
const logger = require('./utils/logger');
require('dotenv').config();

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  logger.info(`RUPAYA Backend running on port ${PORT}`);
});
