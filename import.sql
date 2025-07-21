CREATE TABLE IF NOT EXISTS `huzo_societymoney` (
  `job` VARCHAR(50) NOT NULL,
  `money` INT(11) NOT NULL DEFAULT 0,
  `ItemsAndGuns` LONGTEXT,
  `isFrozen` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
