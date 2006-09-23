-- General French-Canadian (AKA Qu�b�cois) COA
-- sample only

-- translated and adapted from the General Canadian COA, with the help
-- of the Grand Dictionnaire Terminologique:
-- http://granddictionnaire.com/

-- Some provisions have been made for Qu�bec-specifics, namely:
-- TVQ/TPS terminology, CSST, Assurance-emploi, RRQ

INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1060', 'Compte ch�que', 'A', 'A', 'AR_paid:AP_paid', '1002');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1065', 'Petite caisse', 'A', 'A', 'AR_paid:AP_paid', '1001');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1500', 'STOCKS', 'H', 'A', '', '1120');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1200', 'Comptes clients', 'A', 'A', 'AR', '1060');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1530', 'Stocks / Pi�ces de rechange', 'A', 'A', 'IC', '1122');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1540', 'Stocks / Mati�res premi�res', 'A', 'A', 'IC', '1122');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1800', 'AUTRES IMMOBILISATIONS', 'H', 'A', '', '1900');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1820', 'Meubles et accessoires', 'A', 'A', '', '1787');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno,contra) VALUES ('1825', 'Amortissement cumul� des meubles et des accessoires', 'A', 'A', '', '1788', '1');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1840', 'V�hicules automobiles', 'A', 'A', '', '1742');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno,contra) VALUES ('1845', 'Amortissement cumul� des v�hicules automobiles', 'A', 'A', '', '1743', '1');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2100', 'Comptes fournisseurs', 'A', 'L', 'AP', '2621');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1000', 'ACTIF COURANT', 'H', 'A', '', '1000');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2000', 'PASSIF COURANT', 'H', 'L', '', '2620');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2160', 'Taxes f�d�rales � payer', 'A', 'L', '', '2683');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2170', 'Taxes provinciales � payer', 'A', 'L', '', '2684');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2310', 'TPS', 'A', 'L', 'AR_tax:AP_tax:IC_taxpart:IC_taxservice', '2685');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2320', 'TVQ', 'A', 'L', 'AR_tax:AP_tax:IC_taxpart:IC_taxservice', '2686');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2380', 'Indemnit�s de vacances � payer', 'A', 'L', '', '2624');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2390', 'CSST � payer', 'A', 'L', '', '2627');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2400', 'RETENUES SUR SALAIRE', 'H', 'L', '', '2620');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1520', 'Stocks / G�n�ral', 'A', 'A', 'IC', '1122');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2410', 'Assurance-emploi � payer', 'A', 'L', '', '2627');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2450', 'Imp�t sur le revenu � payer', 'A', 'L', '', '2628');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2600', 'PASSIF � LONG TERME', 'H', 'L', '', '3140');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2620', 'Emprunts bancaires', 'A', 'L', '', '2701');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3300', 'CAPITAL SOCIAL', 'H', 'Q', '', '3500');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3350', 'Actions ordinaires', 'A', 'Q', '', '3500');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4000', 'REVENUS DE VENTE', 'H', 'I', '', '8000');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4020', 'Ventes g�n�rales', 'A', 'I', 'AR_amount:IC_sale:IC_income', '8000');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4030', 'Pi�ces de rechange', 'A', 'I', 'AR_amount:IC_sale', '8000');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4400', 'AUTRES REVENUS', 'H', 'I', '', '8090');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4430', 'Transport et manutention', 'A', 'I', 'IC_income', '8457');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4450', 'Gain sur change', 'A', 'I', '', '8231');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5000', 'CO�T DES PRODUITS VENDUS', 'H', 'E', '', '8515');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5010', 'Achats', 'A', 'E', 'AP_amount:IC_cogs:IC_expense', '8320');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5050', 'Pi�ces de rechange', 'A', 'E', 'AP_amount:IC_cogs', '8320');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5100', 'Frais de transport', 'A', 'E', 'AP_amount:IC_expense', '8457');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5400', 'FRAIS DE PERSONNEL', 'H', 'E', '', '');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5410', 'Salaires', 'A', 'E', '', '9060');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5420', 'D�penses d''assurance-emploi', 'A', 'E', '', '8622');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2420', 'RRQ � payer', 'A', 'L', '', '2627');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5430', 'D�penses RRQ', 'A', 'E', '', '8622');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5440', 'D�penses CSST', 'A', 'E', '', '8622');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5600', 'D�PENSES ADMINISTRATIVES ET G�N�RALES', 'H', 'E', '', '');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5615', 'Publicit� et promotion', 'A', 'E', 'AP_amount', '8520');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5620', 'Cr�ances irr�vocables', 'A', 'E', '', '8590');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5660', 'Amortissement de l''exercice', 'A', 'E', '', '8670');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5680', 'Imp�t sur le revenu', 'A', 'E', '', '9990');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5685', 'Assurances', 'A', 'E', 'AP_amount', '9804');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5690', 'Int�r�ts et frais bancaires', 'A', 'E', '', '9805');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5700', 'Fournitures de bureau', 'A', 'E', 'AP_amount', '8811');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5760', 'Loyer', 'A', 'E', 'AP_amount', '9811');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5780', 'T�l�phone', 'A', 'E', 'AP_amount', '9225');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5785', 'Voyages et loisirs', 'A', 'E', '', '8523');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5790', 'Services publics', 'A', 'E', 'AP_amount', '8812');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5810', 'Perte sur change', 'A', 'E', '', '8231');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1205', 'Provisions pour cr�ances douteuses', 'A', 'A', '', '1063');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2680', 'Emprunt aupr�s des actionnaires', 'A', 'L', 'AP_paid', '2780');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5610', 'Frais comptables et juridiques', 'A', 'E', 'AP_amount', '8862');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4440', 'Int�r�ts', 'A', 'I', 'IC_income', '8090');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5765', 'R�paration et entretien', 'A', 'E', 'AP_amount', '8964');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5800', 'Taxes d''affaires, droits d''adh�sion et permis', 'A', 'E', 'AP_amount', '8760');
--
insert into tax (chart_id,rate) values ((select id from chart where accno = '2310'),0.07);
insert into tax (chart_id,rate) values ((select id from chart where accno = '2320'),0.08025);
--
update defaults set inventory_accno_id = (select id from chart where accno = '1520'), income_accno_id = (select id from chart where accno = '4020'), expense_accno_id = (select id from chart where accno = '5010'), fxgain_accno_id = (select id from chart where accno = '4450'), fxloss_accno_id = (select id from chart where accno = '4450'), curr = 'CAD:USD:EUR', weightunit = 'kg';
