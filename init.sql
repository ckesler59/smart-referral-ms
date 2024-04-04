CREATE DATABASE IF NOT EXISTS smartreferral;
USE smartreferral;


DROP TABLE IF EXISTS sr_organization;
CREATE TABLE sr_organization (
                                 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                                 name VARCHAR(256) NOT NULL,
                                 phone VARCHAR(20),
                                 email VARCHAR(256)
) ROW_FORMAT=COMPRESSED;
CREATE index idx_organization_name ON sr_organization(name);



DROP TABLE IF EXISTS sr_location;
CREATE TABLE sr_location (
                             id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                             organization_id INT UNSIGNED NOT NULL,
                             name VARCHAR(256) NOT NULL,
                             phone VARCHAR(20),
                             email VARCHAR(256),
                             address1 VARCHAR(256) NOT NULL,
                             address2 VARCHAR(256),
                             city VARCHAR(80) NOT NULL,
                             state VARCHAR(80) NOT NULL,
                             zip VARCHAR(20) NOT NULL,
                             country VARCHAR(80) NOT NULL,
                             time_zone VARCHAR(40)
) ROW_FORMAT=COMPRESSED;
ALTER TABLE sr_location ADD FOREIGN KEY (organization_id) REFERENCES sr_organization(id);
CREATE index idx_location_zip ON sr_location(zip);



DROP TABLE IF EXISTS sr_user;
CREATE TABLE sr_user (
                         id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                         organization_id INT UNSIGNED NOT NULL,
                         login_name VARCHAR(20) NOT NULL UNIQUE,
                         password VARBINARY(90) NOT NULL,
                         name VARCHAR(80) NOT NULL,
                         email VARCHAR(254) NOT NULL,
                         email_verified BOOLEAN NOT NULL,
                         phone VARCHAR(20),
                         phone_verified BOOLEAN NOT NULL,
                         password_expired BOOLEAN NOT NULL,
                         status_code VARCHAR(20) NOT NULL,
                         manage_users BOOLEAN,
                         manage_locations BOOLEAN,
                         manage_providers BOOLEAN,
                         manage_favorites BOOLEAN,
                         send_referrals BOOLEAN,
                         view_referrals BOOLEAN
) ROW_FORMAT=COMPRESSED;
ALTER TABLE sr_user ADD FOREIGN KEY (organization_id) REFERENCES sr_organization(id);
CREATE unique index idx_login_name ON sr_user(login_name);



DROP TABLE IF EXISTS sr_provider;
CREATE TABLE sr_provider (
                             id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                             organization_id INT UNSIGNED NOT NULL,
                             name VARCHAR(256) NOT NULL,
                             phone VARCHAR(20),
                             email VARCHAR(256)
) ROW_FORMAT=COMPRESSED;
ALTER TABLE sr_provider ADD FOREIGN KEY (organization_id) REFERENCES sr_organization(id);



DROP TABLE IF EXISTS sr_provider_location;
CREATE TABLE sr_provider_location (
                                      provider_id INT UNSIGNED NOT NULL,
                                      location_id INT UNSIGNED NOT NULL
) ROW_FORMAT=COMPRESSED;
ALTER TABLE sr_provider_location ADD FOREIGN KEY (provider_id) REFERENCES sr_provider(id);
ALTER TABLE sr_provider_location ADD FOREIGN KEY (location_id) REFERENCES sr_location(id);
CREATE unique index idx_provider_location ON sr_provider_location(provider_id, location_id);



DROP TABLE IF EXISTS sr_taxonomy_code;
CREATE TABLE sr_taxonomy_code (
                                  taxonomy_code VARCHAR(20) NOT NULL PRIMARY KEY,
                                  tx_grouping VARCHAR(128) NOT NULL,
                                  tx_classification VARCHAR(128) NOT NULL,
                                  tx_specialization VARCHAR(128),
                                  tx_name VARCHAR(128) NOT NULL,
                                  tx_section VARCHAR(40) NOT NULL
) ROW_FORMAT=COMPRESSED;
CREATE unique index idx_taxonomy ON sr_taxonomy_code(taxonomy_code);
CREATE index idx_tax_group_class ON sr_taxonomy_code(tx_grouping, tx_classification);
-- example of taxonomy codes
-- taxonomy code: 207KA0200X
-- grouping: Allopathic & Osteopathic Physicians
-- classification: Allergy & Immunology
-- specialization: Allergy
-- display name: Allergy Physician
-- section: Individual



