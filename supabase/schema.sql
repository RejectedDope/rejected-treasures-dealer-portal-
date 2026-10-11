-- Rejected Treasures Dealer Portal. Install ONCE in an empty Supabase project.
create extension if not exists pgcrypto;
create table public.profiles (id uuid primary key references auth.users(id) on delete cascade,role text not null default 'dealer' check(role in ('dealer','admin')),email text not null,created_at timestamptz not null default now());
create table public.items (id uuid primary key default gen_random_uuid(),dealer_id uuid not null references public.profiles(id),title text not null check(length(trim(title))>0),category text,brand text,condition text,dimensions text,notes text,price_hint numeric(12,2) check(price_hint>=0),status text not null default 'submitted' check(status in ('submitted','researched','priced','approved','listed','sold','needs_info','returned')),research_notes text,suggested_price numeric(12,2) check(suggested_price>=0),listing_url text,sold_price numeric(12,2) check(sold_price>=0),created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table public.item_photos (id uuid primary key default gen_random_uuid(),item_id uuid not null references public.items(id) on delete cascade,storage_path text not null unique,created_at timestamptz not null default now());
create index items_dealer_created_idx on public.items(dealer_id,created_at desc);
create index items_status_idx on public.items(status);
create index item_photos_item_idx on public.item_photos(item_id);
create function public.is_admin() returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.profiles where id=(select auth.uid()) and role='admin') $$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;
create function public.new_user_profile() returns trigger language plpgsql security definer set search_path='' as $$ begin insert into public.profiles(id,email,role) values(new.id,coalesce(new.email,''),'dealer'); return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.new_user_profile();
create function public.touch_updated_at() returns trigger language plpgsql set search_path='' as $$ begin new.updated_at=now(); return new; end $$;
create trigger items_touch before update on public.items for each row execute function public.touch_updated_at();
create function public.enforce_item_edit() returns trigger language plpgsql security definer set search_path='' as $$ begin
 if public.is_admin() then return new; end if;
 if tg_op='INSERT' then
  if new.dealer_id is distinct from auth.uid() or new.status <> 'submitted' or new.research_notes is not null or new.suggested_price is not null or new.listing_url is not null or new.sold_price is not null then raise exception 'Unauthorized item submission'; end if;
 else
  if old.dealer_id is distinct from auth.uid() or old.status not in ('submitted','needs_info') or new.dealer_id is distinct from old.dealer_id or new.status is distinct from old.status or new.research_notes is distinct from old.research_notes or new.suggested_price is distinct from old.suggested_price or new.listing_url is distinct from old.listing_url or new.sold_price is distinct from old.sold_price then raise exception 'Unauthorized item edit'; end if;
 end if; return new; end $$;
create trigger items_guard before insert or update on public.items for each row execute function public.enforce_item_edit();
alter table public.profiles enable row level security;
alter table public.items enable row level security;
alter table public.item_photos enable row level security;
create policy profiles_read on public.profiles for select to authenticated using(id=(select auth.uid()) or (select public.is_admin()));
create policy items_read on public.items for select to authenticated using(dealer_id=(select auth.uid()) or (select public.is_admin()));
create policy items_insert on public.items for insert to authenticated with check(dealer_id=(select auth.uid()) or (select public.is_admin()));
create policy items_update on public.items for update to authenticated using((dealer_id=(select auth.uid()) and status in ('submitted','needs_info')) or (select public.is_admin())) with check(dealer_id=(select auth.uid()) or (select public.is_admin()));
create policy photos_read on public.item_photos for select to authenticated using(exists(select 1 from public.items i where i.id=item_id and (i.dealer_id=(select auth.uid()) or (select public.is_admin()))));
create policy photos_insert on public.item_photos for insert to authenticated with check(exists(select 1 from public.items i where i.id=item_id and ((i.dealer_id=(select auth.uid()) and i.status in ('submitted','needs_info')) or (select public.is_admin()))) and storage_path like item_id::text || '/%');
create policy photos_delete on public.item_photos for delete to authenticated using(exists(select 1 from public.items i where i.id=item_id and ((i.dealer_id=(select auth.uid()) and i.status in ('submitted','needs_info')) or (select public.is_admin()))));
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('item-photos','item-photos',true,10485760,array['image/jpeg','image/png','image/webp','image/gif']) on conflict(id) do update set public=true,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
create policy storage_photo_insert on storage.objects for insert to authenticated with check(bucket_id='item-photos' and exists(select 1 from public.items i where i.id::text=(storage.foldername(name))[1] and ((i.dealer_id=(select auth.uid()) and i.status in ('submitted','needs_info')) or (select public.is_admin()))));
create policy storage_photo_delete on storage.objects for delete to authenticated using(bucket_id='item-photos' and exists(select 1 from public.items i where i.id::text=(storage.foldername(name))[1] and ((i.dealer_id=(select auth.uid()) and i.status in ('submitted','needs_info')) or (select public.is_admin()))));
grant select on public.profiles,public.items,public.item_photos to authenticated;
grant insert,update on public.items to authenticated;
grant insert,delete on public.item_photos to authenticated;
revoke all on function public.enforce_item_edit() from public,anon,authenticated;
revoke all on function public.new_user_profile() from public,anon,authenticated;
revoke all on function public.touch_updated_at() from public,anon,authenticated;
