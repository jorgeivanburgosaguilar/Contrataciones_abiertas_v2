--Este cambia el propietario de todas las tablas, en todos los schemas--

UPDATE pg_class SET relowner = (SELECT oid FROM pg_roles WHERE rolname = 'prueba_captura') 
WHERE relname IN (SELECT relname FROM pg_class, pg_namespace WHERE pg_namespace.oid = pg_class.relnamespace 
AND pg_namespace.nspname = 'public');