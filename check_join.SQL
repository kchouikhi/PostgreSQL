DO $$
DECLARE
    direct_join TEXT;
    intermediate_join TEXT;
BEGIN
    -- Vérification de la jointure directe
    SELECT STRING_AGG('t1.' || t1.column_name || ' = t2.' || t2.column_name, ' AND ')
    INTO direct_join
    FROM information_schema.columns t1
    JOIN information_schema.columns t2 
    ON t1.column_name = t2.column_name AND t1.data_type = t2.data_type
    WHERE t1.table_name = 'table1' AND t2.table_name = 'table2';

    IF direct_join IS NOT NULL THEN
        RAISE NOTICE '✅ Jointure directe possible : SELECT * FROM table1 t1 JOIN table2 t2 ON %', direct_join;
    ELSE
        -- Vérification via une table intermédiaire
        SELECT 't1.' || t1.column_name || ' = it.' || it.column_name || ' AND it.' || it2.column_name || ' = t2.' || t2.column_name
        INTO intermediate_join
        FROM information_schema.columns t1
        JOIN information_schema.columns it ON t1.column_name = it.column_name AND t1.data_type = it.data_type
        JOIN information_schema.columns t2 ON it.column_name = t2.column_name AND it.data_type = t2.data_type
        WHERE t1.table_name = 'table1' AND t2.table_name = 'table2'
        LIMIT 1;

        IF intermediate_join IS NOT NULL THEN
            RAISE NOTICE '🔗 Jointure indirecte possible : SELECT * FROM table1 t1 JOIN intermediate_table it ON % JOIN table2 t2 ON %', intermediate_join;
        ELSE
            RAISE NOTICE '❌ Aucune jointure possible trouvée.';
        END IF;
    END IF;
END $$;
