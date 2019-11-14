
alter table Implementation add column datelastupdate timestamp;

alter table Contract add column  datelastupdate timestamp;

alter table Award add column  datelastupdate timestamp;

alter table ContractingProcess add column awardstatus text,
                               add column contractstatus text,
                               add column implementationstatus text;

CREATE TABLE item
(
  id serial primary key,
  classificationid text NOT NULL,
  description text NOT NULL,
  unit text
);


CREATE TABLE metadata
(
    field_name character varying(50) NOT NULL,
    value text,
    CONSTRAINT pk_metadata_id PRIMARY KEY (field_name)
);


CREATE TABLE prefixocid
(
  id serial primary key,
  value text
);
-----------------------------------------

ALTER TABLE awardamendmentchanges ADD COLUMN amendments_date timestamp, ADD COLUMN amendments_rationale text, ADD COLUMN amendments_id text, ADD COLUMN amendments_description text;
ALTER TABLE tenderamendmentchanges ADD COLUMN amendments_date timestamp, ADD COLUMN amendments_rationale text, ADD COLUMN amendments_id text, ADD COLUMN amendments_description text;

ALTER TABLE awarditem ADD COLUMN latitude double precision, ADD COLUMN longitude double precision;
ALTER TABLE contractitem ADD COLUMN latitude double precision, ADD COLUMN longitude double precision;
ALTER TABLE tenderitem ADD COLUMN latitude double precision, ADD COLUMN longitude double precision;

ALTER TABLE awarditem  add column location_postalcode text, add column location_countryname text, add column location_streetaddress text, add column location_region text, add column location_locality text;
ALTER TABLE contractitem  add column location_postalcode text, add column location_countryname text, add column location_streetaddress text, add column location_region text, add column location_locality text;
ALTER TABLE tenderitem add column location_postalcode text, add column location_countryname text, add column location_streetaddress text, add column location_region text, add column location_locality text;



create table DocumentType (
    id serial primary key,
    category text,
    code text,
    title text,
    title_esp text,
    description text,
    source text,
	  stage integer
);

DELETE FROM DocumentType;
INSERT INTO DocumentType(id, category, code, title, title_esp, description, source, stage) VALUES
(1,'intermediate','hearingNotice','Public Hearing Notice','Aviso de audiencia pública','Details of any public hearings that took place as part of the planning for this procurement.','',1),
(2,'advanced','feasibilityStudy','Feasibility study','Estudio de factibilidad','','',1),
(3,'advanced','assetAndLiabilityAssessment','Assesment of government’s assets and liabilities','Evaluación de los activos y responsabilidades del gobierno','','',1),
(4,'advanced','environmentalImpact','Environmental Impact','Impacto ambiental','','',1),
(5,'intermediate','marketStudies','Market Studies','Investigación de mercado','','',1),
(6,'advanced','needsAssessment','Needs Assessment','Justificación de la contratación','','',1),
(7,'advanced','projectPlan','Project plan','Plan de proyecto','','',1),
(8,'basic','procurementPlan','Procurement Plan','Proyecto de convocatoria','','',1),
(9,'intermediate','clarifications','Clarifications to bidders questions','Acta de junta de aclaraciones','Including replies to issues raised in pre-bid conferences.','',2),
(10,'basic','technicalSpecifications','Technical Specifications','Anexo técnico','Detailed technical information about goods or services to be provided.','',2),
(11,'basic','biddingDocuments','Bidding Documents','Anexos de la convocatoria','Information for potential suppliers, describing the goals of the contract (e.g. goods and services to be procured) and the bidding process.','',2),
(12,'advanced','riskProvisions','Provisions for management of risks and liabilities','Cláusulas de riesgos y responsabilidades','','',2),
(13,'advanced','conflictOfInterest','conflicts of interest uncovered','Conflicto de intereses','','',2),
(14,'basic','tenderNotice','Tender Notice','Convocatoria','The formal notice that gives details of a tender. This may be a link to a downloadable document, to a web page or to an official gazette in which the notice is contained.','',2),
(15,'intermediate','eligibilityCriteria','Eligibility Criteria','Criterios de elegibilidad','Detailed documents about the eligibility of bidders.','',2),
(16,'basic','evaluationCriteria','Evaluation Criteria','Criterios de evaluación','Information about how bids will be evaluated.','',2),
(17,'intermediate','shortlistedFirms','Shortlisted Firms','Empresas preseleccionadas','','',2),
(18,'advanced','billOfQuantity','Bill Of Quantity','Especificación de cantidades','','',2),
(19,'advanced','bidders','Information on bidders','Información del licitante','Information on bidders or participants,their validation documents and any procedural exemptions for which they qualify','',2),
(20,'advanced','debarments','debarments issued','Inhabilitaciones','','',2),
(21,'basic','awardNotice','Award Notice','Fallo o notificación de adjudicación','The formal notice that gives details of the contract award. This may be a link to a downloadable document,to a web page or to an official gazette in which the notice is contained.','',3),
(22,'advanced','winningBid','Winning Bid','Proposición ganadora','','',3),
(23,'advanced','complaints','Complaints and decisions','Quejas y aclaraciones','','',3),
(24,'intermediate','evaluationReports','Evaluation report','Reporte de resultado de la evaluación','Report on the evaluation of the bids and the application of the evaluation criteria, including the justification fo the award','',3),
(25,'intermediate','contractArrangements','Arrangements for ending contract','Acuerdos de terminación del contrato','','',4),
(26,'intermediate','contractSchedule','Schedules and milestones','Anexo del contrato','','',4),
(27,'advanced','contractAnnexe','Contract Annexe','Anexos del Contrato','','',4),
(28,'intermediate','contractSigned','Signed Contract','Contrato firmado','','',4),
(29,'basic','contractNotice','Contract Notice','Datos relevantes del contrato','The formal notice that gives details of a contract being signed and valid to start implementation. This may be a link to a downloadable document','',4),
(30,'advanced','contractGuarantees','Guarantees','Garantías del contrato','','',4),
(31,'advanced','subContract','Subcontracts','Subcontratos','A document detailing subcontracts, the subcontract itself or a linked OCDS document describing a subcontract.','',4),
(32,'basic','contractText','Contract Text','Texto del contrato','','',4),
(33,'intermediate','finalAudit','Final Audit','Conclusión de la auditoría','','',5),
(34,'basic','completionCertificate','Completion certificate','Documento en el que conste la conclusión de la contratación','','',5),
(35,'intermediate','financialProgressReport','Financial progress reports','Informe de avance financiero','Dates and amounts of stage payments made (against total amount) and the source of those payments, including cost overruns if any. Structured versions of this data can be provided through transactions.','',5),
(36,'intermediate','physicalProcessReport','Physical progress reports','Informe de avance físico','A report on the status of implementation, usually against key milestones.','',5);


