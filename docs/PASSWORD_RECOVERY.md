# Password recovery

Run `php artisan migrate` to add password_reset_tokens; do not use migrate:fresh on real data.
Configure a working SMTP transport in backend/.env: MAIL_MAILER=smtp, MAIL_HOST,
MAIL_PORT, MAIL_USERNAME, MAIL_PASSWORD, MAIL_FROM_ADDRESS and MAIL_FROM_NAME.
APP_URL must be the externally reachable backend URL used in recovery emails.
Use HTTPS in production. Local HTTP testing can set SESSION_SECURE_COOKIE=false;
production keeps secure cookies. Keep APP_KEY unchanged.

POST /api/auth/forgot-password returns the same response for registered/unknown
accounts and rate-limited resends. A transport failure returns 503, never a fake
successful email delivery. The email opens the backend reset form, so a Flutter
web deployment or mobile deep link is not required. Tokens expire after 15 minutes,
are stored hashed, and are single-use. Reset revokes all existing API sessions.
The new password must contain at least 12 characters and match confirmation.

POST /api/auth/reset-password also supports API clients with email, token,
password and password_confirmation. The web form uses CSRF and file-backed
sessions; it must be served by the same backend origin. No real email has been
sent as part of automated tests; tests fake notifications and verify the broker.
