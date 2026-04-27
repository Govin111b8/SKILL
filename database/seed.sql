-- SkillConnect Platform Seed Data
-- Service Categories

-- ============================================================
-- TOP-LEVEL CATEGORIES
-- ============================================================

INSERT INTO categories (name, parent_id, description, icon) VALUES
('Home Services', NULL, 'Services related to home maintenance, repair, and improvement', 'home'),
('Event Services', NULL, 'Services for planning and executing events', 'event'),
('Personal Services', NULL, 'Personal care and lifestyle services', 'person'),
('Technical Services', NULL, 'Technology and technical support services', 'technical'),
('Creative Services', NULL, 'Creative, design, and artistic services', 'creative');

-- ============================================================
-- SUB-CATEGORIES: Home Services
-- ============================================================

INSERT INTO categories (name, parent_id, description, icon) VALUES
('Plumbing', (SELECT id FROM categories WHERE name = 'Home Services'), 'Pipe repair, installation, and maintenance', 'plumbing'),
('Electrical', (SELECT id FROM categories WHERE name = 'Home Services'), 'Electrical wiring, repair, and installation', 'electrical'),
('Carpentry', (SELECT id FROM categories WHERE name = 'Home Services'), 'Woodwork, furniture repair, and custom builds', 'carpentry'),
('Painting', (SELECT id FROM categories WHERE name = 'Home Services'), 'Interior and exterior painting services', 'painting'),
('Cleaning', (SELECT id FROM categories WHERE name = 'Home Services'), 'Home and office cleaning services', 'cleaning'),
('Landscaping', (SELECT id FROM categories WHERE name = 'Home Services'), 'Garden maintenance, lawn care, and design', 'landscaping'),
('Pest Control', (SELECT id FROM categories WHERE name = 'Home Services'), 'Pest removal and prevention services', 'pest_control'),
('HVAC', (SELECT id FROM categories WHERE name = 'Home Services'), 'Heating, ventilation, and air conditioning', 'hvac'),
('Roofing', (SELECT id FROM categories WHERE name = 'Home Services'), 'Roof repair, replacement, and maintenance', 'roofing'),
('Appliance Repair', (SELECT id FROM categories WHERE name = 'Home Services'), 'Repair of home appliances', 'appliance');

-- ============================================================
-- SUB-CATEGORIES: Event Services
-- ============================================================

INSERT INTO categories (name, parent_id, description, icon) VALUES
('Catering', (SELECT id FROM categories WHERE name = 'Event Services'), 'Food and beverage catering for events', 'catering'),
('Photography', (SELECT id FROM categories WHERE name = 'Event Services'), 'Event and portrait photography', 'photography'),
('Videography', (SELECT id FROM categories WHERE name = 'Event Services'), 'Video recording and production for events', 'videography'),
('DJ & Music', (SELECT id FROM categories WHERE name = 'Event Services'), 'Music entertainment and DJ services', 'music'),
('Event Planning', (SELECT id FROM categories WHERE name = 'Event Services'), 'Full event coordination and planning', 'event_planning'),
('Decoration', (SELECT id FROM categories WHERE name = 'Event Services'), 'Event decoration and styling', 'decoration'),
('MC & Hosting', (SELECT id FROM categories WHERE name = 'Event Services'), 'Master of ceremonies and event hosting', 'mc'),
('Venue Rental', (SELECT id FROM categories WHERE name = 'Event Services'), 'Venue sourcing and rental coordination', 'venue');

-- ============================================================
-- SUB-CATEGORIES: Personal Services
-- ============================================================

INSERT INTO categories (name, parent_id, description, icon) VALUES
('Tutoring', (SELECT id FROM categories WHERE name = 'Personal Services'), 'Academic tutoring and coaching', 'tutoring'),
('Fitness Training', (SELECT id FROM categories WHERE name = 'Personal Services'), 'Personal fitness and workout training', 'fitness'),
('Beauty & Makeup', (SELECT id FROM categories WHERE name = 'Personal Services'), 'Beauty treatments and makeup application', 'beauty'),
('Hair Styling', (SELECT id FROM categories WHERE name = 'Personal Services'), 'Haircuts, styling, and treatments', 'hair'),
('Massage Therapy', (SELECT id FROM categories WHERE name = 'Personal Services'), 'Therapeutic and relaxation massage', 'massage'),
('Nutrition & Diet', (SELECT id FROM categories WHERE name = 'Personal Services'), 'Nutrition planning and dietary advice', 'nutrition'),
('Life Coaching', (SELECT id FROM categories WHERE name = 'Personal Services'), 'Personal development and life coaching', 'coaching'),
('Pet Care', (SELECT id FROM categories WHERE name = 'Personal Services'), 'Pet sitting, grooming, and walking', 'pet_care');

-- ============================================================
-- SUB-CATEGORIES: Technical Services
-- ============================================================

INSERT INTO categories (name, parent_id, description, icon) VALUES
('IT Support', (SELECT id FROM categories WHERE name = 'Technical Services'), 'Computer and network troubleshooting', 'it_support'),
('Web Development', (SELECT id FROM categories WHERE name = 'Technical Services'), 'Website design and development', 'web_dev'),
('Mobile App Development', (SELECT id FROM categories WHERE name = 'Technical Services'), 'iOS and Android app development', 'mobile_dev'),
('Data Recovery', (SELECT id FROM categories WHERE name = 'Technical Services'), 'Data recovery and backup services', 'data_recovery'),
('CCTV & Security', (SELECT id FROM categories WHERE name = 'Technical Services'), 'Security camera installation and setup', 'security'),
('Phone Repair', (SELECT id FROM categories WHERE name = 'Technical Services'), 'Smartphone and tablet repair', 'phone_repair'),
('Networking', (SELECT id FROM categories WHERE name = 'Technical Services'), 'Network setup and configuration', 'networking'),
('Software Training', (SELECT id FROM categories WHERE name = 'Technical Services'), 'Software usage training and workshops', 'training');

-- ============================================================
-- SUB-CATEGORIES: Creative Services
-- ============================================================

INSERT INTO categories (name, parent_id, description, icon) VALUES
('Graphic Design', (SELECT id FROM categories WHERE name = 'Creative Services'), 'Logo, branding, and visual design', 'graphic_design'),
('Interior Design', (SELECT id FROM categories WHERE name = 'Creative Services'), 'Interior space planning and design', 'interior_design'),
('Content Writing', (SELECT id FROM categories WHERE name = 'Creative Services'), 'Copywriting, blogs, and content creation', 'writing'),
('Video Editing', (SELECT id FROM categories WHERE name = 'Creative Services'), 'Video post-production and editing', 'video_editing'),
('Animation', (SELECT id FROM categories WHERE name = 'Creative Services'), '2D and 3D animation services', 'animation'),
('Music Production', (SELECT id FROM categories WHERE name = 'Creative Services'), 'Music composition and production', 'music_production'),
('Voice Over', (SELECT id FROM categories WHERE name = 'Creative Services'), 'Professional voice-over recording', 'voice_over'),
('Illustration', (SELECT id FROM categories WHERE name = 'Creative Services'), 'Custom illustrations and artwork', 'illustration');
