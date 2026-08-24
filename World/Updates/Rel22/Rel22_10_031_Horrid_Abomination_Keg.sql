-- ----------------------------------------------------------------
-- The Horrid Abomination keg.
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
    SET @cOldContent = '030';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '031';
    SET @cNewDescription = 'Horrid_Abomination_Keg';
    SET @cNewComment = 'Horrid Abomination keg chain - panic, watchman shot, explosion, credit; restitching instead of death';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- `You Can't Take 'Em Alone` (14348): throwing the Black Gunpowder Keg landed
        -- 68555 `Keg Placed` on the Horrid Abomination - the wire shows the cast
        -- succeeding - and then nothing, because nothing handled the keg. The new
        -- `npc_horrid_abomination` runs TrinityCore's chain: panic line, a Duskhaven
        -- Watchman's shot (68559), the gore circle and explosion, credit to the
        -- keg-thrower, and Restitching instead of death for anyone who tries plain
        -- violence. Texts are TC's own five panic lines.
        DELETE FROM `script_texts` WHERE `entry` IN (-1999953, -1999954, -1999955, -1999956, -1999957);
        INSERT INTO `script_texts` (`entry`, `content_default`, `sound`, `type`, `language`, `emote`, `comment`) VALUES
        (-1999953, 'Barrel smell like gunpowder...', 0, 0, 0, 0, 'horrid abomination - keg placed 1'),
        (-1999954, 'GAH!!!!  I CAN''T SEE IN HERE!!!!', 0, 0, 0, 0, 'horrid abomination - keg placed 2'),
        (-1999955, 'Uh-oh... this gonna hurts me...', 0, 0, 0, 0, 'horrid abomination - keg placed 3'),
        (-1999956, 'This not be good...', 0, 0, 0, 0, 'horrid abomination - keg placed 4'),
        (-1999957, 'I gots bad feeling...', 0, 0, 0, 0, 'horrid abomination - keg placed 5');

        DELETE FROM `script_binding` WHERE `ScriptName` = 'npc_horrid_abomination';
        INSERT INTO `script_binding` (`type`, `ScriptName`, `bind`, `data`) VALUES
        (0, 'npc_horrid_abomination', 36231, 0);

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
