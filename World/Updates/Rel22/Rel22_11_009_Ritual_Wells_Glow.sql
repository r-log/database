-- ----------------------------------------------------------------
-- Make the ritual wells glow.
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
    SET @cOldContent = '008';

    SET @cNewVersion = '22';
    SET @cNewStructure = '11';
    SET @cNewContent = '009';
    SET @cNewDescription = 'Ritual_Wells_Glow';
    SET @cNewComment = 'Neither Human Nor Beast (24593): the well glow (71200) belongs on the well bunny, not the clicker - go_ritual_well suppresses the goober player-cast';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- Neither Human Nor Beast (24593): the goober default cast the well
        -- spell (71200, the 12s light column) on the CLICKER; the capture shows
        -- the invisible bunny on each well casting it on itself. go_ritual_well
        -- redirects the glow and adds Lyros' one-time blessing line.
        DELETE FROM `script_binding` WHERE `ScriptName` = 'go_ritual_well';
        INSERT INTO `script_binding` (`type`, `bind`, `ScriptName`) VALUES
        (1, 201950, 'go_ritual_well'),
        (1, 201951, 'go_ritual_well'),
        (1, 201952, 'go_ritual_well');

        DELETE FROM `script_texts` WHERE `entry` = -1999967;
        INSERT INTO `script_texts` (`entry`, `content_default`, `type`, `comment`) VALUES
        (-1999967, 'Just as Goldrinn''s spirit once blessed our druids, let $n be blessed with the wisdom of his race and the ferocity of the wolf god.', 0, 'lyros swiftwind - ritual wells blessing');

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
