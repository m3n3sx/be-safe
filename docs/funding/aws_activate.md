# AWS Activate Founders — Application Draft

**Program**: AWS Activate Founders (no investor required tier)
**Credits**: $1,000 USD AWS credits + Business Support (1 year) + technical resources
**URL**: https://aws.amazon.com/activate/founders/
**Decision time**: ~7 days
**Equity**: 0%

**Upgrade path**: After 12 months with usage, can apply for AWS Activate Portfolio ($25k–$100k credits) via accelerator/VC referral.

---

## Form fields and answers

### Company Information

**Company name**: be:Safe

**Company website**: https://besafe.org.pl

**Country**: Poland

**State/Province**: Wielkopolska

**Company description (50 words max)**:
> be:Safe is a Polish family safety mobile app that combines hyperlocal danger alerts, real-time family tracking, daily senior check-ins, AED locator, escort mode, and a verified emergency response network. Built for parents, seniors, and children, it addresses a gap unfilled by Life360 (no Polish), Yanosik (drivers only), or Family Link (parental control only).

**Founded**: 2026

**Stage of company**:
- ☑ Idea/Pre-Seed
- ☐ Seed
- ☐ Series A+

**Number of employees**: 1

**Is your business funded by an AWS-affiliated investor, accelerator, or incubator?**:
- ☐ Yes
- ☑ No (Founders tier)

---

### About the Founder/Applicant

**Full name**: [Your name]

**Job title**: Founder & CEO

**Email**: [your email]

**LinkedIn URL**: [your LinkedIn]

**Are you the technical founder?**: Yes

---

### Product & Technology

**Product description (150 words)**:
> be:Safe is a community-driven family safety platform deployed at besafe.org.pl, currently in beta on Android (iOS planned Q1 2027). The app provides:
>
> 1. **Real-time hyperlocal alerts** across 18 categories (aggression, theft, fire, weather, accidents, etc.) with PostGIS-powered geofencing and FCM push notifications
> 2. **Family safety tools**: location sharing, geofences, safe routes with deviation alerts, daily senior check-ins, panic gestures, fake call, escort mode with auto-alarm
> 3. **Civic safety integrations**: 16,600 AEDs synchronized from OpenStreetMap, 289 air quality stations from Polish government API, mental health hotlines
> 4. **Three adaptive UI modes**: kids (ages 7-12), seniors (60+), and standard, each with dedicated layouts for accessibility
> 5. **Verified responders network**: KPP-certified first responders (Kwalifikowana Pierwsza Pomoc) receive SOS alerts within 2km radius
>
> 60+ features shipped in v61. Open-source design system "Serenity Guard". GDPR-compliant audio recording with explicit consent.

**Technology stack**:
- Frontend Mobile: Flutter 3.29 (Dart)
- Frontend Web: Next.js 16 + React 19 + TypeScript + Tailwind 4
- Backend: Node.js + Express + Socket.io
- Database: PostgreSQL 16 + PostGIS (geospatial)
- Push: Firebase Cloud Messaging
- Maps: Google Maps Flutter SDK
- Authentication: JWT + Google Sign-In
- Infrastructure: AWS EC2 t3.xlarge (currently — would benefit from credits!)
- Other: Sentry, Geolocator, local_auth (biometrics)

**Are you a B2B, B2C, or B2B2C company?**: B2C with B2B partnerships planned (insurers, municipalities, OSP volunteer fire departments)

**Industry**: Civic Tech / Family Safety / Health & Wellness / Public Safety

---

### AWS Usage

**Are you currently using AWS?**: Yes

**What AWS services are you using?**:
- EC2 (t3.xlarge — production server)
- Route 53 (planned)
- SES (planned — for email verification)
- S3 (planned — for user avatars, audio recordings)
- CloudWatch (planned)
- RDS (considering migration from self-managed PostgreSQL)

**Monthly AWS spend**: ~$60/month currently

**How will you use AWS credits?**:
> 1. **Migrate PostgreSQL to RDS** with automated backups and read replicas for the geospatial query load
> 2. **S3 + CloudFront** for user-generated content (alert photos, avatars, SOS audio recordings)
> 3. **SES** for transactional email (verification, password reset, weekly digests)
> 4. **CloudWatch + X-Ray** for production monitoring and tracing
> 5. **Lambda** for cron jobs currently running on EC2 (AED sync, AQI sync, geofence checks, escort panic detection)
> 6. **API Gateway + WAF** to protect public endpoints from abuse
> 7. **Rekognition** (planned F06) for AI-powered image moderation of user-submitted alert photos
> 8. **Comprehend** (planned) for upgraded text moderation (currently heuristic-based)

