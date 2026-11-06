-- VOLTRIX starter catalog
-- Reference prices are copied from publicly displayed LampaTronics listings
-- checked on 2026-11-06; they are NOT confirmed VOLTRIX selling prices.
-- Stock is initialized to 0 so no unverified inventory is advertised.
-- Product photos are left NULL until VOLTRIX-owned/licensed photos are supplied.

insert into public.products
  (name, description, price, stock, image_url, category, active)
select v.name, v.description, v.price, 0, null, v.category, true
from (values
  ('Arduino UNO R3 Without Cable', 'Arduino UNO R3 compatible development board. Reference price only; verify model and price before selling.', 350.00, 'Arduino & Development Boards'),
  ('Arduino Nano V3.0 CH340 Without Cable', 'Compact Arduino Nano V3.0 development board with CH340 USB interface.', 215.00, 'Arduino & Development Boards'),
  ('STM32F103C8T6 Blue Pill Board', 'STM32F103C8T6 development board for embedded projects.', 150.00, 'Arduino & Development Boards'),
  ('ST-LINK V2 Programmer', 'ST-LINK V2 programmer and debugger for STM8 and STM32 boards.', 140.00, 'Arduino & Development Boards'),
  ('Water Flow Sensor YF-S201', 'Water flow sensor with 1/2 inch hose connector.', 35.00, 'Sensors'),
  ('Adjustable Buck Power Module CA-1239', 'Adjustable step-down DC power supply module.', 50.00, 'Power Supply'),
  ('USB-C 18650 Charging Module', 'Compact USB Type-C charging and boost module for a single 3.7V lithium cell.', 35.00, 'Batteries & Chargers'),
  ('LED Aluminum PCB Module 3W Warm White', '3-watt warm-white LED aluminum PCB module.', 20.00, 'LED / LED Strip / IR / Fuses'),
  ('Portable 25-in-1 Screwdriver Set', 'Portable precision screwdriver kit for electronics maintenance.', 125.00, 'Tools'),
  ('USB Cable Shielded 0.3m for Arduino UNO / Mega', 'Shielded USB cable for Arduino UNO and Mega boards.', 20.00, 'Breadboards, Wires & Cables'),
  ('Terminal Block 3-Pin 5mm', 'Three-position screw terminal block with 5mm pitch.', 5.00, 'Connectors & Cable Accessories'),
  ('MAX485 TTL to RS485 Converter Module', 'TTL-to-RS485 serial communication converter module.', 60.00, 'Wireless / RF / Bluetooth'),
  ('Bluetooth Stereo Amplifier Board 5V', 'Bluetooth stereo audio module with integrated amplifier.', 70.00, 'Audio & Amplifier Modules'),
  ('8-Channel 5V Serial Control Relay Module', 'Eight-channel relay control module for low-voltage projects.', 300.00, 'Relays & Control Modules'),
  ('ICL7660 DIP-8 Voltage Converter IC', 'ICL7660 switched-capacitor voltage converter integrated circuit.', 25.00, 'ICs & Electronic Components'),
  ('Arduino Nano 3D Printed Case', '3D printed protective enclosure for Arduino Nano. Color may vary.', 25.00, '3D Printing'),
  ('Arduino UNO R3 3D Printed Snap-Fit Case', '3D printed snap-fit enclosure for Arduino UNO R3.', 60.00, '3D Printing'),
  ('Arduino Mega 3D Printed Snap-Fit Case', '3D printed snap-fit enclosure for Arduino Mega.', 100.00, '3D Printing'),
  ('Tie Wraps 150x2.5mm Black - 100 Pieces', 'Pack of 100 black cable ties, 150x2.5mm.', 20.00, 'Mechanical / Hardware'),
  ('Zip Lock Bags 15x20cm - 100 Pieces', 'Pack of 100 clear resealable storage bags, 15x20cm.', 140.00, 'Storage & Accessories'),
  ('Acti Soldering Liquid Flux 15mL', 'Liquid flux for soldering nickel and stainless steel.', 55.00, 'Soldering / Flux / Cleaning'),
  ('SMD Resistor 332K Ohm 0805 - 10 Pieces', 'Pack of 10 SMD 0805 resistors, 332K ohm.', 2.00, 'Wholesale')
) as v(name, description, price, category)
where not exists (
  select 1 from public.products p where lower(p.name) = lower(v.name)
);
