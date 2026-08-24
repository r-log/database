-- ----------------------------------------------------------------
-- The Dark Scout ambush and Belysra's Talisman.
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
    SET @cOldContent = '005';

    SET @cNewVersion = '22';
    SET @cNewStructure = '11';
    SET @cNewContent = '006';
    SET @cNewDescription = 'Dark_Scout_Ambush';
    SET @cNewComment = 'Losing Your Tail (24616): wire the Dark Scout ambush - areatrigger 6687 springs the trap (npc_dark_scout), Belysra talisman dummy reaches the scout';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from Dark_Scout_Ambush ----
        -- Losing Your Tail (24616): the Dark Scout (37953) had spell 70796 in
        -- creature_template_spells but nothing driving it - no AI, no binding.
        -- Capture (03:08:27): areatrigger 6687 springs the trap; 70794 freezes
        -- the player while the scout winds up the ten-second 70796 kill shot;
        -- Belysra Talisman (70797) breaks it via its dummy effect at the scout.
        DELETE FROM `script_binding` WHERE `ScriptName` IN ('npc_dark_scout', 'at_dark_scout_ambush', 'spell_belysra_talisman');
        INSERT INTO `script_binding` (`type`, `bind`, `ScriptName`) VALUES
        (0, 37953, 'npc_dark_scout'),
        (3, 6687, 'at_dark_scout_ambush'),
        (4, 70797, 'spell_belysra_talisman');

        DELETE FROM `spell_script_target` WHERE `entry` = 70797;
        INSERT INTO `spell_script_target` (`entry`, `type`, `targetEntry`) VALUES
        (70797, 1, 37953);

        DELETE FROM `script_texts` WHERE `entry` = -1999966;
        INSERT INTO `script_texts` (`entry`, `content_default`, `type`, `comment`) VALUES
        (-1999966, 'How did you--?!  It doesn''t matter -- I don''t need a trap to defeat you.', 0, 'dark scout - trap broken');

        -- ---- from Dark_Scout_All_Phase ----
        -- The Dark Scout spawn was phaseMask 1: the quest player stands in the
        -- Blackwald phase (131072, like Belysra), so the ambush grid search
        -- (phase-aware) never found the scout and the trap never sprang. The
        -- script gates its visibility, so all-phase is safe - map 654 convention.
        UPDATE `creature` SET `phaseMask` = 4294967295 WHERE `guid` = 222093;

        -- ---- from Talisman_Bind_Data_Col ----
        -- The loader builds the SD3 spell key as bind | (data << 24): the
        -- effect index goes in the DATA column, not baked into bind (mediumint
        -- clamped 16848013 to 8388607 and the row was ignored at boot). Bind
        -- the talisman dummy to spell 70797, effect 1, the intended way.
        DELETE FROM `script_binding` WHERE `ScriptName` = 'spell_belysra_talisman';
        INSERT INTO `script_binding` (`type`, `bind`, `data`, `ScriptName`) VALUES
        (4, 70797, 1, 'spell_belysra_talisman');

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
