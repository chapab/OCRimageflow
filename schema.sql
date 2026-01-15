-- OCRimageflow Database Schema

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

-- Usage logs table
CREATE TABLE IF NOT EXISTS usage_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    details JSONB,
    images_processed INTEGER DEFAULT 0,
    cost DECIMAL(10, 4) DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_tier ON users(tier);
CREATE INDEX IF NOT EXISTS idx_usage_logs_user_id ON usage_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_usage_logs_action ON usage_logs(action);
CREATE INDEX IF NOT EXISTS idx_usage_logs_created_at ON usage_logs(created_at);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to reset monthly image counter (run this monthly via cron)
CREATE OR REPLACE FUNCTION reset_monthly_images()
RETURNS void AS $$
BEGIN
    UPDATE users SET images_processed_this_month = 0;
END;
$$ language 'plpgsql';

-- View for user statistics
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    u.id,
    u.email,
    u.name,
    u.tier,
    u.images_processed_this_month,
    COUNT(ul.id) as total_batches,
    COALESCE(SUM(ul.images_processed), 0) as total_images_all_time,
    COALESCE(SUM(ul.cost), 0) as total_cost,
    u.created_at as member_since
FROM users u
LEFT JOIN usage_logs ul ON u.id = ul.user_id AND ul.action = 'batch_processed'
GROUP BY u.id, u.email, u.name, u.tier, u.images_processed_this_month, u.created_at;
