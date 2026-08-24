-- ----------------------------------------------------------------
-- The city finale phase windows.
--
-- Two of the four windows were provably unwinnable - DBC AreaGroup locks
-- 69812 and 68770 onto Kalimdor - so they are not carried.
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
    SET @cOldContent = '003';

    SET @cNewVersion = '22';
    SET @cNewStructure = '11';
    SET @cNewContent = '004';
    SET @cNewDescription = 'City_Phase_Windows';
    SET @cNewComment = 'Phase-timeline audit P2+P3: restore the three missing city phase windows (post-14159/14293/14221) and the post-24681 finale phase; spawn-verified';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from City_Finale_Phases ----
        -- Phase-timeline audit, P2 + P3 (report: GILNEAS_PHASE_TIMELINE.md).
        -- P2: three city phase windows retail applies that our spell_area never
        -- did - their populations (144 spawns mask 4, 516 mask 8, 24 mask 1024)
        -- have sat invisible. Regression-verify with a fresh character.
        DELETE FROM `spell_area` WHERE `spell` IN (69812, 68770, 67789) AND `area` IN (4714, 4755);
        INSERT INTO `spell_area` (`spell`, `area`, `quest_start`, `quest_start_active`, `quest_end`, `condition_id`, `aura_spell`, `racemask`, `gender`, `autocast`) VALUES
        (69812, 4714, 14159, 0, 14293, 0, 0, 0, 2, 1),
        (69812, 4755, 14159, 0, 14293, 0, 0, 0, 2, 1),
        (68770, 4714, 14293, 0, 14221, 0, 0, 0, 2, 1),
        (68770, 4755, 14293, 0, 14221, 0, 0, 0, 2, 1),
        (67789, 4714, 14221, 0, 14222, 0, 0, 0, 2, 1),
        (67789, 4755, 14221, 0, 14222, 0, 0, 0, 2, 1);

        -- P3: the finale phase after 24681; gate passed (508 creatures + 252
        -- gameobjects on map 654 carry mask 4194304).
        DELETE FROM `spell_area` WHERE `spell` = 74093 AND `area` IN (4714, 4755);
        INSERT INTO `spell_area` (`spell`, `area`, `quest_start`, `quest_start_active`, `quest_end`, `condition_id`, `aura_spell`, `racemask`, `gender`, `autocast`) VALUES
        (74093, 4714, 24681, 0, 0, 0, 0, 0, 2, 1),
        (74093, 4755, 24681, 0, 0, 0, 0, 0, 2, 1);

        -- ---- from Remove_Unwinnable_Death_Spell_Area ----
        -- 69812 "Death?" carries a client-DBC AreaGroup lock (2103 -> area 1224,
        -- map 1 Kalimdor); the spell_area autocast fired on rewarding 14159 fails
        -- SPELL_FAILED_INCORRECT_AREA by construction on map 654, flashing red
        -- "You are in the wrong zone." at the player. The aura has never applied
        -- once in this core; the rows are inert except for the error flash. The
        -- bite scene continues to ride 72870''s spell_area row + DBS_ON_SPELL.
        DELETE FROM `spell_area` WHERE `spell`=69812 AND `area` IN (4714,4755);

        -- ---- from Remove_Unwinnable_68770_Spell_Area ----
        -- 68770 "Death to Agogridon Complete" carries a client-DBC AreaGroup
        -- lock (creq 4897 -> AreaGroup 1 -> area 2198, map 1 Kalimdor). Its
        -- spell_area autocast opens on rewarding 14293 and fails
        -- SPELL_FAILED_INCORRECT_AREA by construction on map 654 - and since
        -- the aura never applies, EVERY re-evaluation (each area crossing,
        -- each quest event) retries and flashes red. Live ZONETRACE caught it
        -- three times in seventeen seconds. Same disease as 69812 (mig 162);
        -- no other reference to the spell exists in the world DB.
        DELETE FROM `spell_area` WHERE `spell`=68770 AND `area` IN (4714,4755);

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
