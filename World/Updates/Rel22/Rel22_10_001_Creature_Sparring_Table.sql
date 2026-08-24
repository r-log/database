-- ----------------------------------------------------------------
-- Add creature_sparring_template and the Gilneas City floors.
--
-- STRUCTURE bump: this creates a table. The CREATE lives here rather
-- than in FullDB so a database that only applies updates still gets it.
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
    SET @cOldStructure = '09';
    SET @cOldContent = '001';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '001';
    SET @cNewDescription = 'Creature_Sparring_Table';
    SET @cNewComment = 'Add creature_sparring_template so the Gilneas street battles run as theatre and the defenders stop dying';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- Gilneas was killing itself. Guards died instead of holding the street, the
        -- surviving worgen then piled onto the next thing along - Northgate Rebels,
        -- quest givers, the player - and Tobias Mistmantle, who takes `Sacrifices`
        -- (14212) in, was being cut down, which hard-blocks the turn-in.
        --
        -- A decode of the three retail captures (build 18019, 28,422 seconds, 1,017
        -- creature deaths recovered) says none of that is how it goes. Across 62
        -- minutes of city fighting NOT ONE defender dies: Northgate Rebel 36057 (14
        -- guids), 41015 (8), Gilneas City Guard 50474 (8), the cannons, and every
        -- named NPC all survive to the end of the capture. 41015 was caught mid-floor,
        -- ground down to 438 of 516 health - 84.9% - and stopped there. 35232 stopped
        -- at 85.00% exactly. The invaded city is theatre: the two sides brawl forever
        -- and the defenders never fall.
        --
        -- What DOES die is the attacking wave. Bloodfang Rippers 35505 died 242 times
        -- and Afflicted Gilneans 50471 eleven times against the guard lines with no
        -- player involved. So this is not a blanket immunity - it is a floor under the
        -- named brawlers and a conveyor of expendable attackers past them. The rows
        -- below reproduce that: nothing that Blizzard lets die is listed.
        --
        -- TrinityCore ships the same idea with a floor of 90; the capture measures 85,
        -- with rest values of 82.6-85.0% - the shape of "the crossing hit lands in
        -- full, then NPC damage goes to zero". 85 is used here because it is measured.

        DROP TABLE IF EXISTS `creature_sparring_template`;
        CREATE TABLE `creature_sparring_template` (
          `CreatureID` MEDIUMINT(8) UNSIGNED NOT NULL COMMENT 'creature_template entry of the protected VICTIM',
          `HealthLimitPct` FLOAT NOT NULL DEFAULT 100 COMMENT 'NPC attackers deal nothing at or below this health pct, and can never land a killing blow',
          PRIMARY KEY (`CreatureID`)
        ) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Creature sparring health floors';

        INSERT INTO `creature_sparring_template` (`CreatureID`, `HealthLimitPct`) VALUES
        -- Named NPCs. 100 means no NPC may take a single point off them, which is what
        -- the capture shows - none of these was ever damaged in 62 minutes.
        (35618, 100),   -- Tobias Mistmantle -- the quest 14212 turn-in, and the hard blocker
        (35551, 100),   -- Prince Liam Greymane (city)
        (35911, 100),   -- King Genn Greymane
        (35552, 100),   -- Lord Darius Crowley, quest giver
        (34913, 100),   -- Prince Liam Greymane (prologue)
        (35317, 100),   -- Rebel Cannon -- retail only ever damages it while a player mans it
        (35839, 100),   -- Sergeant Cleese
        (35872, 100),   -- Myriam Spellwaker
        -- The brawlers, on the measured floor.
        (36057, 85),    -- Northgate Rebel
        (41015, 85),    -- Northgate Rebel -- caught resting at 438/516 = 84.9%
        (50474, 85),    -- Gilneas City Guard
        (35504, 85),
        (35509, 85),
        (34864, 85),
        (34916, 85),
        (35232, 85),    -- caught resting at 85.00%
        -- Their opposite numbers, which retail only ever lets PLAYERS kill.
        (35229, 85),    -- Bloodfang Stalker -- its 244 deaths are all inside player set-pieces
        (51277, 85),    -- Bloodfang Stalker
        (35627, 85),    -- rests at 80-84%
        (35118, 85),    -- Bloodfang Worgen
        (34884, 85),    -- lower confidence: a few NPC-side deaths appear in the capture
        -- Duskhaven, from TrinityCore only - the later chapters are genuinely
        -- two-sided in the captures, so nothing is floored beyond these.
        (36211, 85),
        (34511, 85),
        (36236, 85),
        (36140, 100);

        -- NOT listed, deliberately: 35505 and 35916 Bloodfang Ripper, 50471 Afflicted
        -- Gilnean, 35456, 35463. Retail kills these by the hundred at the guard lines
        -- and they must stay killable, or the streets silt up with immortal attackers
        -- and the fight the player walks into never thins out. TrinityCore's rows for
        -- 35505 and 50471 contradict the capture and are not carried over.

        -- Two wire-truth corrections the capture turned up here are NOT carried:
        --
        -- 35231's health: retail's 18019 values run at twice ours (client-side
        -- doubling in that build), so the ride horse should read 4,080. The
        -- Sacrifices ride migration sets that final value; setting an interim
        -- 2,040 here would only be overwritten.
        --
        -- 35232's faction: the wire broadcasts FactionTemplate 2207, but 2207
        -- guards are neutral to worgen in DBC, which stops them defending the
        -- street. 2173 is kept - both resolve to faction 1134 underneath.

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
