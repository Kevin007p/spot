# Supabase Setup Guide

This guide walks you through setting up the Supabase backend for spot.

## Step 1: Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up (free)
2. Click **New Project**
3. Fill in:
   - **Name:** `spot`
   - **Database Password:** Choose a strong password (save it somewhere safe)
   - **Region:** Choose the closest to your users
4. Click **Create new project** and wait ~2 minutes for it to spin up

## Step 2: Get Your Credentials

1. Go to **Settings** → **API** in the Supabase Dashboard
2. Copy these two values:
   - **Project URL** (looks like `https://abcdefgh.supabase.co`)
   - **anon/public** key (starts with `eyJ...`)
3. Open `Spot/Services/SupabaseService.swift` and replace:
   ```swift
   supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
   supabaseKey: "YOUR_SUPABASE_ANON_KEY"
   ```
   with your actual values.

## Step 3: Run the Database Migration

1. In the Supabase Dashboard, go to **SQL Editor**
2. Click **New query**
3. Open the file `supabase/migrations/001_initial_schema.sql`
4. Copy the entire contents and paste into the SQL Editor
5. Click **Run**
6. You should see "Success. No rows returned" — this means the tables, policies, and functions were created

### Verify the tables were created:
- Go to **Table Editor** — you should see: `users`, `saved_places`, `place_cache`
- Go to **Authentication** → **Policies** — you should see RLS policies on each table

## Step 4: Enable Auth Providers

### Apple Sign-In
1. Go to **Authentication** → **Providers** → **Apple**
2. Toggle it **ON**
3. You'll need an Apple Developer account ($99/year) to configure:
   - **Service ID**
   - **Key ID**
   - **Team ID**
   - **Private Key**
4. Follow Supabase's [Apple auth guide](https://supabase.com/docs/guides/auth/social-login/auth-apple) for the Apple Developer Console setup

> **Note:** You can skip Apple Sign-In for now and test with Google first. The app will still build.

### Google Sign-In
1. Go to **Authentication** → **Providers** → **Google**
2. Toggle it **ON**
3. Go to [Google Cloud Console](https://console.cloud.google.com):
   - Create a new project (or use an existing one)
   - Go to **APIs & Services** → **Credentials**
   - Create an **OAuth 2.0 Client ID** (type: iOS)
   - Set the **Bundle ID** to your app's bundle identifier (e.g., `com.yourname.Spot`)
   - Create another **OAuth 2.0 Client ID** (type: Web application) for Supabase
4. Copy the **Web Client ID** and **Client Secret** into the Supabase Google provider settings
5. Copy the **iOS Client ID** — you'll need this in the Xcode project:
   - Add it to `Info.plist` as `GIDClientID`
   - Add the reversed client ID as a URL scheme

## Step 5: Set Up the Google Places Edge Function

### Get a Google Places API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Go to **APIs & Services** → **Library**
3. Enable **Places API**
4. Go to **APIs & Services** → **Credentials**
5. Click **Create Credentials** → **API Key**
6. Restrict the key:
   - **Application restrictions:** None (it's server-side)
   - **API restrictions:** Places API only
7. Copy the API key

### Deploy the Edge Function

**Option A: Via Supabase CLI (recommended)**

1. Install the Supabase CLI:
   ```bash
   npm install -g supabase
   ```
2. Login:
   ```bash
   supabase login
   ```
3. Link your project:
   ```bash
   cd /path/to/MySavedPlaces
   supabase link --project-ref YOUR_PROJECT_REF
   ```
   (Find your project ref in Dashboard → Settings → General)
4. Set the Google API key as a secret:
   ```bash
   supabase secrets set GOOGLE_PLACES_API_KEY=your_google_api_key_here
   ```
5. Deploy:
   ```bash
   supabase functions deploy google-places-proxy
   ```

**Option B: Via Dashboard**

1. Go to **Edge Functions** in the Supabase Dashboard
2. Click **Create a new function**
3. Name it `google-places-proxy`
4. Paste the contents of `supabase/functions/google-places-proxy/index.ts`
5. Go to **Settings** → **Edge Functions** → **Secrets**
6. Add: `GOOGLE_PLACES_API_KEY` = your Google API key

### Test the Edge Function
```bash
curl "https://YOUR_PROJECT_REF.supabase.co/functions/v1/google-places-proxy/autocomplete?query=pizza" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "apikey: YOUR_ANON_KEY"
```

You should get back a JSON array of place results.

## Step 6: Enable pg_cron (Optional — for account auto-purge)

1. Go to **Database** → **Extensions**
2. Search for `pg_cron` and enable it
3. Go to **SQL Editor** and run:
   ```sql
   select cron.schedule(
     'purge-deleted-accounts',
     '0 3 * * *',
     $$
       delete from auth.users
       where id in (
         select id from public.users
         where deleted_at is not null
           and deleted_at < now() - interval '30 days'
       );
     $$
   );
   ```

## Checklist

- [ ] Supabase project created
- [ ] Credentials added to `SupabaseService.swift`
- [ ] Database migration run (3 tables + RLS + functions)
- [ ] Apple auth provider configured (or skipped for now)
- [ ] Google auth provider configured
- [ ] Google Places API key obtained
- [ ] Edge function deployed with API key secret
- [ ] Edge function tested with curl
- [ ] (Optional) pg_cron enabled for account purge