ALTER TABLE tags ADD COLUMN stage integer, ADD COLUMN register_date timestamp;

ALTER TABLE tender ADD COLUMN procurementmethod_rationale_id text;

alter table contractingprocess add column published bool,
                               add column valid bool;



CREATE TABLE programaticstructure
(
  id serial primary key,
  cve text,
  year integer,
  trimester integer,
  branch text,
  branch_desc text,
  finality	 text,
  finality_desc text,
  function text, 
  function_desc text, 
  subfunction text,
  subfunction_desc text,
  institutionalactivity	 text,
  institutionalactivity_desc text,
  budgetprogram	 text,
  budgetprogram_desc text,
  strategicobjective text,
  strategicobjective_desc text,
  responsibleunit	 text,
  responsibleunit_desc text,
  requestingunit	text,
  requestingunit_desc text,
  spendingtype text,
  spendingtype_desc text,
  specificactivity text,
  specificactivity_desc text,
  spendingobject text,
  spendingobject_desc text,
  region text,
  region_desc text,
  budgetsource text,
  budgetsource_desc text,
  portfoliokey text,
  approvedamount decimal,
  modifiedamount decimal,
  executedamount decimal,
  committedamount decimal,
  reservedamount decimal
);

drop table if exists activitymir;

drop table if exists departure;


create table requestforquotes(
	id serial primary key,
	contractingprocess_id integer references contractingprocess(id) on delete cascade,
  planning_id integer,
  requestforquotes_id text,
	title text,
	description text,
	period_startdate timestamp,
	period_enddate timestamp
);

create table requestforquotesitems(
	id serial primary key,
	requestforquotes_id integer references requestforquotes(id) on delete cascade,
	itemid text,
  item text,
	quantity integer
);

create table requestforquotesinvitedsuppliers(
  id serial primary key,
  requestforquotes_id integer references requestforquotes(id) on delete cascade,
  parties_id integer references parties(id) on delete cascade
);


create table quotes(
  id serial primary key,
  requestforquotes_id integer references requestforquotes(id) on delete cascade,
  quotes_id text,
  description text,
  date timestamp,
  value decimal,
  quotePeriod_startdate timestamp,
  quotePeriod_enddate timestamp,
  issuingSupplier_id integer references parties(id) on delete cascade
);

create table quotesitems(
  id serial primary key,
  quotes_id integer references quotes(id) on delete cascade,
	itemid text,
  item text,
	quantity decimal
);

