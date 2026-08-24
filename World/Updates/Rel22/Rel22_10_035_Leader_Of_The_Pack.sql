-- ----------------------------------------------------------------
-- Leader Of The Pack: the whistle, Thyala and the pack.
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
    SET @cOldContent = '034';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '035';
    SET @cNewDescription = 'Leader_Of_The_Pack';
    SET @cNewComment = 'Leader of the Pack - point 68682 spell_script_target at Dark Ranger Thyala and bind spell_call_attack_mastiffs';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from Mastiff_Whistle ----
        -- `Leader of the Pack` (14386). The Mastiff Whistle (49240, spell 68682)
        -- failed with "invalid target": the spell_script_target row pointed at a
        -- stray GAMEOBJECT (176210) - one of the junk rows this table carries - so
        -- the script-target search never found Dark Ranger Thyala. Point it at her
        -- (creature 36312) and bind the SD3 spell script that answers the whistle
        -- with TrinityCore's ten Attack Mastiffs.
        DELETE FROM `spell_script_target` WHERE `entry` = 68682;
        INSERT INTO `spell_script_target` (`entry`, `type`, `targetEntry`, `inverseEffectMask`) VALUES (68682, 1, 36312, 0);

        DELETE FROM `script_binding` WHERE `ScriptName` = 'spell_call_attack_mastiffs';
        INSERT INTO `script_binding` (`type`, `bind`, `ScriptName`) VALUES (4, 68682, 'spell_call_attack_mastiffs');

        -- ---- from Thyala_Damage ----
        -- `Leader of the Pack` (14386), part two. Dark Ranger Thyala carried
        -- DamageMultiplier 35 - raid-boss scaling on a level-7 quest target - so her
        -- 6-9 melee landed as 210-315 and every Attack Mastiff died in one hit on
        -- approach. The 18019 capture shows the opposite fight: she appears ONLY as
        -- a target, the pack bites her for 12-16 a hit, and nearby troopers trade
        -- normal 12-13 blows with stray dogs. Multiplier to 1 (her neighbors'
        -- value), and the mastiffs' bite raised to the capture's numbers.
        UPDATE `creature_template` SET `DamageMultiplier` = 1 WHERE `Entry` = 36312;
        UPDATE `creature_template` SET `DamageMultiplier` = 2.5 WHERE `Entry` = 36405;

        -- ---- from Thyala_Pack_Despawn ----
        -- Leader of the Pack (14386), final polish. The whistle pack (60 s summons)
        -- despawns two seconds after Dark Ranger Thyala dies instead of brawling
        -- with the shore Forsaken; the resident shore mastiffs are untouched.
        DELETE FROM `script_binding` WHERE `ScriptName` = 'npc_dark_ranger_thyala';
        INSERT INTO `script_binding` (`type`, `bind`, `ScriptName`) VALUES (0, 36312, 'npc_dark_ranger_thyala');

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
