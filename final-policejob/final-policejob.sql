INSERT INTO `addon_account` (name, label, shared) VALUES
	('society_police', 'Police', 1)
;

INSERT INTO `datastore` (name, label, shared) VALUES
	('society_police', 'Police', 1)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
	('society_police', 'Police', 1)
;

INSERT INTO `jobs` (name, label) VALUES
	('police', 'Police')
;

INSERT INTO `job_grades` (`id`, `job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
(NULL, 'police', 0, 'recruit', 'Cadet', 1000, '{}', '{}'),
(NULL, 'police', 1, 'officer', 'Officier', 1500, '{}', '{}'),
(NULL, 'police', 2, 'sergeant', 'Sergent', 1700, '{}', '{}'),
(NULL, 'police', 3, 'sergeant', 'Sergent-Formateur', 1700, '{}', '{}'),
(NULL, 'police', 4, 'sergeant', 'Sergent-Chef', 1950, '{}', '{}'),
(NULL, 'police', 5, 'lieutenant', 'Lieutenant', 2000, '{}', '{}'),
(NULL, 'police', 6, 'lieutenant', 'Capitaine', 2500, '{}', '{}'),
(NULL, 'police', 7, 'boss', 'Commandant', 3999, '{}', '{}');

CREATE TABLE `adr` (
  `id` int(11) NOT NULL,
  `author` text NOT NULL,
  `date` text NOT NULL,
  `firstname` text NOT NULL,
  `lastname` text NOT NULL,
  `reason` text NOT NULL,
  `dangerosity` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `adr`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `adr`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

CREATE TABLE `cj` (
  `id` int(11) NOT NULL,
  `author` text NOT NULL,
  `date` text NOT NULL,
  `firstname` text NOT NULL,
  `lastname` text NOT NULL,
  `reason` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `cj`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `cj`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;
COMMIT;
