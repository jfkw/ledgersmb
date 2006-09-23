--Hungarian chart of accounts 
-- Magyar f�k�nyvi sz�ml�k, amelyek csak p�ldak�nt szolg�lnak
--
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1140','Irodai eszk�z�k','A','A','','114');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1199','Irodai eszk�z�k �CS','A','A','','119');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2610','�ruk ','A','A','IC','261');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3110','Vev�k','A','A','AR','311');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3111','K�lf�ldi vev�k','A','A','AR','311');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3810','P�nzt�r 1','A','A','AR_paid:AP_paid','381');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3811','P�nzt�r 2','A','A','AR_paid:AP_paid','381');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3840','Bank 1','A','A','AR_paid:AP_paid','384');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3841','Bank 2','A','A','AR_paid:AP_paid','384');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4540','Belf�ldi Sz�ll�t�k','A','L','AP','454');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4541','K�lf�ldi sz�ll�t�k','A','L','AP','454');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4660','Visszaig�nyelhet� �FA 25%','A','L','AP_tax:IC_taxpart:IC_taxservice','466');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4661','Visszaig�nyelhet� �FA 12%','A','L','AP_tax:IC_taxpart:IC_taxservice','466');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4662','Visszaig�nyelhet� �FA 5%','A','L','AP_tax:IC_taxpart:IC_taxservice','466');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4663','Visszaig�nyelhet� �FA ad�mentes','A','L','AP_tax:IC_taxpart:IC_taxservice','466');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4670','Fizetend� �FA 25%','A','L','AR_tax:IC_taxpart:IC_taxservice','467');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4671','Fizetend� �FA 15%','A','L','AR_tax:IC_taxpart:IC_taxservice','467');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4672','Fizetend� �FA 5%','A','L','AR_tax:IC_taxpart:IC_taxservice','467');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4673','Fizetend� �FA ad�mentes','A','L','AR_tax:IC_taxpart:IC_taxservice','467');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5200','B�rleti d�j','A','E','AP_amount','520');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5210','Telefon','A','E','AP_amount','521');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5990','K�lts�gek','A','E','IC_expense','599');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8140','Eladott �ruk beszerz�si �rt�ke','A','E','IC_cogs','814');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8700','�rfolyamvesztes�g','A','E','','870');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9110','Belf�ldi �rbev�tel','A','I','AR_amount:IC_sale:IC_income','911');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9111','K�lf�ldi �rbev�tel','A','I','AR_amount:IC_sale:IC_income','911');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9700','�rfolyamnyeres�g','A','I','','970');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1','BEFEKTETETT ESZK�Z�K','H','A','','1');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2','K�SZLETEK','H','A','','2');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3','K�VETEL�SEK','H','A','','3');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4','K�TELEZETTS�GEK','H','L','','4');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5','K�LTS�GEK','H','E','','5');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8','R�FORD�T�SOK','H','E','','8');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9','BEV�TELEK','H','I','','9');
--
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4660'),'0.25','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4661'),'0.15','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4662'),'0.05','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4663'),'0','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4670'),'0.25','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4671'),'0.15','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4672'),'0.05','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4673'),'0','');
--
UPDATE defaults SET inventory_accno_id = (SELECT id FROM chart WHERE accno = '2110'), income_accno_id = (SELECT id FROM chart WHERE accno = '9110'), expense_accno_id = (SELECT id FROM chart WHERE accno = '8140'), fxgain_accno_id = (SELECT id FROM chart WHERE accno = '9700'), fxloss_accno_id = (SELECT id FROM chart WHERE accno = '8700'), curr = 'HUF:EUR:USD', weightunit = 'kg';
