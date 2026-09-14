<script setup>
const effectiveDate = 'September 6, 2026'
</script>

<template>
  <div class="policy-page">
    <div class="policy-card">
      <p class="policy-logo">kisela</p>
      <h1>Privacy Policy</h1>
      <p class="policy-updated">Effective date: {{ effectiveDate }}</p>

      <p>
        Kisela ("we," "us," or "our") operates the Kisela mobile app (the "App"). This Privacy
        Policy explains what information we collect, how we use it, and the choices you have. By
        creating an account or using the App, you agree to this policy.
      </p>

      <h2>Information We Collect</h2>
      <p>We collect the following information directly from you or automatically as you use the App:</p>
      <ul>
        <li><strong>Account information:</strong> the email address and password you use to sign up and log in.</li>
        <li>
          <strong>Profile information:</strong> your first name, age, gender, an optional bio, and
          an optional profile photo.
        </li>
        <li>
          <strong>Activity information:</strong> the profiles you like or pass on, your matches,
          and the messages you send to your matches within the App.
        </li>
        <li>
          <strong>Device and notification information:</strong> a device push-notification token,
          used solely to deliver notifications about matches, messages, and occasional app
          announcements to your device.
        </li>
      </ul>
      <p>
        We do not collect your precise location, and we do not use third-party advertising or
        analytics SDKs in the App.
      </p>

      <h2>How We Use Your Information</h2>
      <ul>
        <li>To create and maintain your account and profile.</li>
        <li>To show your profile to other users and let you discover other users' profiles.</li>
        <li>To detect mutual likes ("matches") and enable messaging between matched users.</li>
        <li>To send push notifications about new matches, new messages, and occasional product announcements.</li>
        <li>To maintain the security and integrity of the App.</li>
      </ul>

      <h2>How We Share Your Information</h2>
      <p>
        Your profile information (name, age, gender, bio, and photo) is visible to other Kisela
        users as part of the App's core matching functionality. Messages you send are visible only
        to you and the match you're messaging.
      </p>
      <p>
        We do not sell your personal information to third parties. We use Google Firebase
        (Authentication, Cloud Firestore, Cloud Storage, Cloud Messaging, and Cloud Functions) to
        operate the App's backend; Google processes data on our behalf under its own data
        processing and security terms and does not use it for its own purposes.
      </p>

      <h2>Data Storage and Security</h2>
      <p>
        Your data is stored on Google Firebase infrastructure and protected by access-control rules
        that restrict it to you, the app's operator, and (where applicable, such as matches and
        messages) the specific other user involved. No method of transmission or storage is
        completely secure, but we take reasonable measures to protect your information.
      </p>

      <h2>Data Retention and Deletion</h2>
      <p>
        We retain your information for as long as your account is active. You may request deletion
        of your account and associated data at any time by emailing us at the address below; we
        will delete your account, profile, and messages within a reasonable time after verifying
        your request.
      </p>

      <h2>Children's Privacy</h2>
      <p>
        Kisela is intended for users aged 18 and older. We do not knowingly collect information
        from anyone under 18. If you believe a minor has created an account, please contact us so
        we can remove it.
      </p>

      <h2>Your Choices</h2>
      <p>
        You can edit or delete your profile information from within the App at any time. You can
        disable push notifications at any time from your device's notification settings.
      </p>

      <h2>Changes to This Policy</h2>
      <p>
        We may update this Privacy Policy from time to time. We will update the "Effective date"
        above when we do. Continued use of the App after a change means you accept the updated
        policy.
      </p>

      <h2>Contact Us</h2>
      <p>
        If you have questions about this Privacy Policy or wish to request access to or deletion of
        your data, contact us at
        <a href="mailto:haflaway@gmail.com">haflaway@gmail.com</a>.
      </p>
    </div>
  </div>
</template>

<style scoped>
.policy-page {
  min-height: 100vh;
  background: var(--bg);
  padding: 48px 20px;
  display: flex;
  justify-content: center;
}

.policy-card {
  background: var(--surface);
  border-radius: 20px;
  padding: 48px;
  max-width: 720px;
  width: 100%;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06);
}

.policy-logo {
  font-size: 24px;
  font-weight: 900;
  font-style: italic;
  background: var(--gradient);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  margin: 0 0 24px 0;
}

.policy-card h1 {
  margin: 0 0 4px 0;
  font-size: 28px;
}

.policy-updated {
  color: var(--text-muted);
  font-size: 13px;
  margin: 0 0 28px 0;
}

.policy-card h2 {
  font-size: 17px;
  margin: 28px 0 10px 0;
}

.policy-card p,
.policy-card li {
  line-height: 1.6;
  color: var(--text);
  font-size: 15px;
}

.policy-card ul {
  padding-left: 20px;
  margin: 8px 0;
}

.policy-card a {
  color: var(--primary);
  font-weight: 600;
}
</style>
