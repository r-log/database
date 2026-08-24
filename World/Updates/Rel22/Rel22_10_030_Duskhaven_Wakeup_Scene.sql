-- ----------------------------------------------------------------
-- The Duskhaven wake-up scene, its texts and voice-over.
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
    SET @cOldContent = '029';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '030';
    SET @cNewDescription = 'Duskhaven_Wakeup_Scene';
    SET @cNewComment = 'The Duskhaven wake-up: 69123 summon target row (fade + Krennan), scripted Godfrey and Greymane walk-ins with the retail dialogue';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from Duskhaven_Wakeup_Scene ----
        -- The Duskhaven wake-up scene, from the capture (19:54:49 -> 19:57:07):
        -- arrival under 68630/68631 (fade to black, stunned), Krennan summoned at the
        -- player's side by 69123, Lord Godfrey walking in at +12 s and King Genn
        -- Greymane at +20 s, the four-line exchange, and King Greymane holding quest
        -- 14375 at the end of it.
        --
        -- Why none of it happened here: 69123's summon carries
        -- TARGET_SCRIPT_COORDINATES and had no `spell_script_target` row, and a
        -- missing row fails the WHOLE cast - taking the 94053 fade down with it. The
        -- trigger spawns (36198) sit on every retail summon spot already, so one row
        -- fixes both. The stock DB staged Krennan/Godfrey/Greymane as static phase-1
        -- spawns instead; retail summons them per player, and static plus summoned
        -- would stand doubled, so the statics retire and `npc_krennan_duskhaven`
        -- (bound below) plays the scene on the summoned Krennan at the capture's
        -- offsets.
        DELETE FROM `spell_script_target` WHERE `entry` = 69123;
        INSERT INTO `spell_script_target` (`entry`, `type`, `targetEntry`, `inverseEffectMask`) VALUES
        (69123, 1, 36198, 0);

        -- The static stand-ins (Krennan 36331, Godfrey 36330, Greymane 36332 by the
        -- stagecoach); the other 36332 spawns elsewhere in the zone stay.
        DELETE FROM `creature` WHERE `guid` IN (371633, 371557, 375757);

        -- 68639, 14375's completion cast, teleports through the position table too.
        DELETE FROM `spell_target_position` WHERE `id` = 68639;
        INSERT INTO `spell_target_position`
            (`id`, `target_map`, `target_position_x`, `target_position_y`, `target_position_z`, `target_orientation`) VALUES
        (68639, 654, -1818.4, 2294.25, 42.2135, 3.24666);

        -- The scene's four lines, emotes riding on the text rows.
        DELETE FROM `script_texts` WHERE `entry` IN (-1999949, -1999950, -1999951, -1999952);
        INSERT INTO `script_texts` (`entry`, `content_default`, `sound`, `type`, `language`, `emote`, `comment`) VALUES
        (-1999949, 'I am not giving up on you.  I don''t have a cure for the Curse yet... but there are treatments.  You will have control again.', 0, 0, 0, 274, 'krennan duskhaven - not giving up'),
        (-1999950, 'Give it up, Krennan.  It''s time to put this one down.  It''s protocol.', 0, 0, 0, 274, 'godfrey duskhaven - protocol'),
        (-1999951, 'Tell me, Godfrey.  Those that stayed in Gilneas City so that we could live.  Were they following protocol?', 0, 0, 0, 1, 'greymane duskhaven - were they following protocol'),
        (-1999952, 'I didn''t think so.  Now hand me that potion, Krennan... and double the dosage.', 0, 0, 0, 1, 'greymane duskhaven - double the dosage');

        DELETE FROM `script_binding` WHERE `ScriptName` = 'npc_krennan_duskhaven';
        INSERT INTO `script_binding` (`type`, `ScriptName`, `bind`, `data`) VALUES
        (0, 'npc_krennan_duskhaven', 36331, 0);

        -- ---- from Gilneas_Offer_Reward_Texts ----
        -- Three Gilneas quests shipped with an EMPTY OfferRewardText, so their
        -- completion windows opened blank - 14375 blocked the Duskhaven wake-up scene
        -- visually the moment the pushed reward window appeared. The words are the
        -- captures' own Completion Text fields, byte for byte (87 quests audited, all
        -- others already populated).
        UPDATE `quest_template` SET `OfferRewardText` = 'I need you to pull through, $n.  This dosage is strong enough to kill a horse.$B$BBut I know you.  I know what you''re made of.  You will be fine.$B$BTrust me.  I know what you''re going through.$B$BNow drink up and close your eyes.' WHERE `entry` = 14375;
        UPDATE `quest_template` SET `OfferRewardText` = 'Are you ready to set sail, $n?  Your people have been granted shelter in the lands of the kaldorei.$B$BDo not worry, $r.  Your people will get a chance to fight for Gilneas again.  This time, with the full strength of the Alliance.' WHERE `entry` = 14434;
        UPDATE `quest_template` SET `OfferRewardText` = 'Look, $n!  Look at what''s become of Duskhaven!$B$BLook at what''s become of the last safe place in Gilneas!' WHERE `entry` = 14467;

        -- ---- from Duskhaven_Wakeup_Scene_Voice ----
        -- The wake-up scene after the first transformation is voiced on
        -- retail: broadcast_text (verified build 18019) carries a SoundId on
        -- all four lines, in the same VO band as the proven Gilneas sounds
        -- (Lorna 19696, Genn 19709). Ours played silent.
        UPDATE `script_texts` SET `sound`=20919 WHERE `entry`=-1999949; -- Krennan: not giving up on you
        UPDATE `script_texts` SET `sound`=19635 WHERE `entry`=-1999950; -- Godfrey: it is protocol
        UPDATE `script_texts` SET `sound`=19721 WHERE `entry`=-1999951; -- Greymane: were they following protocol?
        UPDATE `script_texts` SET `sound`=19722 WHERE `entry`=-1999952; -- Greymane: double the dosage

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
