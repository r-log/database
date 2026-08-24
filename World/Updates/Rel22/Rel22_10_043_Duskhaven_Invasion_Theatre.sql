-- ----------------------------------------------------------------
-- Stage the Duskhaven invasion theatre.
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS `update_mangos`;

DELIMITER $$

CREATE PROCEDURE `update_mangos`()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SHOW ERRORS;
        SELECT '* UPDATE FAILED *' AS `===== Status =====`,
               @cCurResult AS `===== DB is on Version: =====`;
        RESIGNAL;
    END;

    SET @cCurVersion := (SELECT `version` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cCurStructure := (SELECT `structure` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cCurContent := (SELECT `content` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);

    SET @cOldVersion = '22';
    SET @cOldStructure = '10';
    SET @cOldContent = '042';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '043';
    SET @cNewDescription = 'Duskhaven_Invasion_Theatre';
    SET @cNewComment = 'Duskhaven invasion staged to the capture: Liam holds the capture spot and gets npc_prince_liam_duskhaven (bottle+shoot instead of bare-handed';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- The capture stages the Duskhaven invasion on 18 Forsaken Invader
        -- spawn points (respawns folded by first-position clustering); ours had
        -- 29 rows - 12 already matching the capture exactly, 6 near-misses
        -- snapped to the exact points here, and 11 extras (stacked pairs among
        -- them) that balled into one bare-knuckle knot around Prince Liam.
        -- The 17 Duskhaven Watchmen were already exact - untouched. Liam
        -- himself moves to the spot he holds through the whole capture and is
        -- bound to npc_prince_liam_duskhaven: bottle (68552) and rifle (68559)
        -- from his post, melee only for what reaches him.
        DELETE FROM `creature` WHERE `guid` IN (221180,221738,221174,221358,221725,221724,221737,221734,221733,221731,221362);
        UPDATE `creature` SET `position_x`=-1918.5, `position_y`=2330.18, `position_z`=38.42, `orientation`=3.23 WHERE `guid`=221727;
        UPDATE `creature` SET `position_x`=-1930.84, `position_y`=2324.91, `position_z`=36.43, `orientation`=4.64 WHERE `guid`=221361;
        UPDATE `creature` SET `position_x`=-1928.24, `position_y`=2319.3, `position_z`=37.22, `orientation`=0.2 WHERE `guid`=221736;
        UPDATE `creature` SET `position_x`=-1924.65, `position_y`=2326.96, `position_z`=37.6, `orientation`=0.77 WHERE `guid`=221357;
        UPDATE `creature` SET `position_x`=-1939.2, `position_y`=2311.68, `position_z`=36.93, `orientation`=0.8 WHERE `guid`=221177;
        UPDATE `creature` SET `position_x`=-1935.33, `position_y`=2317.71, `position_z`=36.75, `orientation`=4.35 WHERE `guid`=221175;
        UPDATE `creature` SET `position_x`=-1924.66, `position_y`=2320.02, `position_z`=37.63, `orientation`=2.489 WHERE `guid` IN (SELECT * FROM (SELECT guid FROM `creature` WHERE `map`=654 AND `id`=36140) t);
        INSERT INTO `script_binding` (`type`,`ScriptName`,`bind`,`data`) VALUES (0,'npc_prince_liam_duskhaven',36140,0);

        INSERT INTO `db_version` VALUES (@cNewVersion, @cNewStructure,
            @cNewContent, @cNewDescription, @cNewComment);
        SET @cNewResult := (SELECT `description` FROM `db_version`
            WHERE `version` = @cNewVersion AND `structure` = @cNewStructure
              AND `content` = @cNewContent);
        COMMIT;
        SELECT '* UPDATE COMPLETE *' AS `===== Status =====`,
               @cNewResult AS `===== DB is now on Version =====`;
    ELSE
        IF (@cCurResult = @cNewResult) THEN
            SELECT '* UPDATE SKIPPED *' AS `===== Status =====`,
                   @cCurResult AS `===== DB is already on Version =====`;
        ELSE
            IF (@cCurResult IS NULL) THEN
                SELECT '* UPDATE FAILED *' AS `===== Status =====`,
                       'Unable to locate DB Version Information' AS `============= Error Message =============`;
            ELSE
                SET @cCurOutput = CONCAT(@cCurVersion, '_', @cCurStructure,
                    '_', @cCurContent, ' - ', @cCurResult);
                SET @cOldOutput = CONCAT(@cOldVersion, '_', @cOldStructure,
                    '_', @cOldContent, ' - ',
                    COALESCE(@cOldResult, 'IS NOT APPLIED'));
                SELECT '* UPDATE SKIPPED *' AS `===== Status =====`,
                       @cOldOutput AS `=== Expected ===`,
                       @cCurOutput AS `===== Found Version =====`;
            END IF;
        END IF;
    END IF;
END $$

DELIMITER ;

CALL update_mangos();

DROP PROCEDURE IF EXISTS `update_mangos`;
