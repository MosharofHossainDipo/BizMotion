INSERT INTO scopes (name) VALUES ('VIEW_EXPENSE');
INSERT INTO scopes (name) VALUES ('CREATE_EXPENSE');

INSERT INTO role_scopes (role_id, scope_id) SELECT r.id, s.id FROM roles r, scopes s WHERE r.role_name = 'SUPER_ADMIN' AND s.name IN ('VIEW_EXPENSE','CREATE_EXPENSE');
INSERT INTO role_scopes (role_id, scope_id) SELECT r.id, s.id FROM roles r, scopes s WHERE r.role_name = 'ACCOUNTANT' AND s.name IN ('VIEW_EXPENSE','CREATE_EXPENSE');
INSERT INTO role_scopes (role_id, scope_id) SELECT r.id, s.id FROM roles r, scopes s WHERE r.role_name = 'VIEWER' AND s.name IN ('VIEW_EXPENSE');

COMMIT;
