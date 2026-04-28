// Master service catalog — every service is a "mini-app" in the unified SkillConnect platform
// Each entry maps to a backend category_id and gets its own icon, gradient, and theming
import 'package:flutter/material.dart';

class ServiceDef {
  final int id;
  final String name;
  final String emoji;
  final IconData icon;
  final List<Color> gradient;
  final String tagline;
  final String parent;
  const ServiceDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.icon,
    required this.gradient,
    required this.tagline,
    required this.parent,
  });
}

class ServiceHubDef {
  final int id;
  final String name;
  final String emoji;
  final IconData icon;
  final List<Color> gradient;
  final String description;
  const ServiceHubDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.icon,
    required this.gradient,
    required this.description,
  });
}

const kServiceHubs = <ServiceHubDef>[
  ServiceHubDef(id: 1, name: 'Home Services', emoji: '🏠', icon: Icons.home_repair_service, gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)], description: 'Maintenance, repair & improvement'),
  ServiceHubDef(id: 2, name: 'Event Services', emoji: '🎉', icon: Icons.celebration, gradient: [Color(0xFFEC4899), Color(0xFFF43F5E)], description: 'Plan unforgettable celebrations'),
  ServiceHubDef(id: 3, name: 'Personal Services', emoji: '💆', icon: Icons.spa, gradient: [Color(0xFFF59E0B), Color(0xFFEF4444)], description: 'Care, fitness & lifestyle'),
  ServiceHubDef(id: 4, name: 'Technical Services', emoji: '💻', icon: Icons.computer, gradient: [Color(0xFF06B6D4), Color(0xFF3B82F6)], description: 'Tech support & development'),
  ServiceHubDef(id: 5, name: 'Creative Services', emoji: '🎨', icon: Icons.palette, gradient: [Color(0xFF8B5CF6), Color(0xFFD946EF)], description: 'Design, content & artistry'),
];

