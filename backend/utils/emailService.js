// utils/emailService.js
const nodemailer = require('nodemailer');

const createEmailTemplate = (residentName, message, timestamp, emergencyContact = null) => {
  const formattedTime = new Date(timestamp || Date.now()).toLocaleString('en-US', {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone: 'Asia/Singapore'
  });

  return `
    <div style="font-family: 'Helvetica Neue', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
      <!-- Header with Logo -->
      <div style="text-align: center; margin-bottom: 30px;">
        <div style="background: linear-gradient(135deg, #dc3545 0%, #ff4d5a 100%); padding: 20px; border-radius: 10px;">
          <h1 style="color: white; margin: 0; font-size: 28px; text-transform: uppercase; letter-spacing: 2px;">
            Emergency Alert
          </h1>
        </div>
      </div>

      <!-- Alert Content -->
      <div style="background-color: #fff; border-radius: 10px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); margin-bottom: 20px; overflow: hidden;">
        <!-- Alert Header -->
        <div style="background-color: #f8d7da; padding: 20px; border-bottom: 1px solid #f5c6cb;">
          <h2 style="color: #721c24; margin: 0; font-size: 20px;">
            ⚠️ Urgent Alert for ${residentName}
          </h2>
        </div>

        <!-- Alert Body -->
        <div style="padding: 20px;">
          <div style="margin-bottom: 20px;">
            <p style="font-size: 16px; color: #555; line-height: 1.6; margin: 0 0 15px;">
              <strong style="color: #721c24;">Alert Message:</strong><br>
              ${message}
            </p>
            <p style="font-size: 14px; color: #666; margin: 0;">
              <strong>Time:</strong> ${formattedTime}
            </p>
          </div>

          ${emergencyContact ? `
          <!-- Emergency Contact Information -->
          <div style="background-color: #f8f9fa; border-radius: 8px; padding: 15px; margin-top: 20px;">
            <h3 style="color: #495057; margin: 0 0 15px; font-size: 16px;">Emergency Contact Details</h3>
            <div style="font-size: 14px; color: #666;">
              <p style="margin: 5px 0;"><strong>Name:</strong> ${emergencyContact.name || 'Not provided'}</p>
              <p style="margin: 5px 0;"><strong>Phone:</strong> ${emergencyContact.phone || 'Not provided'}</p>
              <p style="margin: 5px 0;"><strong>Relation:</strong> ${emergencyContact.relation || 'Not specified'}</p>
            </div>
          </div>
          ` : ''}
        </div>
      </div>

      <!-- Action Required Notice -->
      <div style="background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; border-radius: 4px; margin-bottom: 20px;">
        <p style="color: #856404; margin: 0; font-size: 15px;">
          <strong>⚡ Immediate Action Required:</strong><br>
          Please check the LIFEEC application for complete details and required actions.
        </p>
      </div>

      <!-- Footer -->
      <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
        <p style="color: #666; font-size: 12px; margin: 0;">
          This is an automated emergency alert from LIFEEC Alert System.<br>
          Please do not reply to this email.
        </p>
        <div style="margin-top: 15px;">
          <p style="color: #999; font-size: 11px; margin: 0;">
            &copy; ${new Date().getFullYear()} LIFEEC. All rights reserved.
          </p>
        </div>
      </div>
    </div>
  `;
};

// Create reusable transporter with better error handling and configuration
const createTransporter = async () => {
  // Production transporter
  const prodTransporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
    tls: {
      rejectUnauthorized: false
    },
    connectionTimeout: 10000,
    pool: true,
    maxConnections: 3,
    maxMessages: 100,
    rateDelta: 1000,
    rateLimit: 5
  });

  try {
    await prodTransporter.verify();
    console.log('Email transporter verified successfully');
    return prodTransporter;
  } catch (error) {
    console.error('Email transporter verification failed:', error);
    throw error;
  }
};

// Enhanced sendOTP function with better error handling
const sendOTP = async (email, otp) => {
  try {
    const transporter = await createTransporter();
    
    const mailOptions = {
      from: {
        name: 'LIFEEC Support',
        address: process.env.EMAIL_USER
      },
      to: email,
      subject: 'LIFEEC - Email Verification OTP',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #2196f3;">LIFEEC Email Verification</h2>
          <p>Your verification code is:</p>
          <h1 style="color: #1976d2; font-size: 36px; letter-spacing: 5px;">${otp}</h1>
          <p>This code will expire in 10 minutes.</p>
          <p>If you didn't request this code, please ignore this email.</p>
        </div>
      `,
      headers: {
        'X-Priority': '1',
        'X-MSMail-Priority': 'High',
        'Importance': 'high'
      }
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('Email sent successfully:', info.messageId);
    return true;
  } catch (error) {
    console.error('Detailed email sending error:', {
      error: error.message,
      code: error.code,
      command: error.command,
      recipient: email
    });
    return false;
  }
};

// Enhanced emergency alert email sender with retry logic
const sendEmergencyEmail = async (recipient, residentName, message, retries = 3) => {
  const mailOptions = {
    from: {
      name: 'LIFEEC Emergency Alerts',
      address: process.env.EMAIL_USER
    },
    to: recipient,
    subject: `🚨 URGENT: Emergency Alert for ${residentName}`,
    html: createEmailTemplate(residentName, message, Date.now()),
    priority: 'high',
    headers: {
      'X-Priority': '1',
      'X-MSMail-Priority': 'High',
      'Importance': 'high'
    }
  };

  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const transporter = await createTransporter();
      const info = await transporter.sendMail(mailOptions);
      console.log(`Emergency email sent successfully to ${recipient}:`, info.messageId);
      return true;
    } catch (error) {
      console.error(`Attempt ${attempt} failed for ${recipient}:`, error);
      if (attempt === retries) {
        console.error(`All ${retries} attempts failed for ${recipient}`);
        return false;
      }
      await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
    }
  }
};

module.exports = { sendOTP, sendEmergencyEmail };