---

### Problem & Market

**What problem are you solving?**:
> 38 million Poles lack a unified safety platform. Existing options are fragmented:
> - **Life360** has no Polish localization, no integration with PL emergency services, and dominates the US market only
> - **Yanosik** focuses exclusively on road incidents for drivers
> - **Family Link** is parental control, not family safety
> - **RCB Alert** is one-way government broadcasts, no community input
> - **mObywatel** is administrative, not real-time safety
>
> Specifically underserved:
> - **Seniors (10.8M in PL)** — no app combines large UI, daily check-ins, and family alerting
> - **Ukrainian refugees (1.5M)** — need safety navigation in unfamiliar cities, no localized solution exists
> - **Parents of school-age kids** — need geofence + safe route + emergency comms in one place
> - **Cardiac event bystanders** — need AED locator with real-time directions (cardiac arrest survival drops 10% per minute without defibrillation)

**Market size**:
- TAM: Poland 38M people × 30% smartphone safety-app penetration potential = ~11M users
- SAM: 6.5M households with children + 4.5M seniors = ~11M family unit targets
- SOM Year 1: 50,000 MAU realistic with €100k marketing budget

**Business model**:
- **Freemium B2C**: free core safety, premium tier €4.99/month (advanced analytics, unlimited geofences, priority responder network)
- **B2B partnerships**:
  - Insurance bundles (PZU, Warta, Allianz) — €1-2 PEPM
  - Municipality contracts (gmina-level safety dashboards) — €5k-50k/year per contract
  - Senior care facilities — group licenses

---

### Traction

**Current metrics**:
- 60+ features shipped in production (v61 deployed May 2026)
- 4 user personas with full E2E test coverage (Patrol framework, 25 metrics tracked)
- 16,600 AEDs synchronized from OSM/Overpass
- 289 air quality stations monitored from Polish GIOŚ government API
- Beta APK available at https://besafe.org.pl/download
- Web companion app deployed at https://besafe.org.pl

**Milestones next 12 months**:
- Q1 2027: iOS launch via Flutter
- Q1 2027: Ukrainian + English localization (1.5M Ukrainian refugees in PL)
- Q2 2027: First municipal pilot (Wrzesnia / Wielkopolska region)
- Q2 2027: 10,000 MAU target
- Q3 2027: Series Pre-Seed or PARP SMART grant application (€500k)
- Q4 2027: 50,000 MAU + first B2B insurer contract

---

### Why AWS?

> AWS is our infrastructure foundation. We've been on EC2 since day one. As we scale to 50k+ users with PostGIS geospatial queries, real-time WebSocket connections, FCM push fan-out, daily cron jobs (AED sync, AQI sync, escort panic detection, senior check-in reminders), and planned AI features (Rekognition for alert photo moderation, Comprehend for text), AWS gives us the breadth no other cloud matches.
>
> The Activate credits would accelerate our migration from self-managed services on EC2 to fully-managed (RDS, Lambda, SES, CloudFront), reducing operational overhead and letting a 1-person team focus on product and growth.

---

## Submission checklist

- [ ] Form filled at https://aws.amazon.com/activate/founders/
- [ ] AWS account email matches application email
- [ ] Website besafe.org.pl loads
- [ ] LinkedIn profile complete with founder bio
- [ ] Demo video uploaded (optional but recommended) — Loom 60s showing map + SOS + family flow
- [ ] Wait 5-7 days for response email from `aws-activate@amazon.com`

## After approval

1. Credits auto-applied to AWS account within 48h
2. Free Business Support tier activated (real engineer chat 24/7)
3. Access to AWS Activate Console: training resources, technical guides
4. After 12 months: eligible to apply for Activate Portfolio tier ($25-100k) via referral

## Re-application strategy

If rejected, common reasons:
1. **Pre-product** — solved (we have production deploy)
2. **No founder LinkedIn** — fix before submitting
3. **No website** — solved (besafe.org.pl)
4. **Already used free credits** — N/A, this is first application

If rejected, wait 60 days, add traction (real users, press mention), resubmit.
