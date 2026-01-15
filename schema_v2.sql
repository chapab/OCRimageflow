-- OCRimageflow Database Schema v2.0
-- Added: Suppliers/Providers system with tier-based limits

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    tier VARCHAR(50) DEFAULT 'free' CHECK (tier IN ('free', 'starter', 'basic', 'pro', 'enterprise')),
    images_processed_this_month INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Suppliers/Providers table
CREATE TABLE IF NOT EXISTS suppliers (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    total_images_processed INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_supplier_per_user UNIQUE (user_id, name)
);

-- Batches table (tracks each processing batch)
CREATE TABLE IF NOT EXISTS batches (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    supplier_id INTEGER REFERENCES suppliers(id) ON DELETE SET NULL,
    industry_detected VARCHAR(50),
    images_count INTEGER NOT NULL,
    excel_url TEXT,
    status VARCHAR(50) DEFAULT 'completed',
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Images table (individual images with thumbnails)
CREATE TABLE IF NOT EXISTS images (
    id SERIAL PRIMARY KEY,
    batch_id INTEGER NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    supplier_id INTEGER REFERENCES suppliers(id) ON DELETE SET NULL,
    s3_url TEXT NOT NULL,
    thumbnail_url TEXT,
    filename VARCHAR(255),
    size_bytes INTEGER,
    ocr_data JSONB,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Usage logs table (updated with supplier_id)
CREATE TABLE IF NOT EXISTS usage_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    supplier_id INTEGER REFERENCES suppliers(id) ON DELETE SET NULL,
    batch_id INTEGER REFERENCES batches(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    details JSONB,
    images_processed INTEGER DEFAULT 0,
    cost DECIMAL(10, 4) DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Recovery requests table (for paid recovery of expired data)
CREATE TABLE IF NOT EXISTS recovery_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    batch_id INTEGER REFERENCES batches(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'completed', 'rejected')),
    amount_paid DECIMAL(10, 2),
    payment_method VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_tier ON users(tier);
CREATE INDEX IF NOT EXISTS idx_suppliers_user_id ON suppliers(user_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_is_active ON suppliers(is_active);
CREATE INDEX IF NOT EXISTS idx_batches_user_id ON batches(user_id);
CREATE INDEX IF NOT EXISTS idx_batches_supplier_id ON batches(supplier_id);
CREATE INDEX IF NOT EXISTS idx_batches_expires_at ON batches(expires_at);
CREATE INDEX IF NOT EXISTS idx_images_batch_id ON images(batch_id);
CREATE INDEX IF NOT EXISTS idx_images_supplier_id ON images(supplier_id);
CREATE INDEX IF NOT EXISTS idx_images_expires_at ON images(expires_at);
CREATE INDEX IF NOT EXISTS idx_usage_logs_user_id ON usage_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_usage_logs_supplier_id ON usage_logs(supplier_id);
CREATE INDEX IF NOT EXISTS idx_usage_logs_action ON usage_logs(action);
CREATE INDEX IF NOT EXISTS idx_usage_logs_created_at ON usage_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_recovery_requests_user_id ON recovery_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_recovery_requests_status ON recovery_requests(status);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_suppliers_updated_at ON suppliers;
CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate expiration date based on tier
CREATE OR REPLACE FUNCTION get_expiration_date(user_tier VARCHAR)
RETURNS TIMESTAMP AS $$
BEGIN
    RETURN CASE user_tier
        WHEN 'free' THEN CURRENT_TIMESTAMP + INTERVAL '3 days'
        WHEN 'starter' THEN CURRENT_TIMESTAMP + INTERVAL '30 days'
        WHEN 'basic' THEN CURRENT_TIMESTAMP + INTERVAL '30 days'
        WHEN 'pro' THEN CURRENT_TIMESTAMP + INTERVAL '90 days'
        WHEN 'enterprise' THEN CURRENT_TIMESTAMP + INTERVAL '90 days'
        ELSE CURRENT_TIMESTAMP + INTERVAL '3 days'
    END;
END;
$$ language 'plpgsql';

-- Function to get max suppliers allowed per tier
CREATE OR REPLACE FUNCTION get_max_suppliers(user_tier VARCHAR)
RETURNS INTEGER AS $$
BEGIN
    RETURN CASE user_tier
        WHEN 'free' THEN 1
        WHEN 'starter' THEN 3
        WHEN 'basic' THEN 3
        WHEN 'pro' THEN 5
        WHEN 'enterprise' THEN 999  -- Unlimited
        ELSE 1
    END;
END;
$$ language 'plpgsql';

-- Function to reset monthly image counter (run this monthly via cron)
CREATE OR REPLACE FUNCTION reset_monthly_images()
RETURNS void AS $$
BEGIN
    UPDATE users SET images_processed_this_month = 0;
END;
$$ language 'plpgsql';

-- Function to cleanup expired data (run daily via cron)
CREATE OR REPLACE FUNCTION cleanup_expired_data()
RETURNS void AS $$
BEGIN
    -- Delete expired images
    DELETE FROM images WHERE expires_at < CURRENT_TIMESTAMP;
    
    -- Delete expired batches that have no recovery requests
    DELETE FROM batches 
    WHERE expires_at < CURRENT_TIMESTAMP 
    AND id NOT IN (SELECT batch_id FROM recovery_requests WHERE status IN ('pending', 'approved'));
    
    -- Log cleanup
    INSERT INTO usage_logs (user_id, action, details)
    VALUES (0, 'system_cleanup', jsonb_build_object('cleaned_at', CURRENT_TIMESTAMP));
END;
$$ language 'plpgsql';

-- View for user statistics with supplier breakdown
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    u.id,
    u.email,
    u.name,
    u.tier,
    u.images_processed_this_month,
    COUNT(DISTINCT b.id) as total_batches,
    COUNT(DISTINCT s.id) as total_suppliers,
    COALESCE(SUM(ul.images_processed), 0) as total_images_all_time,
    COALESCE(SUM(ul.cost), 0) as total_cost,
    u.created_at as member_since,
    get_max_suppliers(u.tier) as max_suppliers_allowed
FROM users u
LEFT JOIN batches b ON u.id = b.user_id
LEFT JOIN suppliers s ON u.id = s.user_id AND s.is_active = true
LEFT JOIN usage_logs ul ON u.id = ul.user_id AND ul.action = 'batch_processed'
GROUP BY u.id, u.email, u.name, u.tier, u.images_processed_this_month, u.created_at;

-- View for supplier statistics
CREATE OR REPLACE VIEW supplier_stats AS
SELECT 
    s.id as supplier_id,
    s.user_id,
    s.name as supplier_name,
    s.is_active,
    COUNT(DISTINCT b.id) as total_batches,
    COUNT(DISTINCT i.id) as total_images,
    COALESCE(SUM(b.images_count), 0) as images_processed,
    MAX(b.created_at) as last_batch_date,
    s.created_at as supplier_created_at
FROM suppliers s
LEFT JOIN batches b ON s.id = b.supplier_id
LEFT JOIN images i ON s.id = i.supplier_id
GROUP BY s.id, s.user_id, s.name, s.is_active, s.created_at;