create table clarificationmeeting
(
  id serial primary key,
  clarificationmeetingid text,
  contractingprocess_id integer references contractingprocess(id) on delete cascade,
  date timestamp
);

create table clarificationmeetingactor
(
  id serial primary key,
  clarificationmeeting_id integer references clarificationmeeting(id) on delete cascade,
  parties_id integer references parties(id) on delete cascade,
  attender boolean,
  official boolean
);


CREATE TABLE guarantees
(
  id serial primary key,
  contractingprocess_id integer,
  contract_id integer,
  guarantee_id text,
  guaranteeType text,
  date timestamp,
  guaranteedObligations text,
  value decimal,
  guarantor integer,
  guaranteePeriod_startdate timestamp,
  guaranteePeriod_enddate timestamp
);

ALTER TABLE contract ADD COLUMN surveillanceMechanisms text;

ALTER TABLE parties ADD COLUMN contactpoint_type text, ADD COLUMN contactpoint_language text;


CREATE TABLE additionalContactPoints(
  id serial primary key,
  party_id integer,
  type text,
  name text,
  givenname text,
  surname text,
  additionalsurname text,
  email text,
  telephone text,
  faxnumber text,
  url text,
  language text
);


CREATE TABLE logs(
  id serial primary key,
  version text,
  update_date timestamp,
  publisher text,
  release_file text,
  release_json json,
  record_json json,
  contractingprocess_id integer
);

ALTER TABLE logs ADD COLUMN version_json json;


create table memberOf(
  id serial primary key,
  memberofid text,
  principal_parties_id integer references parties(id) on delete cascade,
  parties_id integer references parties(id) on delete cascade
);

alter table parties add column surname text,
                    add column additionalsurname text,
                    add column contactpoint_surname text,
                    add column contactpoint_additionalsurname text,
                    add column givenname text,
                    add column contactpoint_givenname text;


CREATE TABLE budgetbreakdown(
  id serial primary key,
  contractingprocess_id integer,
  planning_id integer,
  budgetbreakdown_id text,
  description text,
  amount decimal,
  currency text,
  url text,
  budgetbreakdownPeriod_startdate timestamp,
  budgetbreakdownPeriod_enddate timestamp,
  source_id integer
);


CREATE TABLE budgetclassifications(
  id serial primary key,
  budgetbreakdown_id integer,
  year integer,
  branch text,
  responsibleunit text,
  finality text,
  function text,
  subfunction text,
  institutionalactivity text,
  budgetprogram text,
  strategicobjective text,
  requestingunit text,
  specificactivity text,
  spendingobject text,
  spendingtype text,
  budgetsource text,
  region text,
  portfoliokey text,
  cve text
); 


ALTER TABLE budgetclassifications
ADD COLUMN approved DECIMAL,
ADD COLUMN modified DECIMAL,
ADD COLUMN executed DECIMAL,
ADD COLUMN committed DECIMAL,
ADD COLUMN reserved DECIMAL;

ALTER TABLE award DROP COLUMN IF EXISTS supplier_name, 
                  DROP COLUMN IF EXISTS supplier_id;


create table awardsupplier(
  id serial primary key,
  award_id integer references award(id) on delete cascade,
  parties_id integer references parties(id) on delete cascade
);

drop table if exists administrativeunit;

alter table contractingprocess add column date_published timestamp;


CREATE TABLE relatedprocedure(
  id serial primary key,
  contractingprocess_id integer,
  relatedprocedure_id text,
  relationship_type text,
  title text,
  identifier_scheme text,
  relatedprocedure_identifier text,
  url text
);



CREATE TABLE documentmanagement(
  id serial primary key,
  contractingprocess_id integer,
  origin text,
  document text,
  instance_id text,
  type text,
  register_date timestamp
);



CREATE TABLE pntreference(
  id serial primary key,
  contractingprocess_id integer,
  contractid text,
  format integer,
  record_id text,
  position integer,
  field_id integer,
  reference_id integer,
  date timestamp,
  isroot boolean,
  error text
);

-- agregado 13-feb
alter table guarantees add column currency text;


-- agregado 11-abril
create table gdmx_dictionary(
  id serial primary key,
  document text,
  variable text, 
  tablename text, 
  field text,
  parent text, 
  type text, 
  index integer, 
  classification text, 
  catalog text, 
  catalog_field text
);


create table gdmx_document(
  id serial primary key,
  name text, 
  stage integer, 
  type text, 
  tablename text, 
  identifier text,
  title text,
  description text,
  format text,
  language text 
);

-- 18 junio
alter table gdmx_dictionary add column  storeprocedure text;
alter table logs add column published boolean;

