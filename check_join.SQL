DO $$
DECLARE
    table1 TEXT := 'votre_table1'; -- Remplace par le nom de ta première table
    table2 TEXT := 'votre_table2'; -- Remplace par le nom de ta deuxième table
    direct_join TEXT;
    intermediate_join TEXT;
    intermediate_table TEXT;
    data_match BOOLEAN;
BEGIN
    -- 📌 Étape 1 : Vérification de la jointure directe
    SELECT STRING_AGG('t1.' || t1.column_name || ' = t2.' || t2.column_name, ' AND ')
    INTO direct_join
    FROM information_schema.columns t1
    JOIN information_schema.columns t2 
        ON t1.column_name = t2.column_name 
        AND t1.data_type = t2.data_type
    WHERE t1.table_name = table1 AND t2.table_name = table2;

    -- ✅ Jointure directe trouvée
    IF direct_join IS NOT NULL THEN
        -- Vérification de la cohérence des données
        EXECUTE 'SELECT COUNT(*) = 0 FROM ' || table1 || ' t1 JOIN ' || table2 || ' t2 ON ' || direct_join || 
                ' WHERE t1.' || (SELECT column_name FROM information_schema.columns WHERE table_name = table1 LIMIT 1) || 
                ' != t2.' || (SELECT column_name FROM information_schema.columns WHERE table_name = table2 LIMIT 1) || 
                ' LIMIT 1'
        INTO data_match;

        IF data_match THEN
            RAISE NOTICE '✅ Jointure directe possible avec des données cohérentes';
            RAISE NOTICE 'SELECT * FROM % t1 JOIN % t2 ON %', table1, table2, direct_join;
        ELSE
            -- 🔄 Étape 2 : Recherche d'une jointure via une table intermédiaire
            SELECT DISTINCT t1.table_name
            INTO intermediate_table
            FROM information_schema.columns t1
            JOIN information_schema.columns it 
                ON t1.column_name = it.column_name AND t1.data_type = it.data_type
            JOIN information_schema.columns t2 
                ON it.column_name = t2.column_name AND it.data_type = t2.data_type
            WHERE t1.table_name = table1 
              AND t2.table_name = table2
              AND it.table_name NOT IN (table1, table2)
            LIMIT 1;

            -- 🔗 Jointure indirecte trouvée
            IF intermediate_table IS NOT NULL THEN
                SELECT 
                    't1.' || t1.column_name || ' = it.' || it.column_name || ' AND it.' || it2.column_name || ' = t2.' || t2.column_name
                INTO intermediate_join
                FROM information_schema.columns t1
                JOIN information_schema.columns it 
                    ON t1.column_name = it.column_name AND t1.data_type = it.data_type
                JOIN information_schema.columns t2 
                    ON it.column_name = t2.column_name AND it.data_type = t2.data_type
                WHERE t1.table_name = table1 
                  AND it.table_name = intermediate_table 
                  AND t2.table_name = table2
                LIMIT 1;

                RAISE NOTICE '🔗 Jointure indirecte possible via % :', intermediate_table;
                RAISE NOTICE 'SELECT * FROM % t1 JOIN % it ON % JOIN % t2 ON %', table1, intermediate_table, intermediate_join, table2, intermediate_join;
            ELSE
                -- ❌ Aucune jointure trouvée
                RAISE NOTICE '❌ Aucune jointure possible trouvée entre % et %.', table1, table2;
            END IF;
        END IF;
    ELSE
        RAISE NOTICE '❌ Aucune jointure directe trouvée entre % et %.', table1, table2;
    END IF;
END $$;