-- ----------------------------------------------------------------
-- Shaken survivors stand still.
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
    SET @cOldContent = '024';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '025';
    SET @cNewDescription = 'Shaken_Survivors_Still';
    SET @cNewComment = 'Shaken Survivor 35554 spawns stop wandering - the retail capture sends them no MONSTER_MOVE at all';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- The eleven `Shaken Survivor` (35554) in Greymane Court wandered, because
        -- every one of their spawn rows carries `MovementType` 1 (random) with a 3 yard
        -- radius. Their creature_template asks for 0; only the spawns disagree.
        --
        -- Retail does not move them at all. In the 18019 Gilneas capture the same
        -- eleven are present - entry 35554, guids with counters 1529, 1530, 1533-1537
        -- and 2472-2474, 2477, so our spawn count already matches - and across the
        -- whole 62 minute capture **not one MONSTER_MOVE is addressed to any of them**.
        -- That is out of 41,085 MONSTER_MOVE packets decoded in that file, and the
        -- decoder is not blind to the area: in the same pass it attributes 6,474 moves
        -- to 411 distinct Bloodfang Stalker (35229) guids. Zero here is a real zero.
        --
        -- Their neighbours in the same phase are already right - Injured Citizen 44470
        -- and every named NPC in the court sit at MovementType 0 - so 35554 was the
        -- only outlier in phase 8. The Bloodfang Stalkers and Crowley's ride
        -- accessories keep their random movement; that was set deliberately by
        -- Rel22_07_056 for the Sacrifices chase.
        UPDATE `creature`
        SET `MovementType` = 0,
            `spawndist` = 0
        WHERE `id` = 35554;

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
