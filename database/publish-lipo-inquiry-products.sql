-- Publish VOLTRIX 3.7V Li-Po draft listings as inquiry-only products.
-- The storefront displays zero-priced products as "Price on request".
UPDATE public.products
SET active = true,
    description = '3.7V rechargeable lithium-polymer battery. Price and exact specifications on request. Contact VOLTRIX to confirm exact capacity, dimensions, connector, protection circuit and availability.'
WHERE category = 'Batteries & Chargers'
  AND name LIKE '3.7V Li-Po Battery%';