alter table contractingprocess add column publisher text;
alter table contractingprocess add column updated boolean;
alter table contractingprocess add column updated_date timestamp;
alter table contractingprocess add column updated_version text;
alter table contractingprocess add column published_version text;
alter table contractingprocess add column pnt_published boolean;
alter table contractingprocess add column pnt_version text;
alter table contractingprocess add column pnt_date timestamp;

-- tabla de prueba
drop table if exists log_gdmx;
create table log_gdmx(
  id serial primary key,
  date timestamp,
  cp int,
  recordid int,
  record json
);

-- funcion de prueba
drop function if exists sp_test_gdmx(cp int, id int, record json);
create function sp_test_gdmx(cp int, id int, record json)
returns void
AS $$
BEGIN
  INSERT INTO log_gdmx(date, cp, recordid, record)
  VALUES(now(), cp, id,record);
  return;
end; $$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public.clone_schema(
	source_schema text,
	dest_schema text)
RETURNS void AS
$BODY$
DECLARE
object text;
buffer text;
default_ text;
column_ text;
constraint_name_ text;
constraint_def_ text;
trigger_name_ text; 
trigger_timing_ text; 
trigger_events_ text; 
trigger_orientation_ text;
trigger_action_ text;
owner_ text := 'prueba_dashboard';
BEGIN
	-- replace existing schema
	EXECUTE 'DROP SCHEMA IF EXISTS ' || dest_schema || ' CASCADE';
	-- create schema
	EXECUTE 'CREATE SCHEMA ' || dest_schema || ' AUTHORIZATION ' || owner_ ;
	-- create sequences
	FOR object IN
		SELECT sequence_name::text FROM information_schema.SEQUENCES WHERE sequence_schema = source_schema
		LOOP
			EXECUTE 'CREATE SEQUENCE ' || dest_schema || '.' || object;
END LOOP;

-- create tables
FOR object IN
	SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema
	LOOP
		buffer := dest_schema || '.' || object;
		-- create table
		EXECUTE 'CREATE TABLE ' || buffer || ' (LIKE ' || source_schema || '.' || object || ' INCLUDING CONSTRAINTS INCLUDING INDEXES INCLUDING DEFAULTS)';
		-- fix sequence defaults
		FOR column_, default_ IN
			SELECT column_name::text, REPLACE(column_default::text, source_schema||'.', dest_schema||'.') FROM information_schema.COLUMNS WHERE table_schema = dest_schema AND table_name = object AND column_default LIKE 'nextval(%' || source_schema || '.%::regclass)'
			LOOP
				EXECUTE 'ALTER TABLE ' || buffer || ' ALTER COLUMN ' || column_ || ' SET DEFAULT ' || default_;
      END LOOP;
  -- create triggers
  FOR trigger_name_, trigger_timing_, trigger_events_, trigger_orientation_, trigger_action_ IN
    SELECT trigger_name::text, action_timing::text, string_agg(event_manipulation::text, ' OR '), action_orientation::text, action_statement::text FROM information_schema.TRIGGERS WHERE event_object_schema=source_schema and event_object_table=object GROUP BY trigger_name, action_timing, action_orientation, action_statement
      LOOP
        EXECUTE 'CREATE TRIGGER ' || trigger_name_ || ' ' || trigger_timing_ || ' ' || trigger_events_ || ' ON ' || buffer || ' FOR EACH ' || trigger_orientation_ || ' ' || trigger_action_;
    END LOOP;
END LOOP;
-- reiterate tables and create foreign keys
FOR object IN
	SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema
	LOOP
		buffer := dest_schema || '.' || object;
		-- create foreign keys
		FOR constraint_name_, constraint_def_ IN
			SELECT conname::text, 
      CASE WHEN position( source_schema||'.' in pg_get_constraintdef(pg_constraint.oid)) = 0 THEN 
		  	REPLACE(pg_get_constraintdef(pg_constraint.oid), 'REFERENCES ', 'REFERENCES '|| dest_schema ||'.') 
        ELSE
        REPLACE(pg_get_constraintdef(pg_constraint.oid), source_schema ||'.', dest_schema||'.')
  	  END
      FROM pg_constraint INNER JOIN pg_class ON conrelid=pg_class.oid INNER JOIN pg_namespace ON pg_namespace.oid=pg_class.relnamespace WHERE contype='f' and relname=object and nspname=source_schema
			LOOP
				EXECUTE 'ALTER TABLE '|| buffer ||' ADD CONSTRAINT '|| constraint_name_ ||' '|| constraint_def_;
      END LOOP;
  EXECUTE 'ALTER TABLE ' || buffer || ' OWNER TO ' || owner_;
  END LOOP;
END;

$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

update contractingprocess set pnt_version = null,published_version=null,updated=true; 

-- 20 sep
alter table documentmanagement add column error text;