DROP TABLE IF EXISTS sr_provider_taxonomy;
CREATE TABLE sr_provider_taxonomy (
                                      provider_id INT UNSIGNED NOT NULL,
                                      taxonomy_code VARCHAR(20) NOT NULL
) ROW_FORMAT=COMPRESSED;
ALTER TABLE sr_provider_taxonomy ADD FOREIGN KEY (provider_id) REFERENCES sr_provider(id);
ALTER TABLE sr_provider_taxonomy ADD FOREIGN KEY (taxonomy_code) REFERENCES sr_taxonomy_code(taxonomy_code);
CREATE unique index idx_taxonomy_provider ON sr_provider_taxonomy(taxonomy_code, provider_id);




DROP TABLE IF EXISTS sr_referral;
CREATE TABLE sr_referral (
                             referral_id INT UNSIGNED NOT NULL PRIMARY KEY,
                             patient_name VARCHAR(80) NOT NULL,
                             patient_phone VARCHAR(20) NOT NULL,
                             patient_email VARCHAR(256),
                             by_organization_id INT UNSIGNED NOT NULL,
                             by_location_id INT UNSIGNED,
                             by_provider_id INT UNSIGNED,
                             to_organization_id INT UNSIGNED NOT NULL,
                             to_location_id INT UNSIGNED,
                             to_provider_id INT UNSIGNED,
                             at_time DATETIME NOT NULL,
                             at_timezone VARCHAR(40) NOT NULL,
                             status VARCHAR(20) NOT NULL,
                             status_time DATETIME NOT NULL,
                             status_timezone VARCHAR(40) NOT NULL,
                             notes TEXT
) ROW_FORMAT=COMPRESSED;
ALTER TABLE sr_referral ADD FOREIGN KEY (by_organization_id) REFERENCES sr_organization(id);
ALTER TABLE sr_referral ADD FOREIGN KEY (to_organization_id) REFERENCES sr_organization(id);
ALTER TABLE sr_referral ADD FOREIGN KEY (by_location_id) REFERENCES sr_location(id);
ALTER TABLE sr_referral ADD FOREIGN KEY (to_location_id) REFERENCES sr_location(id);
ALTER TABLE sr_referral ADD FOREIGN KEY (by_provider_id) REFERENCES sr_provider(id);
ALTER TABLE sr_referral ADD FOREIGN KEY (to_provider_id) REFERENCES sr_provider(id);
CREATE index idx_referral_to ON sr_referral(to_organization_id, to_location_id, to_provider_id, at_time);
CREATE index idx_referral_by ON sr_referral(by_organization_id, by_location_id, by_provider_id, at_time);



-- create separate user accounts for use by individual microservices

CREATE USER 'sr_org_srvc'@'%' IDENTIFIED BY 'sr_org_srvc_pw';
GRANT ALL PRIVILEGES ON smartreferral.sr_organization TO 'sr_org_srvc'@'%';

CREATE USER 'sr_loc_srvc'@'%' IDENTIFIED BY 'sr_loc_srvc_pw';
GRANT ALL PRIVILEGES ON smartreferral.sr_location TO 'sr_loc_srvc'@'%';

CREATE USER 'sr_usr_srvc'@'%' IDENTIFIED BY 'sr_usr_srvc_pw';
GRANT ALL PRIVILEGES ON smartreferral.sr_user TO 'sr_usr_srvc'@'%';

CREATE USER 'sr_prv_srvc'@'%' IDENTIFIED BY 'sr_prv_srvc_pw';
GRANT ALL PRIVILEGES ON smartreferral.sr_provider TO 'sr_prv_srvc'@'%';
GRANT ALL PRIVILEGES ON smartreferral.sr_provider_location TO 'sr_prv_srvc'@'%';
GRANT ALL PRIVILEGES ON smartreferral.sr_provider_taxonomy TO 'sr_prv_srvc'@'%';
GRANT SELECT ON smartreferral.sr_taxonomy_code TO 'sr_prv_srvc'@'%';

CREATE USER 'sr_prv_search_srvc'@'%' IDENTIFIED BY 'sr_prv_search_srvc_pw';
GRANT SELECT ON smartreferral.sr_provider TO 'sr_prv_search_srvc'@'%';
GRANT SELECT ON smartreferral.sr_provider_location TO 'sr_prv_search_srvc'@'%';
GRANT SELECT ON smartreferral.sr_provider_taxonomy TO 'sr_prv_search_srvc'@'%';
GRANT SELECT ON smartreferral.sr_taxonomy_code TO 'sr_prv_search_srvc'@'%';

CREATE USER 'sr_ref_srvc'@'%' IDENTIFIED BY 'sr_ref_srvc_pw';
GRANT ALL PRIVILEGES ON smartreferral.sr_referral TO 'sr_ref_srvc'@'%';
