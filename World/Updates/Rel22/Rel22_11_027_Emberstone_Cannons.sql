-- ----------------------------------------------------------------
-- The Emberstone cannons: phase, boarding and selection.
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
    SET @cOldContent = '026';

    SET @cNewVersion = '22';
    SET @cNewStructure = '11';
    SET @cNewContent = '027';
    SET @cNewDescription = 'Emberstone_Cannons';
    SET @cNewComment = 'Emberstone Cannons (38424) sat in phase 1, invisible to the battle - promoted to 262144; vehicle 470 + spellclick 72009 already wired';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from Cannons_In_Phase ----
        -- The Emberstone Cannons for the abomination wall sat in phase 1 -
        -- invisible to the battle-phase player. Their vehicle kit (470) and
        -- boarding spellclick (72009) were already wired; only the phase was
        -- wrong.
        UPDATE `creature` SET `phaseMask` = 262144 WHERE `id` = 38424;

        -- ---- from Cannons_Boardable ----
        -- The cannon spellclick carried 72009 - the cannon's own SHOT (school
        -- damage 659 + knockback), not a boarding spell; clicking tried to fire
        -- the gun at nothing instead of seating the gunner. 46598 (the proven
        -- ride-vehicle boarding) seats the player; the shot stays on the
        -- vehicle bar. Also: two cannons stood 2.9 yards apart - unclickable
        -- clutter; the pair is spread.
        DELETE FROM `npc_spellclick_spells` WHERE `npc_entry` = 38424;
        INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `quest_start`, `quest_start_active`, `quest_end`, `cast_flags`, `condition_id`) VALUES
        (38424, 46598, 0, 0, 0, 1, 0);

        UPDATE `creature` SET `position_x` = -1569.20, `position_y` = 1309.80 WHERE `guid` = 222263;

        -- ---- from Cannons_Selectable ----
        -- The last lock on the cannon: its template ships
        -- UNIT_FLAG_NOT_SELECTABLE (0x2000000) - the client cannot target or
        -- hover it, so no spellclick can ever fire (the catapult symptom all
        -- over again). Working click-vehicles (Rebel Cannon, the coach) carry 0.
        UPDATE `creature_template` SET `UnitFlags` = `UnitFlags` & ~33554432 WHERE `Entry` = 38424;

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
