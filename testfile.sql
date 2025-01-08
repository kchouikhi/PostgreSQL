DO $$
DECLARE
    table1 TEXT := 'votre_table1';  -- Remplace par le nom de ta première table
    table2 TEXT := 'votre_table2';  -- Remplace par le nom de ta deuxième table
    current_column_name TEXT;  -- Nouvelle variable pour éviter le conflit
    data_match INTEGER;
    mismatch_query TEXT;
    join_query TEXT;
    intermediate_table TEXT;
    intermediate_join TEXT;
BEGIN
    -- 📌 Étape 1 : Vérification des colonnes communes entre les deux tables
    FOR current_column_name IN 
        SELECT c.column_name
        FROM information_schema.columns c
        WHERE c.table_name = table1
        AND c.column_name IN (SELECT c2.column_name FROM information_schema.columns c2 WHERE c2.table_name = table2)
    LOOP
        -- Construction de la requête de test de cohérence des données pour chaque colonne
        mismatch_query := 'SELECT COUNT(*) FROM ' || table1 || ' t1 LEFT JOIN ' || table2 || ' t2 ON t1.' || current_column_name || ' = t2.' || current_column_name || 
                          ' WHERE t1.' || current_column_name || ' IS DISTINCT FROM t2.' || current_column_name;

        -- Exécution de la requête
        EXECUTE mismatch_query INTO data_match;

        -- Vérification du résultat de la requête
        IF data_match > 0 THEN
            -- Si incohérence de données trouvée
            RAISE NOTICE '❌ Données incohérentes pour la colonne % entre % et %.', current_column_name, table1, table2;

            -- 🔄 Recherche d'une table intermédiaire
            -- Cherche une table qui a une colonne commune avec table1 et table2
            SELECT DISTINCT it.table_name
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

            -- Si une table intermédiaire est trouvée, générer la jointure avec elle
            IF intermediate_table IS NOT NULL THEN
                -- Génération de la jointure avec la table intermédiaire
                SELECT 
                    't1.' || t1.column_name || ' = it.' || it.column_name || ' AND it.' || it.column_name || ' = t2.' || t2.column_name
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

                -- Affichage de la jointure indirecte générée
                RAISE NOTICE '🔗 Jointure indirecte possible via % :', intermediate_table;
                RAISE NOTICE 'SELECT * FROM % t1 JOIN % it ON % JOIN % t2 ON %', table1, intermediate_table, intermediate_join, table2, intermediate_join;
            ELSE
                -- Si aucune table intermédiaire n'est trouvée
                RAISE NOTICE '❌ Aucune table intermédiaire trouvée pour relier % et %.', table1, table2;
            END IF;
        ELSE
            -- Si les données sont cohérentes
            RAISE NOTICE '✅ Aucune incohérence de données trouvée pour la colonne % entre % et %.', current_column_name, table1, table2;

            -- 📋 Génération de la requête de jointure directe
            join_query := 'SELECT * FROM ' || table1 || ' t1 JOIN ' || table2 || ' t2 ON t1.' || current_column_name || ' = t2.' || current_column_name;
            RAISE NOTICE '✅ Jointure directe possible : %', join_query;
        END IF;
    END LOOP;

END $$;