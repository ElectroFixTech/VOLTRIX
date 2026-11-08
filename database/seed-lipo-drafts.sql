-- VOLTRIX: add 3.7V Li-Po product drafts
-- These are intentionally hidden until real supplier prices, stock and specifications are confirmed.
INSERT INTO public.products (name, description, price, stock, category, image_url, active)
SELECT v.name, v.description, 0, 0, 'Batteries & Chargers', NULL, false
FROM (VALUES
  ('3.7V Li-Po Battery 50–100mAh Mini', 'Draft listing. Confirm exact capacity, dimensions, connector and supplier specifications before publishing.'),
  ('3.7V Li-Po Battery 100–300mAh Small', 'Draft listing. Confirm exact capacity, dimensions, connector and supplier specifications before publishing.'),
  ('3.7V Li-Po Battery 300–500mAh Compact', 'Draft listing. Confirm exact capacity, dimensions, connector and supplier specifications before publishing.'),
  ('3.7V Li-Po Battery 500–800mAh Slim', 'Draft listing. Confirm exact capacity, dimensions, connector and supplier specifications before publishing.'),
  ('3.7V Li-Po Battery 800–1200mAh Medium', 'Draft listing. Confirm exact capacity, dimensions, connector and supplier specifications before publishing.'),
  ('3.7V Li-Po Battery 1200–2000mAh Medium Plus', 'Draft listing. Confirm exact capacity, dimensions, connector and supplier specifications before publishing.'),
  ('3.7V Li-Po Battery 2000–3000mAh Large', 'Draft listing. Confirm exact capacity, dimensions, connector and supplier specifications before publishing.'),
  ('3.7V Li-Po Battery 3000–5000mAh Large Plus', 'Draft listing. Confirm exact capacity, dimensions, connector and supplier specifications before publishing.'),
  ('3.7V Li-Po Battery 5000–8000mAh High Capacity', 'Draft listing. Confirm exact capacity, dimensions, connector and supplier specifications before publishing.'),
  ('3.7V Li-Po Battery Custom Size', 'Draft listing. Confirm exact capacity, dimensions, connector and supplier specifications before publishing.')
) AS v(name, description)
WHERE NOT EXISTS (
  SELECT 1 FROM public.products p WHERE lower(p.name) = lower(v.name)
);
