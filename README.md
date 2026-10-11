# Rejected Treasures — Dealer Portal

Dealer photo submission and digital resale management. Dealers keep and ship their items; Rejected Treasures handles research, pricing and online listing.

## Setup
1. Install Node.js 20+; run `npm install`.
2. Copy `.env.example` to `.env.local`; enter your Supabase project URL and publishable/anon key. Never use the service role key in NEXT_PUBLIC variables.
3. Supabase database and public `item-photos` storage bucket have already been installed in the connected project. `supabase/schema.sql` is available in the downloadable source archive.
4. Run `npm run build` and `npm run dev`.
5. Deploy with Vercel; set both NEXT_PUBLIC environment variables. Configure Supabase Authentication redirect URLs.
6. Sign up as the owner, then in Supabase SQL editor: `update public.profiles set role='admin' where email='OWNER_EMAIL';`

## Before accepting dealers
Build, integration testing, RLS tests, and photo-upload recovery need verification. Public photo URLs can be accessed by anyone with the URL. No commission calculations, physical inventory, shipping, or marketplace API automations are included.