const kServices = <ServiceDef>[
  // Home Services (parent_id=1)
  ServiceDef(id: 6,  name: 'Plumbing',           emoji: '🔧', icon: Icons.plumbing,            gradient: [Color(0xFF0EA5E9), Color(0xFF06B6D4)], tagline: 'Pipes, taps, leaks & emergencies', parent: 'Home Services'),
  ServiceDef(id: 7,  name: 'Electrical',         emoji: '⚡', icon: Icons.electrical_services, gradient: [Color(0xFFF59E0B), Color(0xFFEAB308)], tagline: 'Wiring, sockets & safety',         parent: 'Home Services'),
  ServiceDef(id: 8,  name: 'Carpentry',          emoji: '🪚', icon: Icons.handyman,            gradient: [Color(0xFF92400E), Color(0xFFB45309)], tagline: 'Custom woodwork & repairs',        parent: 'Home Services'),
  ServiceDef(id: 9,  name: 'Painting',           emoji: '🎨', icon: Icons.format_paint,        gradient: [Color(0xFFEC4899), Color(0xFFA855F7)], tagline: 'Interior & exterior paint',        parent: 'Home Services'),
  ServiceDef(id: 10, name: 'Cleaning',           emoji: '🧹', icon: Icons.cleaning_services,   gradient: [Color(0xFF10B981), Color(0xFF14B8A6)], tagline: 'Deep cleaning & housekeeping',     parent: 'Home Services'),
  ServiceDef(id: 11, name: 'Landscaping',        emoji: '🌿', icon: Icons.grass,               gradient: [Color(0xFF22C55E), Color(0xFF16A34A)], tagline: 'Gardens, lawns & outdoor design',  parent: 'Home Services'),
  ServiceDef(id: 12, name: 'Pest Control',       emoji: '🐜', icon: Icons.pest_control,        gradient: [Color(0xFF7C2D12), Color(0xFFDC2626)], tagline: 'Safe & effective pest removal',    parent: 'Home Services'),
  ServiceDef(id: 13, name: 'HVAC',               emoji: '❄️', icon: Icons.ac_unit,            gradient: [Color(0xFF0284C7), Color(0xFF0EA5E9)], tagline: 'AC, heating & ventilation',        parent: 'Home Services'),
  ServiceDef(id: 14, name: 'Roofing',            emoji: '🏠', icon: Icons.roofing,             gradient: [Color(0xFF7C3AED), Color(0xFF6D28D9)], tagline: 'Roof repair & installation',       parent: 'Home Services'),
  ServiceDef(id: 15, name: 'Appliance Repair',   emoji: '🔌', icon: Icons.kitchen,             gradient: [Color(0xFF059669), Color(0xFF047857)], tagline: 'Fix fridges, washers & more',      parent: 'Home Services'),

  // Event Services (parent_id=2)
  ServiceDef(id: 16, name: 'Catering',           emoji: '🍽️', icon: Icons.restaurant,         gradient: [Color(0xFFDC2626), Color(0xFFEA580C)], tagline: 'Delicious food for any event',     parent: 'Event Services'),
  ServiceDef(id: 17, name: 'Photography',        emoji: '📸', icon: Icons.camera_alt,          gradient: [Color(0xFF8B5CF6), Color(0xFFEC4899)], tagline: 'Capture every moment',             parent: 'Event Services'),
  ServiceDef(id: 18, name: 'Videography',        emoji: '🎥', icon: Icons.videocam,            gradient: [Color(0xFFEC4899), Color(0xFFDB2777)], tagline: 'Cinematic event films',            parent: 'Event Services'),
  ServiceDef(id: 19, name: 'DJ & Music',         emoji: '🎧', icon: Icons.music_note,          gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)], tagline: 'Live DJs & sound systems',         parent: 'Event Services'),
  ServiceDef(id: 20, name: 'Event Planning',     emoji: '📋', icon: Icons.event,               gradient: [Color(0xFFF43F5E), Color(0xFFE11D48)], tagline: 'End-to-end event management',      parent: 'Event Services'),
  ServiceDef(id: 21, name: 'Decoration',         emoji: '🎀', icon: Icons.celebration,         gradient: [Color(0xFFF472B6), Color(0xFFEC4899)], tagline: 'Themed decor for any occasion',    parent: 'Event Services'),
  ServiceDef(id: 22, name: 'MC & Hosting',       emoji: '🎤', icon: Icons.mic,                 gradient: [Color(0xFF7C3AED), Color(0xFF6D28D9)], tagline: 'Engaging hosts & emcees',          parent: 'Event Services'),
  ServiceDef(id: 23, name: 'Venue Rental',       emoji: '🏛️', icon: Icons.location_city,      gradient: [Color(0xFF0F766E), Color(0xFF115E59)], tagline: 'Halls, lawns & banquet spaces',    parent: 'Event Services'),

  // Personal Services (parent_id=3)
  ServiceDef(id: 24, name: 'Tutoring',           emoji: '📚', icon: Icons.school,              gradient: [Color(0xFF3B82F6), Color(0xFF2563EB)], tagline: 'Subject experts at home',          parent: 'Personal Services'),
  ServiceDef(id: 25, name: 'Fitness Training',   emoji: '💪', icon: Icons.fitness_center,      gradient: [Color(0xFFDC2626), Color(0xFFB91C1C)], tagline: 'Personal trainers & coaches',      parent: 'Personal Services'),
  ServiceDef(id: 26, name: 'Beauty & Makeup',    emoji: '💄', icon: Icons.face_retouching_natural, gradient: [Color(0xFFEC4899), Color(0xFFF472B6)], tagline: 'Bridal & party makeup pros',   parent: 'Personal Services'),
  ServiceDef(id: 27, name: 'Hair Styling',       emoji: '💇', icon: Icons.content_cut,         gradient: [Color(0xFFA855F7), Color(0xFF9333EA)], tagline: 'Cuts, colour & treatments',        parent: 'Personal Services'),
  ServiceDef(id: 28, name: 'Massage Therapy',    emoji: '💆‍♀️', icon: Icons.spa,             gradient: [Color(0xFFEAB308), Color(0xFFCA8A04)], tagline: 'Relaxation & wellness',            parent: 'Personal Services'),
  ServiceDef(id: 29, name: 'Nutrition & Diet',   emoji: '🥗', icon: Icons.local_dining,        gradient: [Color(0xFF22C55E), Color(0xFF16A34A)], tagline: 'Personalised meal plans',          parent: 'Personal Services'),
  ServiceDef(id: 30, name: 'Life Coaching',      emoji: '🌟', icon: Icons.psychology,          gradient: [Color(0xFFF59E0B), Color(0xFFEAB308)], tagline: 'Goals, mindset & growth',          parent: 'Personal Services'),
  ServiceDef(id: 31, name: 'Pet Care',           emoji: '🐾', icon: Icons.pets,                gradient: [Color(0xFFEA580C), Color(0xFFDC2626)], tagline: 'Grooming, walking & sitting',      parent: 'Personal Services'),

  // Technical Services (parent_id=4)
  ServiceDef(id: 32, name: 'IT Support',         emoji: '🖥️', icon: Icons.support_agent,      gradient: [Color(0xFF06B6D4), Color(0xFF0891B2)], tagline: 'Computers, network & helpdesk',    parent: 'Technical Services'),
  ServiceDef(id: 33, name: 'Web Development',    emoji: '🌐', icon: Icons.web,                 gradient: [Color(0xFF3B82F6), Color(0xFF2563EB)], tagline: 'Modern websites & apps',           parent: 'Technical Services'),
  ServiceDef(id: 34, name: 'Mobile App Dev',     emoji: '📱', icon: Icons.smartphone,          gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)], tagline: 'iOS & Android apps',               parent: 'Technical Services'),
  ServiceDef(id: 35, name: 'Data Recovery',      emoji: '💾', icon: Icons.save,                gradient: [Color(0xFF0EA5E9), Color(0xFF0284C7)], tagline: 'Recover lost files & drives',      parent: 'Technical Services'),
  ServiceDef(id: 36, name: 'CCTV & Security',    emoji: '📹', icon: Icons.security,            gradient: [Color(0xFF1E40AF), Color(0xFF1E3A8A)], tagline: 'Install cameras & alarms',         parent: 'Technical Services'),
  ServiceDef(id: 37, name: 'Phone Repair',       emoji: '📲', icon: Icons.phone_android,       gradient: [Color(0xFF06B6D4), Color(0xFF0EA5E9)], tagline: 'Screen, battery & internals',      parent: 'Technical Services'),
  ServiceDef(id: 38, name: 'Networking',         emoji: '📡', icon: Icons.router,              gradient: [Color(0xFF0284C7), Color(0xFF0369A1)], tagline: 'WiFi, LAN & enterprise setup',     parent: 'Technical Services'),
  ServiceDef(id: 39, name: 'Software Training',  emoji: '🎓', icon: Icons.cast_for_education,  gradient: [Color(0xFF6366F1), Color(0xFF4F46E5)], tagline: 'Learn tools & frameworks',         parent: 'Technical Services'),

  // Creative Services (parent_id=5)
  ServiceDef(id: 40, name: 'Graphic Design',     emoji: '🖌️', icon: Icons.brush,              gradient: [Color(0xFF8B5CF6), Color(0xFFA855F7)], tagline: 'Logos, branding & print',          parent: 'Creative Services'),
  ServiceDef(id: 41, name: 'Interior Design',    emoji: '🛋️', icon: Icons.chair,              gradient: [Color(0xFFD946EF), Color(0xFFC026D3)], tagline: 'Transform your space',             parent: 'Creative Services'),
  ServiceDef(id: 42, name: 'Content Writing',    emoji: '✍️', icon: Icons.edit_note,          gradient: [Color(0xFF7C3AED), Color(0xFF6D28D9)], tagline: 'Blogs, copy & storytelling',       parent: 'Creative Services'),
  ServiceDef(id: 43, name: 'Video Editing',      emoji: '🎬', icon: Icons.movie_filter,        gradient: [Color(0xFFEC4899), Color(0xFFDB2777)], tagline: 'Reels, ads & long-form',           parent: 'Creative Services'),
  ServiceDef(id: 44, name: 'Animation',          emoji: '✨', icon: Icons.animation,           gradient: [Color(0xFFA855F7), Color(0xFF9333EA)], tagline: '2D, 3D & motion graphics',         parent: 'Creative Services'),
  ServiceDef(id: 45, name: 'Music Production',   emoji: '🎵', icon: Icons.library_music,       gradient: [Color(0xFF6366F1), Color(0xFF4F46E5)], tagline: 'Beats, mixing & mastering',        parent: 'Creative Services'),
  ServiceDef(id: 46, name: 'Voice Over',         emoji: '🎙️', icon: Icons.record_voice_over,  gradient: [Color(0xFFF59E0B), Color(0xFFD97706)], tagline: 'Ads, narration & dubbing',         parent: 'Creative Services'),
  ServiceDef(id: 47, name: 'Illustration',       emoji: '🖼️', icon: Icons.image,              gradient: [Color(0xFFEF4444), Color(0xFFDC2626)], tagline: 'Custom art & illustrations',       parent: 'Creative Services'),
];

ServiceDef? findServiceById(int id) {
  try {
    return kServices.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
}

ServiceHubDef? findHubById(int id) {
  try {
    return kServiceHubs.firstWhere((h) => h.id == id);
  } catch (_) {
    return null;
  }
}

List<ServiceDef> servicesForHub(int hubId) {
  final hub = findHubById(hubId);
  if (hub == null) return [];
  return kServices.where((s) => s.parent == hub.name).toList();
}
