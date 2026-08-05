-- Grant customer scopes to ADMIN role
INSERT INTO role_scopes (role_id, scope_id)
SELECT r.id, s.id FROM roles r, scopes s
WHERE r.role_name = 'ADMIN'
AND s.name IN ('VIEW_CUSTOMER','CREATE_CUSTOMER','EDIT_CUSTOMER','DELETE_CUSTOMER')
AND NOT EXISTS (
    SELECT 1 FROM role_scopes rs WHERE rs.role_id = r.id AND rs.scope_id = s.id
);
COMMIT;
EXIT;