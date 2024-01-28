#read-only-all-db-only-postgres:
GRANT pg_read_all_data TO xxx;
#connect-postgresql:
psql -h 192.168.1.137 -p 5432 -U postgres
#create-DB:
CREATE DATABASE training;
#create-USER:
CREATE USER training_rw WITH PASSWORD 'password';
CREATE USER training_r WITH PASSWORD 'password';
#give-user-permission-read/write:
GRANT ALL PRIVILEGES ON DATABASE training TO training_rw;
#give-user-permission-read-only:
GRANT CONNECT ON DATABASE training TO training_r;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO training_r;
