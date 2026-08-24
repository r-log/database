-- ----------------------------------------------------------------
-- Gorerot's march.
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
    SET @cOldContent = '028';

    SET @cNewVersion = '22';
    SET @cNewStructure = '11';
    SET @cNewContent = '029';
    SET @cNewDescription = 'Battle_Gorerot_March';
    SET @cNewComment = 'Battle: Gorerot taunt, Darius catapult call (VO 19499) and join line (VO 19500), the march extended north to the final square; Gorerot sparring floor';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- The march continues past the Gorerot square: the giant taunts, Darius
        -- calls for the catapults (VO 19499) and later joins the king's push
        -- (VO 19500), and the column marches north to the final square. Gorerot
        -- holds at 20 so the catapults (player-driven) land the kill.
        DELETE FROM `script_texts` WHERE `entry` BETWEEN -1999997 AND -1999995;
        INSERT INTO `script_texts` (`entry`, `content_default`, `sound`, `type`, `comment`) VALUES
        (-1999995, 'Gorerot crush puny worgen!!', 0, 1, 'battle - gorerot taunt'),
        (-1999996, 'He''s too strong!  Use the catapults to bring him down!', 19499, 1, 'battle - darius catapults'),
        (-1999997, 'Let us join your father''s force''s, Liam.  They''ll need our help against Sylvanas.', 19500, 1, 'battle - darius joins');

        DELETE FROM `creature_sparring_template` WHERE `CreatureID` = 38331;
        INSERT INTO `creature_sparring_template` (`CreatureID`, `HealthLimitPct`) VALUES
        (38331, 20);

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
