INSERT INTO scopes (name) VALUES ('VIEW_ACCOUNT');
INSERT INTO scopes (name) VALUES ('CREATE_ACCOUNT');
INSERT INTO scopes (name) VALUES ('EDIT_ACCOUNT');
INSERT INTO scopes (name) VALUES ('DELETE_ACCOUNT');

INSERT INTO role_scopes (role_id, scope_id)
    SELECT r.id, s.id FROM roles r, scopes s
    WHERE r.role_name = 'SUPER_ADMIN'
    AND s.name IN ('VIEW_ACCOUNT','CREATE_ACCOUNT','EDIT_ACCOUNT','DELETE_ACCOUNT');

INSERT INTO role_scopes (role_id, scope_id)
    SELECT r.id, s.id FROM roles r, scopes s
    WHERE r.role_name = 'ACCOUNTANT'
    AND s.name IN ('VIEW_ACCOUNT','CREATE_ACCOUNT','EDIT_ACCOUNT');

INSERT INTO role_scopes (role_id, scope_id)
    SELECT r.id, s.id FROM roles r, scopes s
    WHERE r.role_name = 'VIEWER'
    AND s.name IN ('VIEW_ACCOUNT');
