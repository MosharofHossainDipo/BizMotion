CREATE TABLE roles (
    id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name VARCHAR2(50) NOT NULL UNIQUE
);
CREATE TABLE scopes (
    id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(50) NOT NULL UNIQUE
);
CREATE TABLE users (
    id            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username      VARCHAR2(50)  NOT NULL UNIQUE,
    email         VARCHAR2(100) NOT NULL UNIQUE,
    password_hash VARCHAR2(255) NOT NULL,
    role_id       NUMBER        NOT NULL,
    CONSTRAINT fk_user_role FOREIGN KEY (role_id) REFERENCES roles(id)
);
CREATE TABLE role_scopes (
    role_id  NUMBER NOT NULL,
    scope_id NUMBER NOT NULL,
    CONSTRAINT pk_role_scopes PRIMARY KEY (role_id, scope_id),
    CONSTRAINT fk_rs_role  FOREIGN KEY (role_id)  REFERENCES roles(id),
    CONSTRAINT fk_rs_scope FOREIGN KEY (scope_id) REFERENCES scopes(id)
);
