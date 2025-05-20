CREATE TYPE management_level_enum AS ENUM ('ENTRY', 'MID', 'SENIOR', 'EXECUTIVE');
CREATE TYPE skill_level_enum AS ENUM ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT');
CREATE TYPE visibility_enum AS ENUM ('PUBLIC', 'PRIVATE', 'INTERNAL');
CREATE TYPE status_enum AS ENUM ('DRAFT', 'OPEN', 'CLOSED', 'FILLED', 'CANCELLED');
CREATE TYPE job_start_type_enum AS ENUM ('ASAP', 'SPECIFIC_DATE');
CREATE TYPE job_type_enum AS ENUM ('FULL_TIME', 'PART_TIME', 'CONTRACT', 'FREELANCE', 'VOLUNTEER');
CREATE TYPE compensation_type_enum AS ENUM ('HOURLY', 'DAILY', 'WEEKLY', 'MONTHLY', 'ANNUAL');
CREATE TYPE duration_unit_enum AS ENUM ('DAY', 'WEEK', 'MONTH', 'YEAR');
CREATE TYPE hiring_type_enum AS ENUM ('LIMITED', 'ON_GOING');
CREATE TYPE location_type_enum AS ENUM ('ON_SITE', 'REMOTE', 'HYBRID');

-- Create tenants table (simplified for this demo)
CREATE TABLE tenants (
    id CHAR(32) PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Create supervisory_orgs table (simplified for this demo)
CREATE TABLE supervisory_orgs (
    id CHAR(32) PRIMARY KEY,
    tenant_id CHAR(32) NOT NULL,
    name VARCHAR(255) NOT NULL,
    CONSTRAINT fk_supervisory_orgs_tenant_id FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- Create locations table (simplified for this demo)
CREATE TABLE locations (
    id CHAR(32) PRIMARY KEY,
    tenant_id CHAR(32) NOT NULL,
    name VARCHAR(255) NOT NULL,
    country VARCHAR(255) NOT NULL,
    formatted_address TEXT,
    CONSTRAINT fk_locations_tenant_id FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- Create skills table (simplified for this demo)
CREATE TABLE skills (
    id CHAR(32) PRIMARY KEY,
    tenant_id CHAR(32) NOT NULL,
    name VARCHAR(255) NOT NULL,
    CONSTRAINT fk_skills_tenant_id FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- Create outbox_events table
CREATE TABLE outbox_events (
    id UUID PRIMARY KEY,
    aggregate_type VARCHAR(255) NOT NULL,
    aggregate_id CHAR(32) NOT NULL,
    type VARCHAR(255) NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create job_requisitions table
CREATE TABLE job_requisitions (
    id CHAR(32) NOT NULL,
    tenant_id CHAR(32) NOT NULL,
    parent_job_id CHAR(32),
    job_title TEXT NOT NULL,
    supervisory_orgs_id CHAR(32),
    reference_id VARCHAR(255),
    management_level management_level_enum,
    skill_level skill_level_enum,
    visibility visibility_enum NOT NULL,
    external_url VARCHAR(255),
    status status_enum NOT NULL,
    revoked_date TIMESTAMP,
    job_start_type job_start_type_enum NOT NULL,
    job_start_date DATE,
    job_type job_type_enum NOT NULL,
    compensation_type compensation_type_enum,
    pay_range_enabled BOOLEAN,
    fixed_compensation DOUBLE PRECISION,
    min_compensation DOUBLE PRECISION,
    max_compensation DOUBLE PRECISION,
    weekly_hours INTEGER,
    duration_unit duration_unit_enum,
    duration INTEGER,
    hiring_type hiring_type_enum,
    number_of_hires INTEGER,
    location_type location_type_enum,
    location_id CHAR(32),
    is_relocation_required BOOLEAN NOT NULL,
    employee_benefits_required BOOLEAN NOT NULL,
    visa_included BOOLEAN NOT NULL,
    created_by CHAR(32) NOT NULL,
    updated_by CHAR(32),
    created_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_timestamp TIMESTAMP,

    CONSTRAINT pk_job_requisitions PRIMARY KEY(id),
    CONSTRAINT fk_job_requisitions_tenant_id FOREIGN KEY (tenant_id) REFERENCES tenants(id),
    CONSTRAINT fk_job_requisitions_parent_job_id FOREIGN KEY (parent_job_id) REFERENCES job_requisitions(id),
    CONSTRAINT fk_job_requisitions_supervisory_orgs_id FOREIGN KEY (supervisory_orgs_id) REFERENCES supervisory_orgs(id),
    CONSTRAINT fk_job_requisitions_location_id FOREIGN KEY (location_id) REFERENCES locations(id),
    CONSTRAINT volunteer_no_compensation CHECK (
        job_type != 'VOLUNTEER' OR (
            compensation_type IS NULL AND
            pay_range_enabled IS NULL AND
            fixed_compensation IS NULL AND
            min_compensation IS NULL AND
            max_compensation IS NULL AND
            weekly_hours IS NULL AND
            duration_unit IS NULL AND
            duration IS NULL
        )
    ),
    CONSTRAINT compensation_logic CHECK (
        (pay_range_enabled = TRUE AND fixed_compensation IS NULL AND min_compensation IS NOT NULL AND max_compensation IS NOT NULL) OR
        (pay_range_enabled = FALSE AND fixed_compensation IS NOT NULL AND min_compensation IS NULL AND max_compensation IS NULL) OR
        (pay_range_enabled IS NULL AND fixed_compensation IS NULL AND min_compensation IS NULL AND max_compensation IS NULL)
    ),
    CONSTRAINT full_time_benefits CHECK (
        job_type = 'FULL_TIME' OR (
            is_relocation_required = FALSE AND
            employee_benefits_required = FALSE AND
            visa_included = FALSE
        )
    ),
    CONSTRAINT number_of_hires_limited CHECK (
        (hiring_type = 'LIMITED' AND number_of_hires IS NOT NULL) OR
        (hiring_type = 'ON_GOING' AND number_of_hires IS NULL)
    ),
    CONSTRAINT job_start_date_specific CHECK (
        (job_start_type = 'SPECIFIC_DATE' AND job_start_date IS NOT NULL) OR
        (job_start_type = 'ASAP' AND job_start_date IS NULL)
    )
);

-- Create job_requisition_skills table
CREATE TABLE job_requisition_skills (
    id CHAR(32) NOT NULL,
    tenant_id CHAR(32) NOT NULL,
    job_requisition_id CHAR(32) NOT NULL,
    skill_id CHAR(32) NOT NULL,
    skill_level INTEGER NOT NULL,
    is_required BOOLEAN NOT NULL,
    created_by CHAR(32) NOT NULL,
    updated_by CHAR(32),
    created_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_timestamp TIMESTAMP,

    CONSTRAINT pk_job_requisition_skills PRIMARY KEY(id),
    CONSTRAINT fk_job_requisition_skills_tenant_id FOREIGN KEY (tenant_id) REFERENCES tenants(id),
    CONSTRAINT fk_job_requisition_skills_job_requisition_id FOREIGN KEY (job_requisition_id) REFERENCES job_requisitions(id),
    CONSTRAINT fk_job_requisition_skills_skill_id FOREIGN KEY (skill_id) REFERENCES skills(id)
);

CREATE INDEX idx_job_requisition_skills_job_requisition_id ON job_requisition_skills(job_requisition_id);
CREATE INDEX idx_job_requisition_skills_tenant_id_skill_id ON job_requisition_skills(tenant_id, skill_id);

-- Create trigger functions
CREATE OR REPLACE FUNCTION job_requisitions_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    payload JSONB;
BEGIN
    payload = to_jsonb(NEW);

    INSERT INTO outbox_events (
        id,
        aggregate_type,
        aggregate_id,
        type,
        payload
    ) VALUES (
        gen_random_uuid(),
        'job_requisition',
        NEW.id,
        CASE
            WHEN TG_OP = 'INSERT' THEN 'JobRequisitionCreated'
            WHEN TG_OP = 'UPDATE' THEN 'JobRequisitionUpdated'
            WHEN TG_OP = 'DELETE' THEN 'JobRequisitionDeleted'
        END,
        payload
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION job_requisition_skills_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    payload JSONB;
BEGIN
    payload = to_jsonb(NEW);

    INSERT INTO outbox_events (
        id,
        aggregate_type,
        aggregate_id,
        type,
        payload
    ) VALUES (
        gen_random_uuid(),
        'job_requisition_skill',
        NEW.job_requisition_id,
        CASE
            WHEN TG_OP = 'INSERT' THEN 'JobRequisitionSkillCreated'
            WHEN TG_OP = 'UPDATE' THEN 'JobRequisitionSkillUpdated'
            WHEN TG_OP = 'DELETE' THEN 'JobRequisitionSkillDeleted'
        END,
        payload
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER job_requisitions_trigger
AFTER INSERT OR UPDATE OR DELETE ON job_requisitions
FOR EACH ROW EXECUTE FUNCTION job_requisitions_trigger_function();

CREATE TRIGGER job_requisition_skills_trigger
AFTER INSERT OR UPDATE OR DELETE ON job_requisition_skills
FOR EACH ROW EXECUTE FUNCTION job_requisition_skills_trigger_function();