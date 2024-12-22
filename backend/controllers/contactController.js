const Contact = require('../models/user');

// Get all contacts
const getContacts = async (req, res) => {
  const { userType } = req.query; // Assume userType is passed as a query parameter

  try {
    // Fetch users based on userType if specified
    let users;
    if (userType === 'Family Member') {
      users = await User.find({ userType: 'Nurse' });
    } else if (userType === 'Nurse') {
      users = await User.find({ userType: { $in: ['Family Member', 'Nutritionist'] } });
    } else if (userType === 'Nutritionist') {
      users = await User.find({ userType: 'Nurse' });
    } else {
      users = await User.find(); // If no filter, fetch all users
    }

    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: 'Failed to get users' });
  }
};

// Add new contact
const addContact = async (req, res) => {
  const { name, subtitle } = req.body;
  
  if (!name || !subtitle) {
    return res.status(400).json({ message: 'Name and subtitle are required' });
  }

  try {
    const newContact = new Contact({
      name,
      subtitle,
    });
    await newContact.save();
    res.status(201).json(newContact);
  } catch (error) {
    res.status(500).json({ message: 'Failed to add contact' });
  }
};

// Edit contact
const editContact = async (req, res) => {
  const { id } = req.params; // Get the contact ID from the URL params
  const { name, subtitle } = req.body; // Get the new name and subtitle from the request body

  try {
    const contact = await Contact.findById(id);
    if (!contact) {
      return res.status(404).json({ message: 'Contact not found' });
    }

    // Update fields
    contact.name = name || contact.name;
    contact.subtitle = subtitle || contact.subtitle;
    await contact.save(); // Save the updated contact

    res.status(200).json(contact); // Return the updated contact
  } catch (error) {
    console.error('Failed to update contact:', error);
    res.status(500).json({ message: 'Failed to edit contact' });
  }
};


// Delete contact
const deleteContact = async (req, res) => {
  const { id } = req.params; // Get the contact ID from the URL params

  try {
    const contact = await Contact.findByIdAndDelete(id); // Find and delete the contact
    if (!contact) {
      return res.status(404).json({ message: 'Contact not found' });
    }

    res.status(204).send(); // Successfully deleted
  } catch (error) {
    console.error('Failed to delete contact:', error);
    res.status(500).json({ message: 'Failed to delete contact' });
  }
};


module.exports = {
  getContacts,
  addContact,
  editContact,
  deleteContact,
};
