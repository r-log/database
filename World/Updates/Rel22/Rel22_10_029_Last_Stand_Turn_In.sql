-- ----------------------------------------------------------------
-- Last Stand turn-in: the cascade is served by the SD3 hook.
--
-- No CompleteScript is set. npc_lord_darius_crowley::OnQuestRewarded
-- handles the turn-in and returns true; the two casts the map-script
-- queue would have run never executed from it (confirmed on the wire).
-- The spell_target_position row stays - the hook's cast reads it.
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
    SET @cOldContent = '028';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '029';
    SET @cNewDescription = 'Last_Stand_Turn_In';
    SET @cNewComment = 'Last Stand turn-in: forced worgen form (98274) under the movie, triggered casts immune to combat state, bind row for 72799';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- The Last Stand turn-in cascade is served by the SD3 hook
        -- npc_lord_darius_crowley::OnQuestRewarded, which runs the casts inside
        -- RewardQuest's own call stack and returns true.
        --
        -- No CompleteScript is set for 14222. The wire showed the two casts a
        -- CompleteScript would have queued (72799 Last Stand Complete, 98274 Force
        -- Worgen Altered Form) never executed from the map-script queue, while the
        -- same turn-in's RewSpellCast always did. FullDB ships CompleteScript 0 for
        -- this quest, so the clear below only matters to a database where one was
        -- set by hand.
        --
        -- The stock chain must not be left in place either: it cast 68996 `Two
        -- Forms`, the racial TOGGLE, which carries a hard combat block - and since
        -- the cathedral battle rework the player is still combat-flagged at turn-in,
        -- so the transformation silently stopped happening. A forced story beat must
        -- not go through a player toggle; the hook casts 98274 instead.
        UPDATE `quest_template` SET `CompleteScript` = 0 WHERE `entry` = 14222;
        DELETE FROM `db_scripts` WHERE `script_type` = 1 AND `id` = 14222;

        DELETE FROM `spell_target_position` WHERE `id` = 72799;
        INSERT INTO `spell_target_position`
            (`id`, `target_map`, `target_position_x`, `target_position_y`, `target_position_z`, `target_orientation`) VALUES
        (72799, 654, -1818.4, 2294.25, 42.2135, 3.24666);

        -- ---- from Crowley_Turn_In_Hook ----
        -- Bind Lord Darius Crowley so the Last Stand turn-in casts run in
        -- RewardQuest's own call stack. The wire proved the DB CompleteScript's two
        -- queued casts (72799, 98274) never executed while the same turn-in's
        -- RewSpellCast always did; the SD3 OnQuestRewarded hook takes their place
        -- and retires the CompleteScript for this quest.
        DELETE FROM `script_binding` WHERE `ScriptName` = 'npc_lord_darius_crowley';
        INSERT INTO `script_binding` (`type`, `ScriptName`, `bind`, `data`) VALUES
        (0, 'npc_lord_darius_crowley', 35566, 0);

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
