-- ----------------------------------------------------------------
-- Lord Hewell's horse and its gossip.
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
    SET @cOldContent = '011';

    SET @cNewVersion = '22';
    SET @cNewStructure = '11';
    SET @cNewContent = '012';
    SET @cNewDescription = 'Hewell_Horse';
    SET @cNewComment = 'Flank the Forsaken (24677): Lord Hewell offers I need a horse (capture menu 11079) - summons Stout Mountain Horse 38765, boards via 46598, rides the';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from Hewell_Horse ----
        -- Flank the Forsaken (24677): Lord Hewell (38764) must offer a ride -
        -- capture: gossip "I need a horse." summons a Stout Mountain Horse
        -- (38765, vehicle 542), the player boards via 46598, and the horse
        -- rides the 1300-yard capture route down to the Stormglen staging
        -- point. Script-driven; bindings only.
        DELETE FROM `script_binding` WHERE `ScriptName` IN ('npc_lord_hewell', 'npc_stout_horse_flank');
        INSERT INTO `script_binding` (`type`, `bind`, `ScriptName`) VALUES
        (0, 38764, 'npc_lord_hewell'),
        (0, 38765, 'npc_stout_horse_flank');

        -- ---- from Hewell_Menu_Dedup ----
        -- Lord Hewell's menu 11079 already carried an "I need a horse." row
        -- with no condition and no action: it showed for everyone (quest or
        -- not) and did nothing when picked, doubling the scripted option. The
        -- script (npc_lord_hewell) is the single, quest-gated source now.
        DELETE FROM `gossip_menu_option` WHERE `menu_id` = 11079;

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
