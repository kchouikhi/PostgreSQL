DO $$
DECLARE
    v_direct_join_found BOOLEAN := FALSE;
    v_intermediate_results TEXT := '';
    rec RECORD;  -- Déclaration de la variable de type RECORD
BEGIN
    -- Vérification de la jointure directe (via une clé étrangère)
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage ccu
          ON ccu.constraint_name = tc.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND kcu.table_name = 'nms_phys_comp'
          AND kcu.column_name = 'serial'
          AND ccu.table_name = 'nms_ip_subnet'
          AND ccu.column_name = 'name'
    ) INTO v_direct_join_found;

    IF v_direct_join_found THEN
        RAISE NOTICE 'Jointure directe possible entre nms_phys_comp.serial et nms_ip_subnet.name.';
    ELSE
        RAISE NOTICE 'Pas de jointure directe trouvée. Recherche des tables intermédiaires...';
        
        -- Recherche des tables intermédiaires
        FOR rec IN
            SELECT DISTINCT c1.table_name AS table1, c1.column_name AS col1, c2.table_name AS table2, c2.column_name AS col2
            FROM information_schema.columns c1
            JOIN information_schema.columns c2
              ON c1.column_name = c2.column_name
            WHERE c1.table_name IN ('nms_phys_comp', 'nms_ip_subnet')
              AND c1.table_name <> c2.table_name
              AND c2.table_name NOT IN ('nms_phys_comp', 'nms_ip_subnet')
        LOOP
            v_intermediate_results := v_intermediate_results || 
                'Relation potentielle via : ' || rec.table1 || ' (' || rec.col1 || ') --> ' ||
                rec.table2 || ' (' || rec.col2 || ')' || E'\n';
        END LOOP;

        -- Affichage des résultats intermédiaires
        IF v_intermediate_results IS NOT NULL THEN
            RAISE NOTICE '%', v_intermediate_results;
        ELSE
            RAISE NOTICE 'Aucune relation intermédiaire trouvée.';
        END IF;
    END IF;
END $$;