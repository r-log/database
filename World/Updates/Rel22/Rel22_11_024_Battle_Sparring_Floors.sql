-- ----------------------------------------------------------------
-- Battle sparring floors: the army kills with the player.
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
    SET @cOldContent = '023';

    SET @cNewVersion = '22';
    SET @cNewStructure = '11';
    SET @cNewContent = '024';
    SET @cNewDescription = 'Battle_Sparring_Floors';
    SET @cNewComment = 'Battle stage 2 - the charge: war-cry texts, abomination warning VO 19609, and sparring floors so the street fights burn as theatre while the army';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from Battle_Stage2_Charge ----
        -- Battle stage 2 - the charge into the city. War cries (unvoiced says
        -- in the capture), the abomination warning (VO 19609), and sparring
        -- floors: the named hold at full, the ranks bleed but do not die, the
        -- Forsaken can only be finished by the player.
        DELETE FROM `script_texts` WHERE `entry` BETWEEN -1999991 AND -1999988;
        INSERT INTO `script_texts` (`entry`, `content_default`, `sound`, `type`, `comment`) VALUES
        (-1999988, 'Push them back!', 0, 0, 'battle - push them back'),
        (-1999989, 'Your time is up, Forsaken scum!', 0, 0, 'battle - time is up'),
        (-1999990, 'Gilneas will prevail!', 0, 0, 'battle - prevail'),
        (-1999991, 'Abominations are blocking the way towards the military district!  This won''t be easy.', 19609, 1, 'battle - abomination wall');

        DELETE FROM `creature_sparring_template` WHERE `CreatureID` IN (38218, 38221, 38348, 38210, 38192);
        INSERT INTO `creature_sparring_template` (`CreatureID`, `HealthLimitPct`) VALUES
        (38218, 100),   -- Prince Liam - untouchable
        (38221, 60),    -- Gilnean Militia
        (38348, 60),    -- Worgen Warrior
        (38210, 10),    -- Forsaken Crossbowman - only the player finishes them
        (38192, 10);    -- Forsaken Infantry

        -- ---- from Forsaken_Killable ----
        -- The whole point is clearing the city TOGETHER: the Forsaken floors
        -- made the army harmless. Militia may finish crossbowmen and infantry;
        -- their own 60 floor keeps the ranks standing.
        DELETE FROM `creature_sparring_template` WHERE `CreatureID` IN (38210, 38192);

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
