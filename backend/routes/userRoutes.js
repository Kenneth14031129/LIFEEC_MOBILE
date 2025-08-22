// routes/userRoutes.js
const express = require("express");
const router = express.Router();
const userController = require("../controllers/userController");

// All routes are now public
router.post("/register", userController.registerUser);
router.post("/login", userController.loginUser);
router.get("/profile/:userId", userController.getUserProfile);
router.put("/update/:userId", userController.updateUser);
router.delete("/delete", userController.deleteUser);
router.put("/change-password/:userId", userController.changePassword);
router.get("/contacts", userController.getContactsList);
router.get("/contacts/:userId", userController.getContactDetails);
router.put("/archive/:userId", userController.archiveUser);
router.post("/verify-otp", userController.verifyOTP);
router.post("/resend-otp", userController.resendOTP);
router.put("/approve-verification/:userId", userController.approveUserVerification);
router.get("/unverified-users", userController.getUnverifiedUsers);

module.exports = router;
