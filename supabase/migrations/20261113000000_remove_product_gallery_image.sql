-- Remove one photo from a product gallery without deleting the product.
-- Run this once in Supabase Dashboard > SQL Editor.
create or replace function public.remove_product_gallery_image(
  p_product_id text,
  p_image_url text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_role text;
  remaining_urls text[];
begin
  select role into caller_role
  from public.profiles
  where id = auth.uid();

  if caller_role is null or caller_role not in ('admin', 'image_editor') then
    raise exception 'Not authorized to manage product photos';
  end if;

  select array_agg(photo_url order by photo_order)
  into remaining_urls
  from (
    select p.image_url as photo_url, 0::bigint as photo_order
    from public.products p
    where p.id::text = p_product_id
      and p.image_url is not null
      and p.image_url <> p_image_url

    union all

    select g.photo_url, g.photo_order
    from public.products p
    cross join lateral unnest(coalesce(p.gallery_images, array[]::text[]))
      with ordinality as g(photo_url, photo_order)
    where p.id::text = p_product_id
      and g.photo_url <> p_image_url
  ) photos;

  if not found then
    raise exception 'Product not found';
  end if;

  update public.products
  set image_url = remaining_urls[1],
      gallery_images = coalesce(
        remaining_urls[2:array_length(remaining_urls, 1)],
        array[]::text[]
      )
  where id::text = p_product_id;
end;
$$;

revoke all on function public.remove_product_gallery_image(text, text) from public;
grant execute on function public.remove_product_gallery_image(text, text) to authenticated;
