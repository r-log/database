-- ----------------------------------------------------------------
-- Royal guards fight the worgen rather than ignoring them.
--
-- FactionAlliance stays 2173. A later experiment moved it to the wire
-- value 2207, but DBC shows 2207 guards are neutral to worgen.
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
    SET @cOldContent = '012';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '013';
    SET @cNewDescription = 'Royal_Guards_Fight_Worgen';
    SET @cNewComment = 'Give the Gilnean Royal Guards the same faction as the City Guards beside them, so they engage worgen instead of standing idle';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- The twenty `Gilnean Royal Guard` (35232) spawns in the Military District
        -- stood through the worgen attack without lifting a weapon. Nothing is wrong
        -- with their flags - UnitFlags 33024 is CAN_SWIM plus OOC_NOT_ATTACKABLE, not
        -- PASSIVE and not PACIFIED - and they share phase 2 with the worgen, so they
        -- can see each other. The hostility is simply one-directional in the DBC:
        --
        --   template 2207 (guard)     faction 1134  enemies [14]    enemyGroup 0x4
        --   template 2179 (Bloodfang) faction 24    enemies [1134]  group      0x8
        --
        -- The worgen list the guards' faction 1134 as an enemy, so worgen attack
        -- guards. The guards' own template lists neither faction 24 nor a matching
        -- group - 0x4 is the Horde bit, and the worgen sit in the monster group 0x8 -
        -- so guards never treat worgen as enemies and never initiate.
        --
        -- 2207 is correct for the player-allied Worgen Warriors of the later Forsaken
        -- chapters, which is what it was presumably copied from; it is wrong for a
        -- city guard defending against the beasts. The `Gilneas City Guard` (34916)
        -- standing in the same district, in the same phase, with the identical
        -- UnitFlags 33024, already uses template 2173, whose enemyGroup 0xC covers
        -- both the Horde bit and the monster bit. The Royal Guards are the outlier.
        --
        -- Verified against FactionTemplate.dbc before changing: 2173 is hostile to
        -- every worgen variant present here - 2179 Bloodfang, 2174 Rampaging and the
        -- raw template 24 used by Bloodfang Lurker - and remains friendly to the
        -- player and to every other Gilneas ally, namely 35 (mastiffs and rebel
        -- cannons), 2163 survivors, 2166 militia, 2182 Northgate rebels and 2207
        -- itself, so the guards will not turn on anything they stand beside today.
        UPDATE `creature_template`
        SET `FactionAlliance` = 2173,
            `FactionHorde` = 2173
        WHERE `entry` = 35232;

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
