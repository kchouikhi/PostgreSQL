DO $$
DECLARE
    table1 TEXT := 'votre_table1'; -- Remplace par le nom de ta première table
    table2 TEXT := 'votre_table2'; -- Remplace par le nom de ta deuxième table
    column_name TEXT;
    data_match INTEGER;
    mismatch_query TEXT;
    result RECORD;
BEGIN
    -- 📌 Étape 1 : Vérification des colonnes communes entre les deux tables
    FOR column_name IN 
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = table1
        AND column_name IN (SELECT column_name FROM information_schema.columns WHERE table_name = table2)
    LOOP
        -- Construction de la requête de test de cohérence des données pour chaque colonne
        mismatch_query := 'SELECT COUNT(*) FROM ' || table1 || ' t1 LEFT JOIN ' || table2 || ' t2 ON t1.' || column_name || ' = t2.' || column_name || ' WHERE t1.' || column_name || ' IS DISTINCT FROM t2.' || column_name;

        -- Exécution de la requête
        EXECUTE mismatch_query INTO data_match;

        -- Vérification du résultat de la requête
        IF data_match > 0 THEN
            -- Si incohérence de données trouvée
            RAISE NOTICE '❌ Données incohérentes pour la colonne % entre % et %.', column_name, table1, table2;
        ELSE
            -- Si pas d'incohérence de données
            RAISE NOTICE '✅ Aucune incohérence de données trouvée pour la colonne % entre % et %.', column_name, table1, table2;
        END IF;
    END LOOP;

    -- 📌 Étape 2 : Si aucune incohérence, chercher la jointure indirecte
    -- Vous pouvez ajouter une logique de recherche de table intermédiaire ici si nécessaire

END $$;