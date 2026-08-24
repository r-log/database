-- ----------------------------------------------------------------
-- Prison defender health and the Crowley brawl floor.
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
    SET @cOldContent = '015';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '016';
    SET @cNewDescription = 'Prison_Defenders';
    SET @cNewComment = 'Crowley holds his ground with the captured kit (Left Hook 67825, Snap Kick 67827, Demoralizing Shout 61044 - all knockback-verified); Tobias gets a';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from Crowley_Brawl_Tobias_Floor ----
        -- Lord Darius Crowley stands his ground on the prison roof and answers
        -- the wave with his captured kit: Left Hook 67825 (knockback punch),
        -- Snap Kick 67827 (knockback kick), Demoralizing Shout 61044.
        DELETE FROM `script_binding` WHERE `ScriptName` = 'npc_lord_darius_prison';
        INSERT INTO `script_binding` (`type`, `bind`, `ScriptName`) VALUES
        (0, 35077, 'npc_lord_darius_prison');
        -- Tobias Mistmantle holds the roof alongside him and must survive the
        -- event: NPC damage floors at a quarter health (players never fight him).
        DELETE FROM `creature_sparring_template` WHERE `CreatureID` = 35124;
        INSERT INTO `creature_sparring_template` (`CreatureID`, `HealthLimitPct`) VALUES (35124, 25);

        -- ---- from Prison_Defender_Health ----
        -- The 18019 create blocks: Lord Darius Crowley holds 2244 health at
        -- level 5 (elite scaling - Rank 1 already matches) and Tobias 172.
        -- Our rows stored EXACTLY HALF of each (1122 / 83).
        UPDATE `creature_template` SET `MinLevelHealth`=2244, `MaxLevelHealth`=2244 WHERE `entry`=35077;
        UPDATE `creature_template` SET `MinLevelHealth`=172, `MaxLevelHealth`=172 WHERE `entry`=35124;

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
