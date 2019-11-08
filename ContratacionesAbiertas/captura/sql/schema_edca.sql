--
-- PostgreSQL database dump
--

-- Dumped from database version 10.10
-- Dumped by pg_dump version 10.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: clone_schema(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.clone_schema(source_schema text, dest_schema text) RETURNS void
    LANGUAGE plpgsql
    AS $$
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

$$;


--
-- Name: sp_test_gdmx(integer, integer, json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sp_test_gdmx(cp integer, id integer, record json) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO log_gdmx(date, cp, recordid, record)
  VALUES(now(), cp, id,record);
  return;
end; $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: additionalcontactpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.additionalcontactpoints (
    id integer NOT NULL,
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


--
-- Name: additionalcontactpoints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.additionalcontactpoints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: additionalcontactpoints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.additionalcontactpoints_id_seq OWNED BY public.additionalcontactpoints.id;


CREATE TABLE public.award (
    id integer NOT NULL,
    contractingprocess_id integer,
    awardid text,
    title text,
    description text,
    rationale text,
    status text,
    award_date timestamp without time zone,
    value_amount numeric,
    value_currency text,
    contractperiod_startdate timestamp without time zone,
    contractperiod_enddate timestamp without time zone,
    amendment_date timestamp without time zone,
    amendment_rationale text,
    value_amountnet numeric,
    datelastupdate timestamp without time zone
);


--
-- Name: award_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.award_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: award_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.award_id_seq OWNED BY public.award.id;


--
-- Name: awardamendmentchanges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.awardamendmentchanges (
    id integer NOT NULL,
    contractingprocess_id integer,
    award_id integer,
    property text,
    former_value text,
    amendments_date timestamp without time zone,
    amendments_rationale text,
    amendments_id text,
    amendments_description text
);


--
-- Name: awardamendmentchanges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.awardamendmentchanges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: awardamendmentchanges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.awardamendmentchanges_id_seq OWNED BY public.awardamendmentchanges.id;


--
-- Name: awarddocuments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.awarddocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    award_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


--
-- Name: awarddocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.awarddocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: awarddocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.awarddocuments_id_seq OWNED BY public.awarddocuments.id;


--
-- Name: awarditem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.awarditem (
    id integer NOT NULL,
    contractingprocess_id integer,
    award_id integer,
    itemid text,
    description text,
    classification_scheme text,
    classification_id text,
    classification_description text,
    classification_uri text,
    quantity integer,
    unit_name text,
    unit_value_amount numeric,
    unit_value_currency text,
    unit_value_amountnet numeric,
    latitude double precision,
    longitude double precision,
    location_postalcode text,
    location_countryname text,
    location_streetaddress text,
    location_region text,
    location_locality text
);


--
-- Name: awarditem_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.awarditem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: awarditem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.awarditem_id_seq OWNED BY public.awarditem.id;


--
-- Name: awarditemadditionalclassifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.awarditemadditionalclassifications (
    id integer NOT NULL,
    award_id integer,
    awarditem_id integer,
    scheme text,
    description text,
    uri text
);


--
-- Name: awarditemadditionalclassifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.awarditemadditionalclassifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: awarditemadditionalclassifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.awarditemadditionalclassifications_id_seq OWNED BY public.awarditemadditionalclassifications.id;


--
-- Name: awardsupplier; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.awardsupplier (
    id integer NOT NULL,
    award_id integer,
    parties_id integer
);


--
-- Name: awardsupplier_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.awardsupplier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: awardsupplier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.awardsupplier_id_seq OWNED BY public.awardsupplier.id;


--
-- Name: budget; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budget (
    id integer NOT NULL,
    contractingprocess_id integer,
    planning_id integer,
    budget_source text,
    budget_budgetid text,
    budget_description text,
    budget_amount numeric,
    budget_currency text,
    budget_project text,
    budget_projectid text,
    budget_uri text
);


--
-- Name: budget_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.budget_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: budget_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.budget_id_seq OWNED BY public.budget.id;


--
-- Name: budgetbreakdown; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budgetbreakdown (
    id integer NOT NULL,
    contractingprocess_id integer,
    planning_id integer,
    budgetbreakdown_id text,
    description text,
    amount numeric,
    currency text,
    url text,
    budgetbreakdownperiod_startdate timestamp without time zone,
    budgetbreakdownperiod_enddate timestamp without time zone,
    source_id integer
);


--
-- Name: budgetbreakdown_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.budgetbreakdown_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: budgetbreakdown_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.budgetbreakdown_id_seq OWNED BY public.budgetbreakdown.id;



--
-- Name: budgetclassifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budgetclassifications (
    id integer NOT NULL,
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
    cve text,
    approved numeric,
    modified numeric,
    executed numeric,
    committed numeric,
    reserved numeric
);


--
-- Name: budgetclassifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.budgetclassifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: budgetclassifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.budgetclassifications_id_seq OWNED BY public.budgetclassifications.id;


--
-- Name: clarificationmeeting; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clarificationmeeting (
    id integer NOT NULL,
    clarificationmeetingid text,
    contractingprocess_id integer,
    date timestamp without time zone
);


--
-- Name: clarificationmeeting_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clarificationmeeting_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clarificationmeeting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clarificationmeeting_id_seq OWNED BY public.clarificationmeeting.id;


--
-- Name: clarificationmeetingactor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clarificationmeetingactor (
    id integer NOT NULL,
    clarificationmeeting_id integer,
    parties_id integer,
    attender boolean,
    official boolean
);


--
-- Name: clarificationmeetingactor_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clarificationmeetingactor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clarificationmeetingactor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clarificationmeetingactor_id_seq OWNED BY public.clarificationmeetingactor.id;


--
-- Name: contract; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contract (
    id integer NOT NULL,
    contractingprocess_id integer,
    awardid text,
    contractid text,
    title text,
    description text,
    status text,
    period_startdate timestamp without time zone,
    period_enddate timestamp without time zone,
    value_amount numeric,
    value_currency text,
    datesigned timestamp without time zone,
    amendment_date timestamp without time zone,
    amendment_rationale text,
    value_amountnet numeric,
    exchangerate_rate numeric,
    exchangerate_amount numeric DEFAULT 0,
    exchangerate_currency text,
    exchangerate_date timestamp without time zone,
    exchangerate_source text,
    datelastupdate timestamp without time zone,
    surveillancemechanisms text
);


--
-- Name: contract_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contract_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contract_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contract_id_seq OWNED BY public.contract.id;



--
-- Name: contractamendmentchanges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contractamendmentchanges (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    amendments_date timestamp without time zone,
    amendments_rationale text,
    amendments_id text,
    amendments_description text
);


--
-- Name: contractamendmentchanges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contractamendmentchanges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contractamendmentchanges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contractamendmentchanges_id_seq OWNED BY public.contractamendmentchanges.id;


--
-- Name: contractdocuments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contractdocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


--
-- Name: contractdocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contractdocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contractdocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contractdocuments_id_seq OWNED BY public.contractdocuments.id;


--
-- Name: contractingprocess; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contractingprocess (
    id integer NOT NULL,
    ocid text,
    description text,
    destino text,
    fecha_creacion date,
    hora_creacion time without time zone,
    stage integer,
    uri text,
    publicationpolicy text,
    license text,
    awardstatus text,
    contractstatus text,
    implementationstatus text,
    published boolean,
    valid boolean,
    date_published timestamp without time zone,
    requirepntupdate boolean,
    pnt_dateupdate timestamp without time zone,
    publisher text,
    updated boolean,
    updated_date timestamp without time zone,
    updated_version text,
    published_version text,
    pnt_published boolean,
    pnt_version text,
    pnt_date timestamp without time zone
);


--
-- Name: contractingprocess_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contractingprocess_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contractingprocess_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contractingprocess_id_seq OWNED BY public.contractingprocess.id;


--
-- Name: contractitem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contractitem (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    itemid text,
    description text,
    classification_scheme text,
    classification_id text,
    classification_description text,
    classification_uri text,
    quantity integer,
    unit_name text,
    unit_value_amount numeric,
    unit_value_currency text,
    unit_value_amountnet numeric,
    latitude double precision,
    longitude double precision,
    location_postalcode text,
    location_countryname text,
    location_streetaddress text,
    location_region text,
    location_locality text
);


--
-- Name: contractitem_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contractitem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contractitem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contractitem_id_seq OWNED BY public.contractitem.id;



--
-- Name: contractitemadditionalclasifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contractitemadditionalclasifications (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    contractitem_id integer,
    scheme text,
    description text,
    uri text
);


--
-- Name: contractitemadditionalclasifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contractitemadditionalclasifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contractitemadditionalclasifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contractitemadditionalclasifications_id_seq OWNED BY public.contractitemadditionalclasifications.id;


--
-- Name: currency; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.currency (
    id integer NOT NULL,
    entity text,
    currency text,
    currency_eng text,
    alphabetic_code text,
    numeric_code text,
    minor_unit text
);


--
-- Name: currency_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.currency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: currency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.currency_id_seq OWNED BY public.currency.id;



--
-- Name: documentformat; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documentformat (
    id integer NOT NULL,
    category text,
    name text,
    template text,
    reference text
);


--
-- Name: documentformat_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.documentformat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: documentformat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.documentformat_id_seq OWNED BY public.documentformat.id;


--
-- Name: documentmanagement; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documentmanagement (
    id integer NOT NULL,
    contractingprocess_id integer,
    origin text,
    document text,
    instance_id text,
    type text,
    register_date timestamp without time zone,
    error text
);


--
-- Name: documentmanagement_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.documentmanagement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: documentmanagement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.documentmanagement_id_seq OWNED BY public.documentmanagement.id;



--
-- Name: documenttype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documenttype (
    id integer NOT NULL,
    category text,
    code text,
    title text,
    title_esp text,
    description text,
    source text,
    stage integer
);


--
-- Name: documenttype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.documenttype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: documenttype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.documenttype_id_seq OWNED BY public.documenttype.id;


--
-- Name: gdmx_dictionary; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gdmx_dictionary (
    id integer NOT NULL,
    document text,
    variable text,
    tablename text,
    field text,
    parent text,
    type text,
    index integer,
    classification text,
    catalog text,
    catalog_field text,
    storeprocedure text
);


--
-- Name: gdmx_dictionary_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gdmx_dictionary_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gdmx_dictionary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gdmx_dictionary_id_seq OWNED BY public.gdmx_dictionary.id;



--
-- Name: gdmx_document; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gdmx_document (
    id integer NOT NULL,
    name text,
    stage integer,
    type text,
    tablename text,
    identifier text,
    title text,
    description text,
    language text,
    format text
);


--
-- Name: gdmx_document_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gdmx_document_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gdmx_document_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gdmx_document_id_seq OWNED BY public.gdmx_document.id;


--
-- Name: guarantees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.guarantees (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    guarantee_id text,
    guaranteetype text,
    date timestamp without time zone,
    guaranteedobligations text,
    value numeric,
    guarantor integer,
    guaranteeperiod_startdate timestamp without time zone,
    guaranteeperiod_enddate timestamp without time zone,
    currency text
);


--
-- Name: guarantees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.guarantees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: guarantees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.guarantees_id_seq OWNED BY public.guarantees.id;


--
-- Name: implementation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.implementation (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    status text,
    datelastupdate timestamp without time zone
);


--
-- Name: implementation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.implementation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: implementation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.implementation_id_seq OWNED BY public.implementation.id;


--
-- Name: implementationdocuments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.implementationdocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    implementation_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


--
-- Name: implementationdocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.implementationdocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: implementationdocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.implementationdocuments_id_seq OWNED BY public.implementationdocuments.id;


--
-- Name: implementationmilestone; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.implementationmilestone (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    implementation_id integer,
    milestoneid text,
    title text,
    description text,
    duedate timestamp without time zone,
    date_modified timestamp without time zone,
    status text,
    type text
);


--
-- Name: implementationmilestone_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.implementationmilestone_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: implementationmilestone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.implementationmilestone_id_seq OWNED BY public.implementationmilestone.id;


--
-- Name: implementationmilestonedocuments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.implementationmilestonedocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    implementation_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


--
-- Name: implementationmilestonedocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.implementationmilestonedocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: implementationmilestonedocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.implementationmilestonedocuments_id_seq OWNED BY public.implementationmilestonedocuments.id;


--
-- Name: implementationstatus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.implementationstatus (
    id integer NOT NULL,
    code text,
    title text,
    title_esp text,
    description text
);


--
-- Name: implementationstatus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.implementationstatus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: implementationstatus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.implementationstatus_id_seq OWNED BY public.implementationstatus.id;


--
-- Name: implementationtransactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.implementationtransactions (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    implementation_id integer,
    transactionid text,
    source text,
    implementation_date timestamp without time zone,
    value_amount numeric,
    value_currency text,
    payment_method text,
    uri text,
    payer_name text,
    payer_id text,
    payee_name text,
    payee_id text,
    value_amountnet numeric
);


--
-- Name: implementationtransactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.implementationtransactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: implementationtransactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.implementationtransactions_id_seq OWNED BY public.implementationtransactions.id;



--
-- Name: item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item (
    id integer NOT NULL,
    classificationid text NOT NULL,
    description text NOT NULL,
    unit text
);


--
-- Name: item_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.item_id_seq OWNED BY public.item.id;


--
-- Name: language; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.language (
    id integer NOT NULL,
    alpha2 character varying(2),
    name text
);


--
-- Name: language_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.language_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: language_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.language_id_seq OWNED BY public.language.id;



--
-- Name: links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.links (
    id integer NOT NULL,
    json text,
    xlsx text,
    pdf text,
    contractingprocess_id integer
);


--
-- Name: links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.links_id_seq OWNED BY public.links.id;



--
-- Name: log_gdmx; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.log_gdmx (
    id integer NOT NULL,
    date timestamp without time zone,
    cp integer,
    recordid integer,
    record json
);


--
-- Name: log_gdmx_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.log_gdmx_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: log_gdmx_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.log_gdmx_id_seq OWNED BY public.log_gdmx.id;


--
-- Name: logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.logs (
    id integer NOT NULL,
    version text,
    update_date timestamp without time zone,
    publisher text,
    release_file text,
    release_json json,
    record_json json,
    contractingprocess_id integer,
    version_json json,
    published boolean
);


--
-- Name: logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.logs_id_seq OWNED BY public.logs.id;



--
-- Name: memberof; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.memberof (
    id integer NOT NULL,
    memberofid text,
    principal_parties_id integer,
    parties_id integer
);


--
-- Name: memberof_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.memberof_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: memberof_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.memberof_id_seq OWNED BY public.memberof.id;


--
-- Name: milestonetype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.milestonetype (
    id integer NOT NULL,
    code text,
    title text,
    description text
);


--
-- Name: milestonetype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.milestonetype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: milestonetype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.milestonetype_id_seq OWNED BY public.milestonetype.id;


--
-- Name: parties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parties (
    contractingprocess_id integer,
    id integer NOT NULL,
    partyid text,
    name text,
    "position" text,
    identifier_scheme text,
    identifier_id text,
    identifier_legalname text,
    identifier_uri text,
    address_streetaddress text,
    address_locality text,
    address_region text,
    address_postalcode text,
    address_countryname text,
    contactpoint_name text,
    contactpoint_email text,
    contactpoint_telephone text,
    contactpoint_faxnumber text,
    contactpoint_url text,
    details text,
    naturalperson boolean,
    contactpoint_type text,
    contactpoint_language text,
    surname text,
    additionalsurname text,
    contactpoint_surname text,
    contactpoint_additionalsurname text,
    givenname text,
    contactpoint_givenname text
);


--
-- Name: parties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parties_id_seq OWNED BY public.parties.id;


--
-- Name: partiesadditionalidentifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.partiesadditionalidentifiers (
    id integer NOT NULL,
    contractingprocess_id integer,
    parties_id integer,
    scheme text,
    legalname text,
    uri text
);


--
-- Name: partiesadditionalidentifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.partiesadditionalidentifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: partiesadditionalidentifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.partiesadditionalidentifiers_id_seq OWNED BY public.partiesadditionalidentifiers.id;


--
-- Name: paymentmethod; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.paymentmethod (
    id integer NOT NULL,
    code text,
    title text,
    description text
);


--
-- Name: paymentmethod_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.paymentmethod_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: paymentmethod_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.paymentmethod_id_seq OWNED BY public.paymentmethod.id;


--
-- Name: planning; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.planning (
    id integer NOT NULL,
    contractingprocess_id integer,
    hasquotes boolean,
    rationale text
);


--
-- Name: planning_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.planning_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: planning_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.planning_id_seq OWNED BY public.planning.id;



--
-- Name: planningdocuments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.planningdocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    planning_id integer,
    documentid text,
    document_type text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


--
-- Name: planningdocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.planningdocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: planningdocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.planningdocuments_id_seq OWNED BY public.planningdocuments.id;


--
-- Name: pntreference; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pntreference (
    id integer NOT NULL,
    contractingprocess_id integer,
    contractid text,
    format integer,
    record_id text,
    "position" integer,
    field_id integer,
    reference_id integer,
    date timestamp without time zone,
    isroot boolean,
    error text
);


--
-- Name: pntreference_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pntreference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pntreference_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pntreference_id_seq OWNED BY public.pntreference.id;




--
-- Name: prefixocid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prefixocid (
    id integer NOT NULL,
    value text
);


--
-- Name: prefixocid_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prefixocid_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prefixocid_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prefixocid_id_seq OWNED BY public.prefixocid.id;



--
-- Name: programaticstructure; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programaticstructure (
    id integer NOT NULL,
    cve text,
    year integer,
    trimester integer,
    branch text,
    branch_desc text,
    finality text,
    finality_desc text,
    function text,
    function_desc text,
    subfunction text,
    subfunction_desc text,
    institutionalactivity text,
    institutionalactivity_desc text,
    budgetprogram text,
    budgetprogram_desc text,
    strategicobjective text,
    strategicobjective_desc text,
    responsibleunit text,
    responsibleunit_desc text,
    requestingunit text,
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
    approvedamount numeric,
    modifiedamount numeric,
    executedamount numeric,
    committedamount numeric,
    reservedamount numeric
);


--
-- Name: programaticstructure_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.programaticstructure_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: programaticstructure_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.programaticstructure_id_seq OWNED BY public.programaticstructure.id;



--
-- Name: publisher; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.publisher (
    id integer NOT NULL,
    contractingprocess_id integer,
    name text,
    scheme text,
    uid text,
    uri text
);


--
-- Name: publisher_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.publisher_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: publisher_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.publisher_id_seq OWNED BY public.publisher.id;


--
-- Name: quotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quotes (
    id integer NOT NULL,
    requestforquotes_id integer,
    quotes_id text,
    description text,
    date timestamp without time zone,
    value numeric,
    quoteperiod_startdate timestamp without time zone,
    quoteperiod_enddate timestamp without time zone,
    issuingsupplier_id integer
);


--
-- Name: quotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quotes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quotes_id_seq OWNED BY public.quotes.id;


--
-- Name: quotesitems; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quotesitems (
    id integer NOT NULL,
    quotes_id integer,
    itemid text,
    item text,
    quantity numeric
);


--
-- Name: quotesitems_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quotesitems_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quotesitems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quotesitems_id_seq OWNED BY public.quotesitems.id;



--
-- Name: relatedprocedure; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.relatedprocedure (
    id integer NOT NULL,
    contractingprocess_id integer,
    relatedprocedure_id text,
    relationship_type text,
    title text,
    identifier_scheme text,
    relatedprocedure_identifier text,
    url text
);


--
-- Name: relatedprocedure_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.relatedprocedure_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: relatedprocedure_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.relatedprocedure_id_seq OWNED BY public.relatedprocedure.id;


--
-- Name: requestforquotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requestforquotes (
    id integer NOT NULL,
    contractingprocess_id integer,
    planning_id integer,
    requestforquotes_id text,
    title text,
    description text,
    period_startdate timestamp without time zone,
    period_enddate timestamp without time zone
);


--
-- Name: requestforquotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.requestforquotes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: requestforquotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.requestforquotes_id_seq OWNED BY public.requestforquotes.id;


-- Name: requestforquotesinvitedsuppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requestforquotesinvitedsuppliers (
    id integer NOT NULL,
    requestforquotes_id integer,
    parties_id integer
);


--
-- Name: requestforquotesinvitedsuppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.requestforquotesinvitedsuppliers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: requestforquotesinvitedsuppliers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.requestforquotesinvitedsuppliers_id_seq OWNED BY public.requestforquotesinvitedsuppliers.id;


--
-- Name: requestforquotesitems; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requestforquotesitems (
    id integer NOT NULL,
    requestforquotes_id integer,
    itemid text,
    item text,
    quantity integer
);


--
-- Name: requestforquotesitems_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.requestforquotesitems_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: requestforquotesitems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.requestforquotesitems_id_seq OWNED BY public.requestforquotesitems.id;



--
-- Name: rolecatalog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rolecatalog (
    id integer NOT NULL,
    code text,
    title text,
    description text
);


--
-- Name: rolecatalog_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rolecatalog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rolecatalog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rolecatalog_id_seq OWNED BY public.rolecatalog.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    contractingprocess_id integer,
    parties_id integer,
    id integer NOT NULL,
    buyer boolean,
    procuringentity boolean,
    supplier boolean,
    tenderer boolean,
    enquirer boolean,
    payer boolean,
    payee boolean,
    reviewbody boolean,
    clarificationmeetingattendee boolean,
    clarificationmeetingofficial boolean,
    invitedsupplier boolean,
    issuingsupplier boolean,
    guarantor boolean
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;




--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id integer NOT NULL,
    contractingprocess_id integer,
    planning boolean,
    planningupdate boolean,
    tender boolean,
    tenderamendment boolean,
    tenderupdate boolean,
    tendercancellation boolean,
    award boolean,
    awardupdate boolean,
    awardcancellation boolean,
    contract boolean,
    contractupdate boolean,
    contractamendment boolean,
    implementation boolean,
    implementationupdate boolean,
    contracttermination boolean,
    compiled boolean,
    stage integer,
    register_date timestamp without time zone
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;



--
-- Name: tender; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tender (
    id integer NOT NULL,
    contractingprocess_id integer,
    tenderid text,
    title text,
    description text,
    status text,
    minvalue_amount numeric,
    minvalue_currency text,
    value_amount numeric,
    value_currency text,
    procurementmethod text,
    procurementmethod_details text,
    procurementmethod_rationale text,
    mainprocurementcategory text,
    additionalprocurementcategories text,
    awardcriteria text,
    awardcriteria_details text,
    submissionmethod text,
    submissionmethod_details text,
    tenderperiod_startdate timestamp without time zone,
    tenderperiod_enddate timestamp without time zone,
    enquiryperiod_startdate timestamp without time zone,
    enquiryperiod_enddate timestamp without time zone,
    hasenquiries boolean,
    eligibilitycriteria text,
    awardperiod_startdate timestamp without time zone,
    awardperiod_enddate timestamp without time zone,
    numberoftenderers integer,
    amendment_date timestamp without time zone,
    amendment_rationale text,
    procurementmethod_rationale_id text
);


--
-- Name: tender_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tender_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tender_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tender_id_seq OWNED BY public.tender.id;

--
-- Name: tenderamendmentchanges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenderamendmentchanges (
    id integer NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    property text,
    former_value text,
    amendments_date timestamp without time zone,
    amendments_rationale text,
    amendments_id text,
    amendments_description text
);


--
-- Name: tenderamendmentchanges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenderamendmentchanges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenderamendmentchanges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenderamendmentchanges_id_seq OWNED BY public.tenderamendmentchanges.id;


--
-- Name: tenderdocuments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenderdocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


--
-- Name: tenderdocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenderdocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenderdocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenderdocuments_id_seq OWNED BY public.tenderdocuments.id;



--
-- Name: tenderitem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenderitem (
    id integer NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    itemid text,
    description text,
    classification_scheme text,
    classification_id text,
    classification_description text,
    classification_uri text,
    quantity integer,
    unit_name text,
    unit_value_amount numeric,
    unit_value_currency text,
    unit_value_amountnet numeric,
    latitude double precision,
    longitude double precision,
    location_postalcode text,
    location_countryname text,
    location_streetaddress text,
    location_region text,
    location_locality text
);


--
-- Name: tenderitem_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenderitem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenderitem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenderitem_id_seq OWNED BY public.tenderitem.id;



--
-- Name: tenderitemadditionalclassifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenderitemadditionalclassifications (
    id integer NOT NULL,
    contractingprocess_id integer,
    tenderitem_id integer,
    scheme text,
    description text,
    uri text
);


--
-- Name: tenderitemadditionalclassifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenderitemadditionalclassifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenderitemadditionalclassifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenderitemadditionalclassifications_id_seq OWNED BY public.tenderitemadditionalclassifications.id;


--
-- Name: tendermilestone; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tendermilestone (
    id integer NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    milestoneid text,
    title text,
    description text,
    duedate timestamp without time zone,
    date_modified timestamp without time zone,
    status text,
    type text
);


--
-- Name: tendermilestone_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tendermilestone_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tendermilestone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tendermilestone_id_seq OWNED BY public.tendermilestone.id;



--
-- Name: tendermilestonedocuments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tendermilestonedocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    milestone_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


--
-- Name: tendermilestonedocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tendermilestonedocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tendermilestonedocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tendermilestonedocuments_id_seq OWNED BY public.tendermilestonedocuments.id;


--
-- Name: user_contractingprocess; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_contractingprocess (
    id integer NOT NULL,
    user_id text,
    contractingprocess_id integer
);


--
-- Name: user_contractingprocess_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_contractingprocess_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_contractingprocess_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_contractingprocess_id_seq OWNED BY public.user_contractingprocess.id;


--
-- Name: metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.metadata (
    field_name character varying(50) NOT NULL,
    value text
);


--
-- Name: additionalcontactpoints id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.additionalcontactpoints ALTER COLUMN id SET DEFAULT nextval('public.additionalcontactpoints_id_seq'::regclass);


--
-- Name: award id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.award ALTER COLUMN id SET DEFAULT nextval('public.award_id_seq'::regclass);


--
-- Name: awardamendmentchanges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awardamendmentchanges ALTER COLUMN id SET DEFAULT nextval('public.awardamendmentchanges_id_seq'::regclass);


--
-- Name: awarddocuments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarddocuments ALTER COLUMN id SET DEFAULT nextval('public.awarddocuments_id_seq'::regclass);


--
-- Name: awarditem id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarditem ALTER COLUMN id SET DEFAULT nextval('public.awarditem_id_seq'::regclass);


--
-- Name: awarditemadditionalclassifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarditemadditionalclassifications ALTER COLUMN id SET DEFAULT nextval('public.awarditemadditionalclassifications_id_seq'::regclass);


--
-- Name: awardsupplier id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awardsupplier ALTER COLUMN id SET DEFAULT nextval('public.awardsupplier_id_seq'::regclass);


--
-- Name: budget id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget ALTER COLUMN id SET DEFAULT nextval('public.budget_id_seq'::regclass);


--
-- Name: budgetbreakdown id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgetbreakdown ALTER COLUMN id SET DEFAULT nextval('public.budgetbreakdown_id_seq'::regclass);


--
-- Name: budgetclassifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgetclassifications ALTER COLUMN id SET DEFAULT nextval('public.budgetclassifications_id_seq'::regclass);


--
-- Name: clarificationmeeting id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clarificationmeeting ALTER COLUMN id SET DEFAULT nextval('public.clarificationmeeting_id_seq'::regclass);


--
-- Name: clarificationmeetingactor id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clarificationmeetingactor ALTER COLUMN id SET DEFAULT nextval('public.clarificationmeetingactor_id_seq'::regclass);


--
-- Name: contract id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contract ALTER COLUMN id SET DEFAULT nextval('public.contract_id_seq'::regclass);


--
-- Name: contractamendmentchanges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractamendmentchanges ALTER COLUMN id SET DEFAULT nextval('public.contractamendmentchanges_id_seq'::regclass);


--
-- Name: contractdocuments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractdocuments ALTER COLUMN id SET DEFAULT nextval('public.contractdocuments_id_seq'::regclass);


--
-- Name: contractingprocess id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractingprocess ALTER COLUMN id SET DEFAULT nextval('public.contractingprocess_id_seq'::regclass);


--
-- Name: contractitem id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitem ALTER COLUMN id SET DEFAULT nextval('public.contractitem_id_seq'::regclass);


--
-- Name: contractitemadditionalclasifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitemadditionalclasifications ALTER COLUMN id SET DEFAULT nextval('public.contractitemadditionalclasifications_id_seq'::regclass);


--
-- Name: currency id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency ALTER COLUMN id SET DEFAULT nextval('public.currency_id_seq'::regclass);


--
-- Name: documentformat id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentformat ALTER COLUMN id SET DEFAULT nextval('public.documentformat_id_seq'::regclass);


--
-- Name: documentmanagement id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentmanagement ALTER COLUMN id SET DEFAULT nextval('public.documentmanagement_id_seq'::regclass);


--
-- Name: documenttype id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documenttype ALTER COLUMN id SET DEFAULT nextval('public.documenttype_id_seq'::regclass);


--
-- Name: gdmx_dictionary id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gdmx_dictionary ALTER COLUMN id SET DEFAULT nextval('public.gdmx_dictionary_id_seq'::regclass);


--
-- Name: gdmx_document id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gdmx_document ALTER COLUMN id SET DEFAULT nextval('public.gdmx_document_id_seq'::regclass);


--
-- Name: guarantees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guarantees ALTER COLUMN id SET DEFAULT nextval('public.guarantees_id_seq'::regclass);


--
-- Name: implementation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementation ALTER COLUMN id SET DEFAULT nextval('public.implementation_id_seq'::regclass);


--
-- Name: implementationdocuments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationdocuments ALTER COLUMN id SET DEFAULT nextval('public.implementationdocuments_id_seq'::regclass);


--
-- Name: implementationmilestone id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestone ALTER COLUMN id SET DEFAULT nextval('public.implementationmilestone_id_seq'::regclass);


--
-- Name: implementationmilestonedocuments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestonedocuments ALTER COLUMN id SET DEFAULT nextval('public.implementationmilestonedocuments_id_seq'::regclass);


--
-- Name: implementationstatus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationstatus ALTER COLUMN id SET DEFAULT nextval('public.implementationstatus_id_seq'::regclass);


--
-- Name: implementationtransactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationtransactions ALTER COLUMN id SET DEFAULT nextval('public.implementationtransactions_id_seq'::regclass);


--
-- Name: item id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item ALTER COLUMN id SET DEFAULT nextval('public.item_id_seq'::regclass);


--
-- Name: language id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language ALTER COLUMN id SET DEFAULT nextval('public.language_id_seq'::regclass);


--
-- Name: links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links ALTER COLUMN id SET DEFAULT nextval('public.links_id_seq'::regclass);


--
-- Name: log_gdmx id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_gdmx ALTER COLUMN id SET DEFAULT nextval('public.log_gdmx_id_seq'::regclass);


--
-- Name: logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs ALTER COLUMN id SET DEFAULT nextval('public.logs_id_seq'::regclass);


--
-- Name: memberof id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberof ALTER COLUMN id SET DEFAULT nextval('public.memberof_id_seq'::regclass);


--
-- Name: milestonetype id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.milestonetype ALTER COLUMN id SET DEFAULT nextval('public.milestonetype_id_seq'::regclass);


--
-- Name: parties id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parties ALTER COLUMN id SET DEFAULT nextval('public.parties_id_seq'::regclass);


--
-- Name: partiesadditionalidentifiers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partiesadditionalidentifiers ALTER COLUMN id SET DEFAULT nextval('public.partiesadditionalidentifiers_id_seq'::regclass);


--
-- Name: paymentmethod id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paymentmethod ALTER COLUMN id SET DEFAULT nextval('public.paymentmethod_id_seq'::regclass);


--
-- Name: planning id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning ALTER COLUMN id SET DEFAULT nextval('public.planning_id_seq'::regclass);


--
-- Name: planningdocuments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planningdocuments ALTER COLUMN id SET DEFAULT nextval('public.planningdocuments_id_seq'::regclass);


--
-- Name: pntreference id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pntreference ALTER COLUMN id SET DEFAULT nextval('public.pntreference_id_seq'::regclass);


--
-- Name: prefixocid id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prefixocid ALTER COLUMN id SET DEFAULT nextval('public.prefixocid_id_seq'::regclass);


--
-- Name: programaticstructure id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programaticstructure ALTER COLUMN id SET DEFAULT nextval('public.programaticstructure_id_seq'::regclass);


--
-- Name: publisher id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publisher ALTER COLUMN id SET DEFAULT nextval('public.publisher_id_seq'::regclass);


--
-- Name: quotes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes ALTER COLUMN id SET DEFAULT nextval('public.quotes_id_seq'::regclass);


--
-- Name: quotesitems id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotesitems ALTER COLUMN id SET DEFAULT nextval('public.quotesitems_id_seq'::regclass);


--
-- Name: relatedprocedure id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relatedprocedure ALTER COLUMN id SET DEFAULT nextval('public.relatedprocedure_id_seq'::regclass);


--
-- Name: requestforquotes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotes ALTER COLUMN id SET DEFAULT nextval('public.requestforquotes_id_seq'::regclass);


--
-- Name: requestforquotesinvitedsuppliers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotesinvitedsuppliers ALTER COLUMN id SET DEFAULT nextval('public.requestforquotesinvitedsuppliers_id_seq'::regclass);


--
-- Name: requestforquotesitems id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotesitems ALTER COLUMN id SET DEFAULT nextval('public.requestforquotesitems_id_seq'::regclass);


--
-- Name: rolecatalog id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rolecatalog ALTER COLUMN id SET DEFAULT nextval('public.rolecatalog_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: tender id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tender ALTER COLUMN id SET DEFAULT nextval('public.tender_id_seq'::regclass);


--
-- Name: tenderamendmentchanges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderamendmentchanges ALTER COLUMN id SET DEFAULT nextval('public.tenderamendmentchanges_id_seq'::regclass);


--
-- Name: tenderdocuments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderdocuments ALTER COLUMN id SET DEFAULT nextval('public.tenderdocuments_id_seq'::regclass);


--
-- Name: tenderitem id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderitem ALTER COLUMN id SET DEFAULT nextval('public.tenderitem_id_seq'::regclass);


--
-- Name: tenderitemadditionalclassifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderitemadditionalclassifications ALTER COLUMN id SET DEFAULT nextval('public.tenderitemadditionalclassifications_id_seq'::regclass);


--
-- Name: tendermilestone id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestone ALTER COLUMN id SET DEFAULT nextval('public.tendermilestone_id_seq'::regclass);


--
-- Name: tendermilestonedocuments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestonedocuments ALTER COLUMN id SET DEFAULT nextval('public.tendermilestonedocuments_id_seq'::regclass);


--
-- Name: user_contractingprocess id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_contractingprocess ALTER COLUMN id SET DEFAULT nextval('public.user_contractingprocess_id_seq'::regclass);


--
-- Name: additionalcontactpoints additionalcontactpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.additionalcontactpoints
    ADD CONSTRAINT additionalcontactpoints_pkey PRIMARY KEY (id);


--
-- Name: award award_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.award
    ADD CONSTRAINT award_pkey PRIMARY KEY (id);


--
-- Name: awardamendmentchanges awardamendmentchanges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awardamendmentchanges
    ADD CONSTRAINT awardamendmentchanges_pkey PRIMARY KEY (id);


--
-- Name: awarddocuments awarddocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarddocuments
    ADD CONSTRAINT awarddocuments_pkey PRIMARY KEY (id);


--
-- Name: awarditem awarditem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarditem
    ADD CONSTRAINT awarditem_pkey PRIMARY KEY (id);


--
-- Name: awarditemadditionalclassifications awarditemadditionalclassifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarditemadditionalclassifications
    ADD CONSTRAINT awarditemadditionalclassifications_pkey PRIMARY KEY (id);


--
-- Name: awardsupplier awardsupplier_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awardsupplier
    ADD CONSTRAINT awardsupplier_pkey PRIMARY KEY (id);


--
-- Name: budget budget_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget
    ADD CONSTRAINT budget_pkey PRIMARY KEY (id);


--
-- Name: budgetbreakdown budgetbreakdown_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgetbreakdown
    ADD CONSTRAINT budgetbreakdown_pkey PRIMARY KEY (id);


--
-- Name: budgetclassifications budgetclassifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgetclassifications
    ADD CONSTRAINT budgetclassifications_pkey PRIMARY KEY (id);


--
-- Name: clarificationmeeting clarificationmeeting_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clarificationmeeting
    ADD CONSTRAINT clarificationmeeting_pkey PRIMARY KEY (id);


--
-- Name: clarificationmeetingactor clarificationmeetingactor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clarificationmeetingactor
    ADD CONSTRAINT clarificationmeetingactor_pkey PRIMARY KEY (id);


--
-- Name: contract contract_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contract
    ADD CONSTRAINT contract_pkey PRIMARY KEY (id);


--
-- Name: contractamendmentchanges contractamendmentchanges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractamendmentchanges
    ADD CONSTRAINT contractamendmentchanges_pkey PRIMARY KEY (id);


--
-- Name: contractdocuments contractdocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractdocuments
    ADD CONSTRAINT contractdocuments_pkey PRIMARY KEY (id);


--
-- Name: contractingprocess contractingprocess_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractingprocess
    ADD CONSTRAINT contractingprocess_pkey PRIMARY KEY (id);


--
-- Name: contractitem contractitem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitem
    ADD CONSTRAINT contractitem_pkey PRIMARY KEY (id);


--
-- Name: contractitemadditionalclasifications contractitemadditionalclasifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitemadditionalclasifications
    ADD CONSTRAINT contractitemadditionalclasifications_pkey PRIMARY KEY (id);


--
-- Name: currency currency_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency
    ADD CONSTRAINT currency_pkey PRIMARY KEY (id);


--
-- Name: documentformat documentformat_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentformat
    ADD CONSTRAINT documentformat_pkey PRIMARY KEY (id);


--
-- Name: documentmanagement documentmanagement_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentmanagement
    ADD CONSTRAINT documentmanagement_pkey PRIMARY KEY (id);


--
-- Name: documenttype documenttype_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documenttype
    ADD CONSTRAINT documenttype_code_key UNIQUE (code);


--
-- Name: documenttype documenttype_code_key1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documenttype
    ADD CONSTRAINT documenttype_code_key1 UNIQUE (code);


--
-- Name: documenttype documenttype_code_key2; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documenttype
    ADD CONSTRAINT documenttype_code_key2 UNIQUE (code);


--
-- Name: documenttype documenttype_code_key3; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documenttype
    ADD CONSTRAINT documenttype_code_key3 UNIQUE (code);


--
-- Name: documenttype documenttype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documenttype
    ADD CONSTRAINT documenttype_pkey PRIMARY KEY (id);


--
-- Name: gdmx_dictionary gdmx_dictionary_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gdmx_dictionary
    ADD CONSTRAINT gdmx_dictionary_pkey PRIMARY KEY (id);


--
-- Name: gdmx_document gdmx_document_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gdmx_document
    ADD CONSTRAINT gdmx_document_pkey PRIMARY KEY (id);


--
-- Name: guarantees guarantees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guarantees
    ADD CONSTRAINT guarantees_pkey PRIMARY KEY (id);


--
-- Name: implementation implementation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementation
    ADD CONSTRAINT implementation_pkey PRIMARY KEY (id);


--
-- Name: implementationdocuments implementationdocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationdocuments
    ADD CONSTRAINT implementationdocuments_pkey PRIMARY KEY (id);


--
-- Name: implementationmilestone implementationmilestone_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestone
    ADD CONSTRAINT implementationmilestone_pkey PRIMARY KEY (id);


--
-- Name: implementationmilestonedocuments implementationmilestonedocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestonedocuments
    ADD CONSTRAINT implementationmilestonedocuments_pkey PRIMARY KEY (id);


--
-- Name: implementationstatus implementationstatus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationstatus
    ADD CONSTRAINT implementationstatus_pkey PRIMARY KEY (id);


--
-- Name: implementationtransactions implementationtransactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationtransactions
    ADD CONSTRAINT implementationtransactions_pkey PRIMARY KEY (id);


--
-- Name: item item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item
    ADD CONSTRAINT item_pkey PRIMARY KEY (id);


--
-- Name: language language_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT language_pkey PRIMARY KEY (id);


--
-- Name: links links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT links_pkey PRIMARY KEY (id);


--
-- Name: log_gdmx log_gdmx_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_gdmx
    ADD CONSTRAINT log_gdmx_pkey PRIMARY KEY (id);


--
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- Name: memberof memberof_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberof
    ADD CONSTRAINT memberof_pkey PRIMARY KEY (id);


--
-- Name: milestonetype milestonetype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.milestonetype
    ADD CONSTRAINT milestonetype_pkey PRIMARY KEY (id);


--
-- Name: parties parties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parties
    ADD CONSTRAINT parties_pkey PRIMARY KEY (id);


--
-- Name: partiesadditionalidentifiers partiesadditionalidentifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partiesadditionalidentifiers
    ADD CONSTRAINT partiesadditionalidentifiers_pkey PRIMARY KEY (id);


--
-- Name: paymentmethod paymentmethod_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paymentmethod
    ADD CONSTRAINT paymentmethod_pkey PRIMARY KEY (id);


--
-- Name: metadata pk_metadata_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metadata
    ADD CONSTRAINT pk_metadata_id PRIMARY KEY (field_name);


--
-- Name: planning planning_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning
    ADD CONSTRAINT planning_pkey PRIMARY KEY (id);


--
-- Name: planningdocuments planningdocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planningdocuments
    ADD CONSTRAINT planningdocuments_pkey PRIMARY KEY (id);


--
-- Name: pntreference pntreference_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pntreference
    ADD CONSTRAINT pntreference_pkey PRIMARY KEY (id);


--
-- Name: prefixocid prefixocid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prefixocid
    ADD CONSTRAINT prefixocid_pkey PRIMARY KEY (id);


--
-- Name: programaticstructure programaticstructure_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programaticstructure
    ADD CONSTRAINT programaticstructure_pkey PRIMARY KEY (id);


--
-- Name: publisher publisher_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publisher
    ADD CONSTRAINT publisher_pkey PRIMARY KEY (id);


--
-- Name: quotes quotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_pkey PRIMARY KEY (id);


--
-- Name: quotesitems quotesitems_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotesitems
    ADD CONSTRAINT quotesitems_pkey PRIMARY KEY (id);


--
-- Name: relatedprocedure relatedprocedure_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relatedprocedure
    ADD CONSTRAINT relatedprocedure_pkey PRIMARY KEY (id);


--
-- Name: requestforquotes requestforquotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotes
    ADD CONSTRAINT requestforquotes_pkey PRIMARY KEY (id);


--
-- Name: requestforquotesinvitedsuppliers requestforquotesinvitedsuppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotesinvitedsuppliers
    ADD CONSTRAINT requestforquotesinvitedsuppliers_pkey PRIMARY KEY (id);


--
-- Name: requestforquotesitems requestforquotesitems_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotesitems
    ADD CONSTRAINT requestforquotesitems_pkey PRIMARY KEY (id);


--
-- Name: rolecatalog rolecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rolecatalog
    ADD CONSTRAINT rolecatalog_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: tender tender_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tender
    ADD CONSTRAINT tender_pkey PRIMARY KEY (id);


--
-- Name: tenderamendmentchanges tenderamendmentchanges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderamendmentchanges
    ADD CONSTRAINT tenderamendmentchanges_pkey PRIMARY KEY (id);


--
-- Name: tenderdocuments tenderdocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderdocuments
    ADD CONSTRAINT tenderdocuments_pkey PRIMARY KEY (id);


--
-- Name: tenderitem tenderitem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderitem
    ADD CONSTRAINT tenderitem_pkey PRIMARY KEY (id);


--
-- Name: tenderitemadditionalclassifications tenderitemadditionalclassifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderitemadditionalclassifications
    ADD CONSTRAINT tenderitemadditionalclassifications_pkey PRIMARY KEY (id);


--
-- Name: tendermilestone tendermilestone_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestone
    ADD CONSTRAINT tendermilestone_pkey PRIMARY KEY (id);


--
-- Name: tendermilestonedocuments tendermilestonedocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestonedocuments
    ADD CONSTRAINT tendermilestonedocuments_pkey PRIMARY KEY (id);


--
-- Name: user_contractingprocess user_contractingprocess_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_contractingprocess
    ADD CONSTRAINT user_contractingprocess_pkey PRIMARY KEY (id);


--
-- Name: award award_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.award
    ADD CONSTRAINT award_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: awardamendmentchanges awardamendmentchanges_award_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awardamendmentchanges
    ADD CONSTRAINT awardamendmentchanges_award_id_fkey FOREIGN KEY (award_id) REFERENCES public.award(id) ON DELETE CASCADE;


--
-- Name: awardamendmentchanges awardamendmentchanges_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awardamendmentchanges
    ADD CONSTRAINT awardamendmentchanges_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: awarddocuments awarddocuments_award_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarddocuments
    ADD CONSTRAINT awarddocuments_award_id_fkey FOREIGN KEY (award_id) REFERENCES public.award(id) ON DELETE CASCADE;


--
-- Name: awarddocuments awarddocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarddocuments
    ADD CONSTRAINT awarddocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: awarditem awarditem_award_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarditem
    ADD CONSTRAINT awarditem_award_id_fkey FOREIGN KEY (award_id) REFERENCES public.award(id) ON DELETE CASCADE;


--
-- Name: awarditem awarditem_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarditem
    ADD CONSTRAINT awarditem_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: awarditemadditionalclassifications awarditemadditionalclassifications_award_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarditemadditionalclassifications
    ADD CONSTRAINT awarditemadditionalclassifications_award_id_fkey FOREIGN KEY (award_id) REFERENCES public.award(id) ON DELETE CASCADE;


--
-- Name: awarditemadditionalclassifications awarditemadditionalclassifications_awarditem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awarditemadditionalclassifications
    ADD CONSTRAINT awarditemadditionalclassifications_awarditem_id_fkey FOREIGN KEY (awarditem_id) REFERENCES public.awarditem(id) ON DELETE CASCADE;


--
-- Name: awardsupplier awardsupplier_award_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awardsupplier
    ADD CONSTRAINT awardsupplier_award_id_fkey FOREIGN KEY (award_id) REFERENCES public.award(id) ON DELETE CASCADE;


--
-- Name: awardsupplier awardsupplier_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awardsupplier
    ADD CONSTRAINT awardsupplier_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: budget budget_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget
    ADD CONSTRAINT budget_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: budget budget_planning_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget
    ADD CONSTRAINT budget_planning_id_fkey FOREIGN KEY (planning_id) REFERENCES public.planning(id) ON DELETE CASCADE;


--
-- Name: clarificationmeeting clarificationmeeting_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clarificationmeeting
    ADD CONSTRAINT clarificationmeeting_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: clarificationmeetingactor clarificationmeetingactor_clarificationmeeting_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clarificationmeetingactor
    ADD CONSTRAINT clarificationmeetingactor_clarificationmeeting_id_fkey FOREIGN KEY (clarificationmeeting_id) REFERENCES public.clarificationmeeting(id) ON DELETE CASCADE;


--
-- Name: clarificationmeetingactor clarificationmeetingactor_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clarificationmeetingactor
    ADD CONSTRAINT clarificationmeetingactor_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: contract contract_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contract
    ADD CONSTRAINT contract_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractamendmentchanges contractamendmentchanges_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractamendmentchanges
    ADD CONSTRAINT contractamendmentchanges_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: contractamendmentchanges contractamendmentchanges_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractamendmentchanges
    ADD CONSTRAINT contractamendmentchanges_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractdocuments contractdocuments_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractdocuments
    ADD CONSTRAINT contractdocuments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: contractdocuments contractdocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractdocuments
    ADD CONSTRAINT contractdocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractitem contractitem_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitem
    ADD CONSTRAINT contractitem_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: contractitem contractitem_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitem
    ADD CONSTRAINT contractitem_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractitemadditionalclasifications contractitemadditionalclasifications_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitemadditionalclasifications
    ADD CONSTRAINT contractitemadditionalclasifications_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: contractitemadditionalclasifications contractitemadditionalclasifications_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitemadditionalclasifications
    ADD CONSTRAINT contractitemadditionalclasifications_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractitemadditionalclasifications contractitemadditionalclasifications_contractitem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contractitemadditionalclasifications
    ADD CONSTRAINT contractitemadditionalclasifications_contractitem_id_fkey FOREIGN KEY (contractitem_id) REFERENCES public.contractitem(id) ON DELETE CASCADE;


--
-- Name: implementation implementation_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementation
    ADD CONSTRAINT implementation_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: implementation implementation_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementation
    ADD CONSTRAINT implementation_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationdocuments implementationdocuments_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationdocuments
    ADD CONSTRAINT implementationdocuments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: implementationdocuments implementationdocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationdocuments
    ADD CONSTRAINT implementationdocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationdocuments implementationdocuments_implementation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationdocuments
    ADD CONSTRAINT implementationdocuments_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES public.implementation(id) ON DELETE CASCADE;


--
-- Name: implementationmilestone implementationmilestone_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestone
    ADD CONSTRAINT implementationmilestone_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: implementationmilestone implementationmilestone_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestone
    ADD CONSTRAINT implementationmilestone_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationmilestone implementationmilestone_implementation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestone
    ADD CONSTRAINT implementationmilestone_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES public.implementation(id) ON DELETE CASCADE;


--
-- Name: implementationmilestonedocuments implementationmilestonedocuments_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestonedocuments
    ADD CONSTRAINT implementationmilestonedocuments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: implementationmilestonedocuments implementationmilestonedocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestonedocuments
    ADD CONSTRAINT implementationmilestonedocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationmilestonedocuments implementationmilestonedocuments_implementation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationmilestonedocuments
    ADD CONSTRAINT implementationmilestonedocuments_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES public.implementation(id) ON DELETE CASCADE;


--
-- Name: implementationtransactions implementationtransactions_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationtransactions
    ADD CONSTRAINT implementationtransactions_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: implementationtransactions implementationtransactions_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationtransactions
    ADD CONSTRAINT implementationtransactions_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationtransactions implementationtransactions_implementation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implementationtransactions
    ADD CONSTRAINT implementationtransactions_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES public.implementation(id) ON DELETE CASCADE;


--
-- Name: links links_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT links_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: memberof memberof_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberof
    ADD CONSTRAINT memberof_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: memberof memberof_principal_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberof
    ADD CONSTRAINT memberof_principal_parties_id_fkey FOREIGN KEY (principal_parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: parties parties_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parties
    ADD CONSTRAINT parties_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: partiesadditionalidentifiers partiesadditionalidentifiers_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partiesadditionalidentifiers
    ADD CONSTRAINT partiesadditionalidentifiers_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: partiesadditionalidentifiers partiesadditionalidentifiers_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partiesadditionalidentifiers
    ADD CONSTRAINT partiesadditionalidentifiers_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: planning planning_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning
    ADD CONSTRAINT planning_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: planningdocuments planningdocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planningdocuments
    ADD CONSTRAINT planningdocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: planningdocuments planningdocuments_planning_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planningdocuments
    ADD CONSTRAINT planningdocuments_planning_id_fkey FOREIGN KEY (planning_id) REFERENCES public.planning(id) ON DELETE CASCADE;


--
-- Name: publisher publisher_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publisher
    ADD CONSTRAINT publisher_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: quotes quotes_issuingsupplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_issuingsupplier_id_fkey FOREIGN KEY (issuingsupplier_id) REFERENCES public.parties(id) ON DELETE SET NULL;


--
-- Name: quotes quotes_requestforquotes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_requestforquotes_id_fkey FOREIGN KEY (requestforquotes_id) REFERENCES public.requestforquotes(id) ON DELETE CASCADE;


--
-- Name: quotesitems quotesitems_quotes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotesitems
    ADD CONSTRAINT quotesitems_quotes_id_fkey FOREIGN KEY (quotes_id) REFERENCES public.quotes(id) ON DELETE CASCADE;


--
-- Name: requestforquotes requestforquotes_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotes
    ADD CONSTRAINT requestforquotes_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: requestforquotesinvitedsuppliers requestforquotesinvitedsuppliers_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotesinvitedsuppliers
    ADD CONSTRAINT requestforquotesinvitedsuppliers_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: requestforquotesinvitedsuppliers requestforquotesinvitedsuppliers_requestforquotes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotesinvitedsuppliers
    ADD CONSTRAINT requestforquotesinvitedsuppliers_requestforquotes_id_fkey FOREIGN KEY (requestforquotes_id) REFERENCES public.requestforquotes(id) ON DELETE CASCADE;


--
-- Name: requestforquotesitems requestforquotesitems_requestforquotes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requestforquotesitems
    ADD CONSTRAINT requestforquotesitems_requestforquotes_id_fkey FOREIGN KEY (requestforquotes_id) REFERENCES public.requestforquotes(id) ON DELETE CASCADE;


--
-- Name: roles roles_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: roles roles_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: tags tags_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tender tender_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tender
    ADD CONSTRAINT tender_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderamendmentchanges tenderamendmentchanges_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderamendmentchanges
    ADD CONSTRAINT tenderamendmentchanges_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderamendmentchanges tenderamendmentchanges_tender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderamendmentchanges
    ADD CONSTRAINT tenderamendmentchanges_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES public.tender(id) ON DELETE CASCADE;


--
-- Name: tenderdocuments tenderdocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderdocuments
    ADD CONSTRAINT tenderdocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderdocuments tenderdocuments_tender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderdocuments
    ADD CONSTRAINT tenderdocuments_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES public.tender(id) ON DELETE CASCADE;


--
-- Name: tenderitem tenderitem_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderitem
    ADD CONSTRAINT tenderitem_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderitem tenderitem_tender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderitem
    ADD CONSTRAINT tenderitem_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES public.tender(id) ON DELETE CASCADE;


--
-- Name: tenderitemadditionalclassifications tenderitemadditionalclassifications_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderitemadditionalclassifications
    ADD CONSTRAINT tenderitemadditionalclassifications_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderitemadditionalclassifications tenderitemadditionalclassifications_tenderitem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenderitemadditionalclassifications
    ADD CONSTRAINT tenderitemadditionalclassifications_tenderitem_id_fkey FOREIGN KEY (tenderitem_id) REFERENCES public.tenderitem(id) ON DELETE CASCADE;


--
-- Name: tendermilestone tendermilestone_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestone
    ADD CONSTRAINT tendermilestone_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tendermilestone tendermilestone_tender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestone
    ADD CONSTRAINT tendermilestone_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES public.tender(id) ON DELETE CASCADE;


--
-- Name: tendermilestonedocuments tendermilestonedocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestonedocuments
    ADD CONSTRAINT tendermilestonedocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tendermilestonedocuments tendermilestonedocuments_milestone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestonedocuments
    ADD CONSTRAINT tendermilestonedocuments_milestone_id_fkey FOREIGN KEY (milestone_id) REFERENCES public.tendermilestone(id) ON DELETE CASCADE;


--
-- Name: tendermilestonedocuments tendermilestonedocuments_tender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tendermilestonedocuments
    ADD CONSTRAINT tendermilestonedocuments_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES public.tender(id) ON DELETE CASCADE;


--
-- Name: user_contractingprocess user_contractingprocess_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_contractingprocess
    ADD CONSTRAINT user_contractingprocess_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

