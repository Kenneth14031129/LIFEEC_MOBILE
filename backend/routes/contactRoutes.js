const express = require('express');
const {
  getContacts,
  addContact,
  editContact,
  deleteContact,
} = require('../controllers/contactController');

const router = express.Router();

// Get all contacts
router.get('/', getContacts);

// Add a new contact
router.post('/', addContact);

// Edit a contact by ID
router.put('/:id', editContact);

// Delete a contact by ID
router.delete('/:id', deleteContact);

module.exports = router;
