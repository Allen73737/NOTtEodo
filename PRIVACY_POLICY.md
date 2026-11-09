# NOTtEodo Privacy Policy

_Last updated: 9 November 2026_

NOTtEodo is a personal notes, tasks, habits, money and journal app. This policy explains what the app stores, where, and what control you have. It is written to match how the app actually works.

## Without an account

Everything you write stays on your phone. It is encrypted on the device (AES-256-GCM, with the key held in the phone's secure keystore). Nothing is sent to us. Uninstalling the app deletes it; there is no copy anywhere else.

## With an account (optional)

If you sign in, your data is copied to our cloud database (Supabase) so it survives a reinstall and appears on your other devices:

- **What is stored:** your notes, tasks, habits, expenses, journal entries, wardrobe, travel plans, moodboard, shopping list and app preferences; your email address; and any photos or voice notes you add (stored with Cloudinary, in a folder only your account can use).
- **End-to-end encryption:** if you turn on an encryption passphrase in Settings → Account & sync, your items are encrypted on your phone before upload, and we cannot read them.
- **Access:** database rules ensure each account can only read and change its own rows.

## AI features

When cloud AI is on and you ask the assistant something, your question and the items it needs to answer are sent to our server and then to the AI provider (Groq) to generate the answer. They are not used to train models. You can turn cloud AI off in Settings → Assistant; the app then answers from on-device search only.

## Feedback

Feedback you send is stored with your account so we can reply and track fixes. Only you and the app's administrators can read it.

## What we do not do

- No advertising, no ad identifiers, no selling or sharing of data.
- No analytics or tracking SDKs.
- No access to your contacts, location or files, except a file or photo you choose to import.

## Permissions the app asks for

- **Notifications and exact alarms:** to deliver the reminders you set.
- **Microphone:** only while you record a voice note.
- **Biometrics:** to unlock the app, if you turn that on.
- **Internet:** for sign-in, sync and AI, only when you use them.

## Deleting your data

- **Everything in the cloud:** Settings → Account & sync → **Delete my account**. This permanently deletes your account, all synced items, uploaded photos and voice notes, and your feedback.
- **Everything on the phone:** Settings → Privacy & data → erase, or uninstall the app.
- Backups you exported yourself are files you control.

## Children

NOTtEodo is not directed at children under 13 and we do not knowingly collect their data.

## Security

Data is encrypted in transit (HTTPS only) and at rest. Report security issues as described in [SECURITY.md](SECURITY.md).

## Changes and contact

We will update this page when the app's handling of data changes, and note the date above. Questions: open an issue at the project's GitHub repository, or use Settings → Send feedback in the app.
