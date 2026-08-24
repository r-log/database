-- ----------------------------------------------------------------
-- The Horn of Tal'doren and its fight floors.
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
    SET @cOldContent = '007';

    SET @cNewVersion = '22';
    SET @cNewStructure = '11';
    SET @cNewContent = '008';
    SET @cNewDescription = 'Horn_Of_Taldoren';
    SET @cNewComment = 'Take Back What Is Ours (24646): wire the Horn of Taldoren - spell 71061 SEND_EVENT 23338 summons Tobias + ten Taldoren Trackers (capture positions)';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from Horn_Of_Taldoren ----
        -- Take Back What's Ours (24646): the Horn of Tal'doren (50134 ->
        -- 71061) fires scripted event 23338, which had no handler - nothing
        -- spawned. event_horn_of_taldoren summons Tobias Mistmantle and the
        -- ten Tal'doren Trackers at the capture positions to charge the
        -- Veteran Dark Rangers guarding the Worn Coffer.
        DELETE FROM `script_binding` WHERE `ScriptName` = 'event_horn_of_taldoren';
        INSERT INTO `script_binding` (`type`, `bind`, `ScriptName`) VALUES
        (6, 23338, 'event_horn_of_taldoren');

        -- ---- from Horn_Fight_Sparring ----
        -- The horn fight is THEATRE, like the city battles: the capture shows
        -- no tracker ever dying and rangers resting at 4.8% under the pack
        -- (their zeros are player kills, which bypass sparring). Floors,
        -- measured: rangers 5, trackers 15, Tobias full.
        DELETE FROM `creature_sparring_template` WHERE `CreatureID` IN (38022, 38027, 38029);
        INSERT INTO `creature_sparring_template` (`CreatureID`, `HealthLimitPct`) VALUES
        (38022, 5),     -- Veteran Dark Ranger - capture rests at 4.8
        (38027, 15),    -- Tal'doren Tracker - none ever died, lows ~15
        (38029, 100);   -- Tobias Mistmantle - never touched

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
