-- SkillConnect Platform Database Schema
-- PostgreSQL 14+

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- ENUM TYPES
-- ============================================================

CREATE TYPE user_role AS ENUM ('customer', 'professional');

CREATE TYPE availability_status AS ENUM ('available', 'busy', 'offline');

CREATE TYPE subscription_plan AS ENUM ('basic', 'premium', 'featured');

CREATE TYPE media_type AS ENUM ('image', 'video', 'certificate');

CREATE TYPE contact_type AS ENUM ('call', 'message', 'quote_request');

CREATE TYPE contact_status AS ENUM ('pending', 'accepted', 'declined');

CREATE TYPE complaint_type AS ENUM ('fraud', 'harassment', 'poor_service', 'fake_profile');

CREATE TYPE complaint_status AS ENUM ('pending', 'warning_issued', 'suspended', 'banned', 'resolved');

CREATE TYPE provider_type AS ENUM ('individual', 'organization');

-- ============================================================
-- TABLES
-- ============================================================

-- 1. Users - Base user accounts
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    role user_role NOT NULL,
    location TEXT,
    phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
    government_id_verified BOOLEAN NOT NULL DEFAULT FALSE,
    selfie_verified BOOLEAN NOT NULL DEFAULT FALSE,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Categories - Service categories (self-referencing for hierarchy)
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    parent_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
    description TEXT,
    icon TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Professionals - Extended profile for professional users (individual or organization)
CREATE TABLE professionals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    provider_type provider_type NOT NULL DEFAULT 'individual',
    headline TEXT,
    bio TEXT,
    years_of_experience INTEGER,
    pricing_estimate TEXT,
    service_location_radius_km INTEGER,
    latitude DECIMAL(9, 6),
    longitude DECIMAL(9, 6),
    availability_status availability_status NOT NULL DEFAULT 'offline',
    reputation_score DECIMAL(3, 2) NOT NULL DEFAULT 0,
    completed_jobs INTEGER NOT NULL DEFAULT 0,
    response_time_hours DECIMAL(5, 2),
    subscription_plan subscription_plan NOT NULL DEFAULT 'basic',
    subscription_expires_at TIMESTAMPTZ,
    announcement TEXT,
    whatsapp_number VARCHAR(20),
    instagram_handle VARCHAR(100),
    website_url TEXT,
    cover_image_url TEXT,
    accent_color VARCHAR(7) DEFAULT '#6366F1',
    show_rating BOOLEAN NOT NULL DEFAULT TRUE,
    return_policy TEXT,
    operating_hours TEXT,
    operating_days TEXT,
    -- Organization-specific fields
    company_name VARCHAR(255),
    company_registration_number VARCHAR(100),
    team_size INTEGER,
    services_offered TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Professional Categories - Many-to-many relationship
CREATE TABLE professional_categories (
    professional_id UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (professional_id, category_id)
);

-- 5. Portfolio Items - Portfolio uploads for professionals
CREATE TABLE portfolio_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    professional_id UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
    title TEXT,
    description TEXT,
    media_type media_type NOT NULL,
    media_url TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Contacts - Contact requests from customers to professionals
CREATE TABLE contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    professional_id UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
    contact_type contact_type NOT NULL,
    message TEXT,
    status contact_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Reviews - Customer reviews of professionals
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    professional_id UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contact_id UUID NOT NULL UNIQUE REFERENCES contacts(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Complaints - User complaints
CREATE TABLE complaints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reported_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    complaint_type complaint_type NOT NULL,
    description TEXT NOT NULL,
    status complaint_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);

CREATE INDEX idx_professionals_user_id ON professionals(user_id);
CREATE INDEX idx_professionals_provider_type ON professionals(provider_type);
CREATE INDEX idx_professionals_reputation_score ON professionals(reputation_score DESC);
CREATE INDEX idx_professionals_location ON professionals(latitude, longitude);

CREATE INDEX idx_reviews_professional_id ON reviews(professional_id);

CREATE INDEX idx_contacts_customer_id ON contacts(customer_id);
CREATE INDEX idx_contacts_professional_id ON contacts(professional_id);

CREATE INDEX idx_complaints_reported_user_id ON complaints(reported_user_id);

CREATE INDEX idx_categories_parent_id ON categories(parent_id);
CREATE INDEX idx_portfolio_items_professional_id ON portfolio_items(professional_id);
