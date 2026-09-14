<script setup>
const effectiveDate = 'September 6, 2026'
</script>

<template>
  <div class="policy-page">
    <div class="policy-card">
      <p class="policy-logo">kisela</p>
      <h1>Child Safety Standards</h1>
      <p class="policy-updated">Effective date: {{ effectiveDate }}</p>

      <p>
        Kisela is a dating app for adults. We have zero tolerance for child sexual abuse and
        exploitation ("CSAE") of any kind, anywhere on our platform, and we are committed to
        preventing, detecting, and reporting it in line with Google Play's Child Safety Standards
        policy and applicable law.
      </p>

      <h2>Who Can Use Kisela</h2>
      <p>
        Kisela is restricted to adults aged 18 and older. Every account must declare an age of 18+
        during sign-up, and profiles are only shown to other users once that requirement is met. We
        do not knowingly permit anyone under 18 to hold an account.
      </p>

      <h2>Zero-Tolerance Policy</h2>
      <p>We prohibit, and will act immediately against, any account or content that:</p>
      <ul>
        <li>Depicts, promotes, or solicits child sexual abuse material (CSAM) in any form.</li>
        <li>Sexualizes, endangers, or attempts to exploit a minor in any way.</li>
        <li>Attempts to use Kisela to contact, groom, or arrange to meet a minor.</li>
        <li>Misrepresents a user's age to circumvent our 18+ requirement.</li>
      </ul>

      <h2>Reporting a Concern</h2>
      <p>
        If you encounter an account, message, or photo on Kisela that you believe involves CSAE,
        report it immediately to
        <a href="mailto:haflaway@gmail.com">haflaway@gmail.com</a>. Please include as much detail
        as you can (the account name, a screenshot, and a description of what you saw) so we can
        act quickly. Reports are reviewed as a top priority, and you may report anonymously.
      </p>

      <h2>Our Response</h2>
      <p>When a report or our own review identifies a CSAE violation, we will:</p>
      <ul>
        <li>Immediately remove the offending content and suspend or permanently ban the account.</li>
        <li>Preserve relevant records as required to support any resulting investigation.</li>
        <li>
          Report confirmed CSAM to the National Center for Missing &amp; Exploited Children
          (NCMEC) and cooperate with law enforcement as legally required.
        </li>
      </ul>

      <h2>Point of Contact</h2>
      <p>
        Our designated point of contact for child safety and CSAM prevention compliance is
        reachable at <a href="mailto:haflaway@gmail.com">haflaway@gmail.com</a>.
      </p>

      <h2>Changes to These Standards</h2>
      <p>
        We may update these standards from time to time to reflect changes in our practices or
        applicable policy. We will update the "Effective date" above when we do.
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
