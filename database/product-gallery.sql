alter table public.products
add column if not exists gallery_images jsonb not null default '[]'::jsonb;

create or replace function public.set_product_gallery(product_id text, new_image_urls text[])
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  current_images jsonb;
  incoming_image text;
begin
  if auth.uid() is null or not exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role in ('admin','image_editor')
  ) then
    raise exception 'Not authorized to change product images';
  end if;

  select coalesce(gallery_images, '[]'::jsonb)
    into current_images
    from public.products
    where id::text = product_id
    for update;

  if not found then
    raise exception 'Product not found';
  end if;

  if new_image_urls is null or cardinality(new_image_urls) = 0 then
    raise exception 'At least one image URL is required';
  end if;

  foreach incoming_image in array new_image_urls loop
    if incoming_image is null or incoming_image not like
      'https://zqzramrhfphvifmayycu.supabase.co/storage/v1/object/public/product-images/%' then
      raise exception 'Image URL must point to the VOLTRIX product-images bucket';
    end if;
    current_images := current_images || jsonb_build_array(incoming_image);
  end loop;

  update public.products
  set gallery_images = current_images,
      image_url = coalesce(image_url, new_image_urls[1])
  where id::text = product_id;
end;
$$;

revoke all on function public.set_product_gallery(text, text[]) from public;
grant execute on function public.set_product_gallery(text, text[]) to authenticated;
