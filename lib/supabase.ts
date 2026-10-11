import {createBrowserClient} from '@supabase/ssr';
export function db(){return createBrowserClient(process.env.NEXT_PUBLIC_SUPABASE_URL!,process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!)}
export const statuses=['submitted','researched','priced','approved','listed','sold','needs_info','returned'] as const;
export type Status=typeof statuses[number];
export type Item={id:string;dealer_id:string;title:string;category:string|null;brand:string|null;condition:string|null;dimensions:string|null;notes:string|null;price_hint:number|null;status:Status;research_notes:string|null;suggested_price:number|null;listing_url:string|null;sold_price:number|null;created_at:string;updated_at:string;item_photos:{id:string;storage_path:string}[];profiles?:{email:string}|null};
export const photoUrl=(path:string)=>db().storage.from('item-photos').getPublicUrl(path).data.publicUrl;
