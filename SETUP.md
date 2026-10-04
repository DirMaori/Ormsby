# Ormsby invites: fresh install

You have 7 files. Nothing else is needed.

| File | What it is |
|---|---|
| index.html | The guest invitation (code entry, cinematic intro, invitation, RSVP) |
| admin.html | Your control panel (sign in, guests and codes, edit invitations, replies) |
| config.js | Your Supabase URL and key, plus the starting invitation wording |
| schema.sql | Sets up the database (run once in Supabase) |
| party.ics | Calendar file for the "Apple Calendar" button |
| robots.txt | Asks search engines not to list the site |
| SETUP.md | This guide |

Supabase holds the database and your login. It does not host web pages, so the files go on a free static host
(Netlify, Cloudflare Pages or Vercel). Netlify is the easiest.

## 1. Supabase (about 5 minutes)
1. Go to supabase.com, sign in, **New project**. Pick any name and a strong database password. Wait for it to finish.
2. Left menu: **SQL Editor > New query**. Paste the whole of `schema.sql`, press **Run**. You should see "Success".
3. Left menu: **Authentication > Users > Add user > Create new user**. Enter your email and a password. Tick **Auto Confirm User**.
4. **Authentication > Sign In / Providers** (or Settings): turn **off** "Allow new users to sign up". Only you can sign in.
5. **Project Settings > API**. Copy the **Project URL** and the **anon public** key.

## 2. config.js (1 minute)
Open `config.js` in any text editor. Replace `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY` with the two values you copied.
Keep the quote marks. Save. (The anon key is meant to be public. The database rules protect your data.)

## 3. Put the files online (2 minutes)
1. Go to app.netlify.com/drop.
2. Drag the whole folder (all the files, with `config.js` already edited) onto the page.
3. Netlify gives you a web address. Your guests use that address. Your admin page is that address plus `/admin.html`.

## 4. First run
1. Open `/admin.html` and sign in.
2. **Invitations** tab: check the wording, then press **Publish changes** once. This saves the wording to Supabase.
3. **Guests & codes** tab: type your guests one per line, choose which invite type, press **Generate codes**.
   Use "Whānau invite" for family. **Export codes for printing** gives a spreadsheet with each code and direct link.
4. Open your main web address, enter one of the codes, and send a test RSVP. It should appear on the Overview tab.
   Delete the test reply and test guest afterwards.

## Notes
- Changed the date or time? Invitations tab > **Download party.ics**, then upload that file over the old one on Netlify.
- Reply alerts only show while the admin page is open in a browser.
- If a code is lost or shared by mistake, use the refresh icon beside it in Guests & codes to make a new one.
- Use a new `PARTY` value in `config.js` for each future birthday so replies stay separate.
