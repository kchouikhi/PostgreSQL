DECLARE
    v_direct_join_found BOOLEAN := FALSE;
    CURSOR intermediate_tables IS
        SELECT a.table_name AS table1, b.table_name AS table2, a.column_name AS col1, b.column_name AS col2
        FROM all_tab_columns a
        JOIN all_tab_columns b ON a.column_name = b.column_name
        WHERE a.table_name IN ('NMS_PHYS_COMP', 'NMS_IP_SUBNET')
          AND b.table_name NOT IN ('NMS_PHYS_COMP', 'NMS_IP_SUBNET');

    v_sql VARCHAR2(1000);
BEGIN
    -- Vérification de la jointure directe
    SELECT COUNT(*) INTO v_direct_join_found
    FROM all_constraints c
    JOIN all_cons_columns col1 ON c.constraint_name = col1.constraint_name
    JOIN all_cons_columns col2 ON c.r_constraint_name = col2.constraint_name
    WHERE col1.table_name = 'NMS_PHYS_COMP'
      AND col2.table_name = 'NMS_IP_SUBNET'
      AND col1.column_name = 'SERIAL'
      AND col2.column_name = 'NAME'
      AND c.constraint_type = 'R';

    IF v_direct_join_found THEN
        DBMS_OUTPUT.PUT_LINE('Jointure directe possible entre NMS_PHYS_COMP.SERIAL et NMS_IP_SUBNET.NAME.');
    ELSE
        -- Recherche des tables intermédiaires
        FOR rec IN intermediate_tables LOOP
            v_sql := 'SELECT COUNT(*) FROM ' || rec.table1 || ' t1 ' ||
                     'JOIN ' || rec.table2 || ' t2 ON t1.' || rec.col1 || ' = t2.' || rec.col2;

            DBMS_OUTPUT.PUT_LINE('Relation potentielle via : ' || rec.table1 || ' (' || rec.col1 || ') --> ' ||
                                                         rec.table2 || ' (' || rec.col2 || ')');
        END LOOP;
    END IF;
END;
/