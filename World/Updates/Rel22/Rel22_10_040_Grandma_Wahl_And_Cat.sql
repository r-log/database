-- ----------------------------------------------------------------
-- Grandma Wahl, Chance the cat and their texts.
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
    SET @cOldContent = '039';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '040';
    SET @cNewDescription = 'Grandma_Wahl_And_Cat';
    SET @cNewComment = 'Remove the duplicate outdoor Grandma Wahl - the capture has ONE static spawn (in the cottage); the outdoor copy is a scripted event actor';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from Grandma_Wahl_Duplicate ----
        -- Two Grandma Wahls stood in the same phase: the cottage one (guid 219757,
        -- exactly the capture's static spawn at -2116.89 2416.67 12.26) and an
        -- outdoor copy 40 yd away. On retail the outdoor Grandma exists only as a
        -- DYNAMIC event spawn (high guid counter in the capture, fighting 36461);
        -- a permanent world spawn of her is wrong. Remove it.
        DELETE FROM `creature` WHERE `guid` = 221861;

        -- ---- from Chance_The_Cat ----
        -- Grandma's Cat (14401). Clicking Chance did nothing: the spellclick row
        -- carried 43689 instead of the capture's 68743 `Get Cat`, and the spell's
        -- retail effect is a server event (61 -> 22401) nothing here served. Fix
        -- the row and bind the script: cat into the bags (item 49281), Lucius the
        -- Cruel steps out for his ambush.
        UPDATE `npc_spellclick_spells` SET `spell_id` = 68743 WHERE `npc_entry` = 36459;

        DELETE FROM `script_binding` WHERE `ScriptName` = 'npc_chance_the_cat';
        INSERT INTO `script_binding` (`type`, `bind`, `ScriptName`) VALUES (0, 36459, 'npc_chance_the_cat');

        -- ---- from Lucius_Grandma_Texts ----
        -- Grandma's Cat (14401) ambush voices, word for word from the capture.
        DELETE FROM `script_texts` WHERE `entry` IN (-1999964, -1999965);
        INSERT INTO `script_texts` (`entry`, `content_default`, `sound`, `type`, `language`, `emote`, `comment`) VALUES
        (-1999964, 'I''ll be taking this cat.  It seems to work as the perfect bait.  Prepare to die now, fool!', 0, 0, 0, 0, 'lucius the cruel - ambush'),
        (-1999965, 'You do not mess with my kitty you son of a mongrel!', 0, 0, 0, 0, 'grandma wahl - kitty defense');

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
