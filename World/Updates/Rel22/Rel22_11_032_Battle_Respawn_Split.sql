-- ----------------------------------------------------------------
-- Split the battle respawn timers.
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
    SET @cOldStructure = '11';
    SET @cOldContent = '031';

    SET @cNewVersion = '22';
    SET @cNewStructure = '11';
    SET @cNewContent = '032';
    SET @cNewDescription = 'Battle_Respawn_Split';
    SET @cNewComment = 'Battle for Gilneas City is an endless grinder in the capture: posts refill ~6s after each wipe on BOTH sides; battle-phase combatants get 15s respawns';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from Battle_Grinder_Respawns ----
        -- The capture's city battle never thins: worgen warrior posts refill
        -- ~6 seconds after a wave dies on Gorerot, and the Forsaken side
        -- cycles the same way - the war is an endless grinder the army fights
        -- THROUGH, not a field it clears. Our 300s timers left dead streets.
        UPDATE `creature` SET `spawntimesecs`=15
            WHERE `map`=654 AND (`phaseMask` & 262144)
              AND `id` IN (38348, 38210, 38192, 38420);

        -- ---- from Battle_Respawn_Split ----
        -- 15s on the Forsaken side made every block refill before the army's
        -- clear-gate could open: the march could never advance. The split: the
        -- PUSH outpaces the war (Forsaken 120s - a block stays clear about two
        -- minutes, the column needs thirty seconds, and the war refills BEHIND
        -- the army), while the worgen grinder at Gorerot keeps its 6-second
        -- retail cycle since it gates nothing.
        UPDATE `creature` SET `spawntimesecs`=120
            WHERE `map`=654 AND (`phaseMask` & 262144)
              AND `id` IN (38210, 38192, 38420);

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
