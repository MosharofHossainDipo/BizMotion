INSERT INTO users (username, email, password_hash, role_id)
SELECT 'super_admin', 'admin@bizmotion.com',
       '$2a$12$tQCeHWFWTQOKYXgCXmLXeO7YX8vQZk3pGpJjX4qGxU5m1NrFdK7Wy',
       id FROM roles WHERE role_name = 'SUPER_ADMIN';
COMMIT;
