-- VOLTRIX: secure product-image upload setup
-- Run once in the Supabase SQL Editor.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = true,
    file_size_limit = 5242880,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'voltrix_product_images_public_read'
  ) then
    create policy voltrix_product_images_public_read
      on storage.objects for select to public
      using (bucket_id = 'product-images');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'voltrix_product_images_admin_upload'
  ) then
    create policy voltrix_product_images_admin_upload
      on storage.objects for insert to authenticated
      with check (
        bucket_id = 'product-images'
        and exists (
          select 1 from public.profiles p
          where p.id = auth.uid()
            and p.role in ('admin', 'image_editor')
        )
      );
  end if;
end
$$;

create or replace function public.set_product_image(product_id text, new_image_url text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null or not exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role in ('admin', 'image_editor')
  ) then
    raise exception 'Not authorized to change product images';
  end if;

  if new_image_url is null or new_image_url not like
    'https://zqzramrhfphvifmayycu.supabase.co/storage/v1/object/public/product-images/%' then
    raise exception 'Image URL must point to the VOLTRIX product-images bucket';
  end if;

  update public.products
  set image_url = new_image_url
  where id::text = product_id;

  if not found then
    raise exception 'Product not found';
  end if;
end;
$$;

revoke all on function public.set_product_image(text, text) from public;
grant execute on function public.set_product_image(text, text) to authenticated;
