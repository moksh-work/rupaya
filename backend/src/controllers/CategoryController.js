const Category = require('../models/Category');
const { asyncHandler } = require('../utils/validators');

const listCategories = asyncHandler(async (req, res) => {
  const categories = await Category.listForUser(req.user.userId, req.query.type);
  res.json(categories);
});

module.exports = {
  listCategories
};
